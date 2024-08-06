// Copyright (c) 2023 dingodb.com, Inc. All Rights Reserved
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#include <cstdint>
#include <cstdio>
#include <filesystem>
#include <memory>
#include <ostream>
#include <sstream>
#include <string>

#include "butil/string_printf.h"
#include "common/role.h"
#include "gflags/gflags_declare.h"

#endif

#include <backtrace.h>
#include <cxxabi.h>
#include <dlfcn.h>
#include <libunwind.h>
#include <unistd.h>

#include <csignal>
#include <cstdlib>  // Replace stdlib.h with cstdlib
#include <filesystem>
#include <iostream>

#include "brpc/server.h"
#include "butil/endpoint.h"
#include "common/constant.h"
#include "common/helper.h"
#include "common/logging.h"
#include "common/role.h"
#include "common/syscheck.h"
#include "common/version.h"
#include "config/config.h"
#include "config/config_manager.h"
#include "diskann/diskann_item_manager.h"
#include "diskann/diskann_item_runtime.h"
#include "gflags/gflags.h"
#include "proto/common.pb.h"
#include "server/diskann_service.h"
#include "server/server.h"

DEFINE_string(conf, "", "server config");
DECLARE_string(coor_url);

DEFINE_uint32(h2_server_max_concurrent_streams, UINT32_MAX, "max concurrent streams");
DEFINE_uint32(h2_server_stream_window_size, 1024 * 1024 * 1024, "stream window size");
DEFINE_uint32(h2_server_connection_window_size, 1024 * 1024 * 1024, "connection window size");
DEFINE_uint32(h2_server_max_frame_size, 16384, "max frame size");
DEFINE_uint32(h2_server_max_header_list_size, UINT32_MAX, "max header list size");

DEFINE_int32(brpc_common_worker_num, 10, "brpc common worker num");

namespace bvar {
DECLARE_int32(bvar_max_dump_multi_dimension_metric_number);
}  // namespace bvar

namespace bthread {
DECLARE_int32(bthread_concurrency);
}  // namespace bthread

// Get server location from config
dingodb::pb::common::Location GetServerLocation(std::shared_ptr<dingodb::Config> config) {
  const std::string host = config->GetString("server.host");
  DINGO_LOG(INFO) << "server.host is set to: " << host;
  const int port = config->GetInt("server.port");
  DINGO_LOG(INFO) << "server.port is set to: " << port;

  dingodb::pb::common::Location location;
  location.set_host(host);
  location.set_port(port);
  return location;
}

// Get server listen endpoint from config
butil::EndPoint GetServerListenEndPoint(std::shared_ptr<dingodb::Config> config) {
  std::string host = config->GetStringOrNullIfNotExists("server.listen_host");
  if (host.empty()) {
    host = config->GetString("server.host");
    DINGO_LOG(INFO) << "server.listen_host is not set, use server.host: " << host;
  } else {
    DINGO_LOG(INFO) << "server.listen_host is set to: " << host;
  }
  const int port = config->GetInt("server.port");
  DINGO_LOG(INFO) << "server.port is set to: " << port;
  return dingodb::Helper::StringToEndPoint(host, port);
}

struct DingoStackTraceInfo {
  char *filename;
  int lineno;
  char *function;
  uintptr_t pc;
};

/* Passed to backtrace callback function.  */
struct DingoBacktraceData {
  struct DingoStackTraceInfo *all;
  size_t index;
  size_t max;
  int failed;
};

int BacktraceCallback(void *vdata, uintptr_t pc, const char *filename, int lineno, const char *function) {
  struct DingoBacktraceData *data = (struct DingoBacktraceData *)vdata;
  struct DingoStackTraceInfo *p;

  if (data->index >= data->max) {
    fprintf(stderr, "callback_one: callback called too many times\n");  // NOLINT
    data->failed = 1;
    return 1;
  }

  p = &data->all[data->index];

  // filename
  if (filename == nullptr)
    p->filename = nullptr;
  else {
    p->filename = strdup(filename);
    assert(p->filename != nullptr);
  }

  // lineno
  p->lineno = lineno;

  // function
  if (function == nullptr)
    p->function = nullptr;
  else {
    p->function = strdup(function);
    assert(p->function != nullptr);
  }

  // pc
  if (pc != 0) {
    p->pc = pc;
  }

  ++data->index;

  return 0;
}

/* An error callback passed to backtrace.  */

void ErrorCallback(void *vdata, const char *msg, int errnum) {
  struct DingoBacktraceData *data = (struct DingoBacktraceData *)vdata;

  fprintf(stderr, "%s", msg);                                 // NOLINT
  if (errnum > 0) fprintf(stderr, ": %s", strerror(errnum));  // NOLINT
  fprintf(stderr, "\n");                                      // NOLINT
  data->failed = 1;
}

// The signal handler
#define MAX_STACKTRACE_SIZE 128
static void SignalHandler(int signo) {
  printf("========== handle signal '%d' ==========\n", signo);

  if (signo == SIGTERM) {
    // TODO: graceful shutdown
    // clean temp directory
    dingodb::Helper::RemoveAllFileOrDirectory(dingodb::Server::GetInstance().GetCheckpointPath());
    dingodb::Helper::RemoveFileOrDirectory(dingodb::Server::GetInstance().PidFilePath());
    DINGO_LOG(WARNING) << "GRACEFUL SHUTDOWN, clean up checkpoint dir: "
                       << dingodb::Server::GetInstance().GetCheckpointPath()
                       << ", clean up pid_file: " << dingodb::Server::GetInstance().PidFilePath();
    _exit(0);
  }

  std::cerr << "Received signal " << signo << '\n';
  std::cerr << "Stack trace:" << '\n';
  DINGO_LOG(ERROR) << "Received signal " << signo;
  DINGO_LOG(ERROR) << "Stack trace:";

  struct backtrace_state *state = backtrace_create_state(nullptr, 0, ErrorCallback, nullptr);
  if (state == nullptr) {
    std::cerr << "state is null" << '\n';
  }

  struct DingoStackTraceInfo all[MAX_STACKTRACE_SIZE];
  struct DingoBacktraceData data;

  data.all = &all[0];
  data.index = 0;
  data.max = MAX_STACKTRACE_SIZE;
  data.failed = 0;

  int i = backtrace_full(state, 0, BacktraceCallback, ErrorCallback, &data);
  if (i != 0) {
    std::cerr << "backtrace_full failed" << '\n';
    DINGO_LOG(ERROR) << "backtrace_full failed";
  }

  for (size_t x = 0; x < data.index; x++) {
    int status;
    char *nameptr = all[x].function;
    char *demangled = abi::__cxa_demangle(all[x].function, nullptr, nullptr, &status);
    if (status == 0 && demangled) {
      nameptr = demangled;
    }

    Dl_info info = {};

    if (!dladdr((void *)all[x].pc, &info)) {
      auto error_msg = butil::string_printf("#%zu source[%s:%d] symbol[%s] pc[0x%0lx]", x, all[x].filename,
                                            all[x].lineno, nameptr, static_cast<uint64_t>(all[x].pc));
      DINGO_LOG(ERROR) << error_msg;
      std::cout << error_msg << '\n';
    } else {
      auto error_msg = butil::string_printf(
          "#%zu source[%s:%d] symbol[%s] pc[0x%0lx] fname[%s] fbase[0x%lx] sname[%s] saddr[0x%lx] ", x, all[x].filename,
          all[x].lineno, nameptr, static_cast<uint64_t>(all[x].pc), info.dli_fname, (uint64_t)info.dli_fbase,
          info.dli_sname, (uint64_t)info.dli_saddr);
      DINGO_LOG(ERROR) << error_msg;
      std::cout << error_msg << '\n';
    }
    if (demangled) {
      free(demangled);
    }
  }

  // call abort() to generate core dump
  DINGO_LOG(ERROR) << "call abort() to generate core dump for signo=" << signo << " " << strsignal(signo);
  auto s = signal(SIGABRT, SIG_DFL);
  if (s == SIG_ERR) {
    std::cerr << "Failed to set signal handler to SIG_DFL for SIGABRT" << '\n';
  }
  abort();
}

static void SignalHandlerWithoutLineno(int signo) {
  printf("========== handle signal '%d' ==========\n", signo);

  if (signo == SIGTERM) {
    // TODO: graceful shutdown
    // clean temp directory
    dingodb::Helper::RemoveAllFileOrDirectory(dingodb::Server::GetInstance().GetCheckpointPath());
    dingodb::Helper::RemoveFileOrDirectory(dingodb::Server::GetInstance().PidFilePath());
    DINGO_LOG(ERROR) << "GRACEFUL SHUTDOWN, clean up checkpoint dir: "
                     << dingodb::Server::GetInstance().GetCheckpointPath()
                     << ", clean up pid_file: " << dingodb::Server::GetInstance().PidFilePath();
    _exit(0);
  }

  unw_context_t context;
  unw_cursor_t cursor;
  unw_getcontext(&context);
  unw_init_local(&cursor, &context);
  int i = 0;
  char buffer[2048];

  do {
    unw_word_t ip, offset;
    char symbol[256];

    unw_word_t pc, sp;
    unw_get_reg(&cursor, UNW_REG_IP, &pc);
    unw_get_reg(&cursor, UNW_REG_SP, &sp);
    Dl_info info = {};

    // Get the instruction pointer and symbol name for this frame
    unw_get_reg(&cursor, UNW_REG_IP, &ip);

    if (unw_get_proc_name(&cursor, symbol, sizeof(symbol), &offset) == 0) {
      char *nameptr = symbol;
      // Demangle the symbol name
      int demangle_status;
      char *demangled = abi::__cxa_demangle(symbol, nullptr, nullptr, &demangle_status);
      if (demangled) {
        nameptr = demangled;
      }
      // std::cout << "  " << nameptr << " + " << offset << " (0x" << std::hex << pc << ")" << '\n';

      if (!dladdr((void *)pc, &info)) {
        std::stringstream string_stream;
        string_stream << "Frame [" << i++ << "] symbol=[" << nameptr << " + " << offset << "] (0x" << std::hex << pc
                      << ") ";
        std::string const error_msg = string_stream.str();
        DINGO_LOG(ERROR) << error_msg;
        std::cout << error_msg << '\n';
      } else {
        std::stringstream string_stream;
        string_stream << "Frame [" << i++ << "] symbol=[" << nameptr << " + " << offset << "] (0x" << std::hex << pc
                      << ") "
                      << " fname=[" << info.dli_fname << "] saddr=[" << info.dli_saddr << "] fbase=[" << info.dli_fbase
                      << "]";
        std::string const error_msg = string_stream.str();
        DINGO_LOG(ERROR) << error_msg;
        std::cout << error_msg << '\n';
      }
      if (demangled) {
        free(demangled);
      }
    }

  } while (unw_step(&cursor) > 0);

  // call abort() to generate core dump
  DINGO_LOG(ERROR) << "call abort() to generate core dump for signo=" << signo << " " << strsignal(signo);
  auto s = signal(SIGABRT, SIG_DFL);
  if (s == SIG_ERR) {
    std::cerr << "Failed to set signal handler to SIG_DFL for SIGABRT" << '\n';
  }
  abort();
}

void SetupSignalHandler() {
  sighandler_t s;
  s = signal(SIGTERM, SignalHandler);
  if (s == SIG_ERR) {
    printf("Failed to setup signal handler for SIGTERM\n");
    exit(-1);
  }
  s = signal(SIGSEGV, SignalHandler);
  if (s == SIG_ERR) {
    printf("Failed to setup signal handler for SIGSEGV\n");
    exit(-1);
  }
  s = signal(SIGFPE, SignalHandler);
  if (s == SIG_ERR) {
    printf("Failed to setup signal handler for SIGFPE\n");
    exit(-1);
  }
  s = signal(SIGBUS, SignalHandler);
  if (s == SIG_ERR) {
    printf("Failed to setup signal handler for SIGBUS\n");
    exit(-1);
  }
  s = signal(SIGILL, SignalHandler);
  if (s == SIG_ERR) {
    printf("Failed to setup signal handler for SIGILL\n");
    exit(-1);
  }
  s = signal(SIGABRT, SignalHandler);
  if (s == SIG_ERR) {
    printf("Failed to setup signal handler for SIGABRT\n");
    exit(-1);
  }
  // ignore SIGPIPE
  s = signal(SIGPIPE, SIG_IGN);
  if (s == SIG_ERR) {
    printf("Failed to setup signal handler for SIGPIPE\n");
    exit(-1);
  }
}

// Modify gflag variable
bool SetGflagVariable() {
  // Open bvar multi dimesion metrics.
  if (bvar::FLAGS_bvar_max_dump_multi_dimension_metric_number <
      dingodb::Constant::kBvarMaxDumpMultiDimensionMetricNumberDefault) {
    if (google::SetCommandLineOption(
            "bvar_max_dump_multi_dimension_metric_number",
            std::to_string(dingodb::Constant::kBvarMaxDumpMultiDimensionMetricNumberDefault).c_str())
            .empty()) {
      DINGO_LOG(ERROR) << "Fail to set bvar_max_dump_multi_dimension_metric_number";
      return false;
    }
  }

  return true;
}

// Get worker thread num used by config
int InitBthreadWorkerThreadNum(std::shared_ptr<dingodb::Config> config) {
  int32_t num = config->GetInt("server.worker_thread_num");
  if (num <= 0) {
    double ratio = config->GetDouble("server.worker_thread_ratio");
    if (ratio > 0) {
      num = std::round(ratio * static_cast<double>(dingodb::Helper::GetCoreNum()));
    }
  }

  if (num > 4) {
    bthread::FLAGS_bthread_concurrency = num;
  }

  int brpc_common_worker_num = config->GetInt("server.brpc_common_worker_num");
  if (brpc_common_worker_num <= 0) {
    DINGO_LOG(WARNING) << "server.brpc_common_worker_num is not set, use dingodb::FLAGS_brpc_common_worker_num";
  } else {
    FLAGS_brpc_common_worker_num = brpc_common_worker_num;
  }
  if (FLAGS_brpc_common_worker_num <= 0) {
    DINGO_LOG(ERROR) << "server.brpc_common_worker_num is less than 0";
    return -1;
  }
  DINGO_LOG(INFO) << "server.brpc_common_worker_num is set to " << FLAGS_brpc_common_worker_num;

  return bthread::FLAGS_bthread_concurrency;
}

// setup default conf and coor_list
bool SetDefaultConfAndCoorList(const dingodb::pb::common::ClusterRole &role) {
  if (FLAGS_conf.empty()) {
    if (role == dingodb::pb::common::DISKANN && std::filesystem::exists("./conf/diskann.yaml")) {
      FLAGS_conf = "./conf/diskann.yaml";
    } else {
      DINGO_LOG(ERROR) << "unknown role:" << role;
      return false;
    }
  }

  if (FLAGS_coor_url.empty() && std::filesystem::exists("./conf/coor_list")) {
    FLAGS_coor_url = "file://./conf/coor_list";
  }

  return true;
}

int main(int argc, char *argv[]) {
  if (dingodb::Helper::IsExistPath("conf/gflags.conf")) {
    google::SetCommandLineOption("flagfile", "conf/gflags.conf");
  }
  google::ParseCommandLineFlags(&argc, &argv, true);

  if (dingodb::FLAGS_show_version || dingodb::GetRoleName().empty()) {
    dingodb::DingoShowVerion();

    printf(
        "Usage: %s --role=[diskann] --conf ./conf/[diskann].yaml "
        "--coor_url=[file://./conf/coor_list]\n",
        argv[0]);
    printf("Example: \n");
    printf("         bin/diskann_server --role [diskann]\n");
    printf(
        "         bin/dingodb_server --role diskann --conf ./conf/diskann.yaml --coor_url=file://./conf/coor_list\n");
    exit(-1);
  }

  SetupSignalHandler();

  if (!SetGflagVariable()) {
    return -1;
  }

  dingodb::pb::common::ClusterRole role = dingodb::GetRole();
  if (role == dingodb::pb::common::ClusterRole::ILLEGAL) {
    DINGO_LOG(ERROR) << "Invalid server role[" + dingodb::GetRoleName() + "]";
    return -1;
  }

  SetDefaultConfAndCoorList(role);

  if (FLAGS_conf.empty()) {
    DINGO_LOG(ERROR) << "Missing server config.";
    return -1;
  } else if (!std::filesystem::exists(FLAGS_conf)) {
    DINGO_LOG(ERROR) << "server config file not exist.";
    return -1;
  }

  auto &dingo_server = dingodb::Server::GetInstance();
  if (!dingo_server.InitConfig(FLAGS_conf)) {
    DINGO_LOG(ERROR) << "InitConfig failed!";
    return -1;
  }

  auto const config = dingodb::ConfigManager::GetInstance().GetRoleConfig();
  if (!dingo_server.InitDirectory()) {
    DINGO_LOG(ERROR) << "InitDirectory failed!";
    return -1;
  }

  if (!dingo_server.InitLog()) {
    DINGO_LOG(ERROR) << "InitLog failed!";
    return -1;
  }

  if (!dingo_server.InitServerID()) {
    DINGO_LOG(ERROR) << "InitServerID failed!";
    return -1;
  }

#ifdef LINK_TCMALLOC
  DINGO_LOG(INFO) << "LINK_TCMALLOC is ON";
#ifdef BRPC_ENABLE_CPU_PROFILER
  DINGO_LOG(INFO) << "BRPC_ENABLE_CPU_PROFILER is ON";
#endif
#else
  DINGO_LOG(INFO) << "LINK_TCMALLOC is OFF";
#endif

  // check system env
  auto ret = dingodb::DoSystemCheck();
  if (ret < 0) {
    DINGO_LOG(ERROR) << "DoSystemCheck failed, DingoDB may run with unexpected behavior.";
  }
  DINGO_LOG(INFO) << "DoSystemCheck ret:" << ret;

  dingo_server.SetServerLocation(GetServerLocation(config));
  dingo_server.SetServerListenEndpoint(GetServerListenEndPoint(config));

  // if (!dingo_server.InitEngine()) {
  //   DINGO_LOG(ERROR) << "InitEngine failed!";
  //   return -1;
  // }

  // for all role
  dingodb::DiskAnnServiceImpl diskann_service;

  brpc::Server brpc_server;

  brpc::ServerOptions options;

  options.h2_settings.max_concurrent_streams = FLAGS_h2_server_max_concurrent_streams;
  options.h2_settings.stream_window_size = FLAGS_h2_server_stream_window_size;
  options.h2_settings.connection_window_size = FLAGS_h2_server_connection_window_size;
  options.h2_settings.max_frame_size = FLAGS_h2_server_max_frame_size;
  options.h2_settings.max_header_list_size = FLAGS_h2_server_max_header_list_size;
  // options.idle_timeout_sec = 30;

  DINGO_LOG(INFO) << "h2_settings.max_concurrent_streams: " << options.h2_settings.max_concurrent_streams;
  DINGO_LOG(INFO) << "h2_settings.stream_window_size: " << options.h2_settings.stream_window_size;
  DINGO_LOG(INFO) << "h2_settings.connection_window_size: " << options.h2_settings.connection_window_size;
  DINGO_LOG(INFO) << "h2_settings.max_frame_size: " << options.h2_settings.max_frame_size;
  DINGO_LOG(INFO) << "h2_settings.max_header_list_size: " << options.h2_settings.max_header_list_size;

  if (role == dingodb::pb::common::ClusterRole::DISKANN) {
    InitBthreadWorkerThreadNum(config);
    if (!dingodb::DiskANNItemRuntime::Init(config)) {
      LOG(ERROR) << "Fail to init diskann item runtime!";
      return -1;
    }

    if (!dingodb::DiskANNItemManager::GetInstance().Init(config)) {
      LOG(ERROR) << "Fail to init diskann item manager!";
      return -1;
    }

    // bthread::FLAGS_bthread_concurrency = dingodb::DiskANNItemRuntime::GetNumBthreads();

    FLAGS_brpc_common_worker_num = bthread::FLAGS_bthread_concurrency;

    options.num_threads = bthread::FLAGS_bthread_concurrency;

    if (brpc_server.AddService(&diskann_service, brpc::SERVER_DOESNT_OWN_SERVICE) != 0) {
      LOG(ERROR) << "Fail to add diskann service to brpc_server!";
      return -1;
    }

  } else {
    DINGO_LOG(ERROR) << "Invalid server role[" + dingodb::GetRoleName() + "]";
    return -1;
  }

  // Start server after raft server started.
  options.pid_file = dingo_server.PidFilePath();

  DINGO_LOG(INFO) << "Server is going to start on " << dingo_server.ServerListenEndpoint()
                  << ", pid_file:" << options.pid_file;

  if (brpc_server.Start(dingo_server.ServerListenEndpoint(), &options) != 0) {
    DINGO_LOG(ERROR) << "Fail to start server!";
    return -1;
  }
  DINGO_LOG(INFO) << "Server is running on " << brpc_server.listen_address();

  // Wait until 'CTRL-C' is pressed. then Stop() and Join() the service
  while (!brpc::IsAskedToQuit()) {
    sleep(1);
  }
  DINGO_LOG(INFO) << "Server is going to quit";

  brpc_server.Stop(0);

  brpc_server.Join();

  dingo_server.Destroy();

  return 0;
}
