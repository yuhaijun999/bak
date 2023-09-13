
flat : 60001, 60002(废弃) ; region id : 80001
hnsw : 60003, 60004(废弃) ; region id : 80002
-------------------------------------------------------------------------------------------------------
server@dingo6 dist [wip-vector-ivf-flat] $ sh create_vector_flat.sh 
E20230913 16:42:39.335628 2959408 dingodb_client.cc:817] [main] coordinator url is empty, try to use file://./coor_list
I20230913 16:42:39.335866 2959408 client_interation.cc:42] [Init] Init channel 172.20.61.106:32001
I20230913 16:42:39.340982 2959408 client_interation.cc:42] [Init] Init channel 172.20.61.106:32002
I20230913 16:42:39.341023 2959408 client_interation.cc:42] [Init] Init channel 172.20.61.106:32003
I20230913 16:42:39.341323 2959419 naming_service_thread.cpp:203] brpc::policy::FileNamingService("./coor_list"): added 3
I20230913 16:42:39.341434 2959408 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=0
I20230913 16:42:39.341491 2959408 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=1
I20230913 16:42:39.341559 2959408 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=3
W20230913 16:42:39.347586 2959408 coordinator_interaction.h:208] [SendRequestByService] name_service_channel_ connect with meta server success by service name, connected to: 172.20.61.106:32002 found new leader: 172.20.61.106:32001
I20230913 16:42:39.349437 2959408 coordinator_client_function_meta.cc:253] [GetCreateTableId] SendRequest status=OK
I20230913 16:42:39.349467 2959408 coordinator_client_function_meta.cc:254] [GetCreateTableId] table_id {
  entity_type: ENTITY_TYPE_TABLE
  parent_entity_id: 2
  entity_id: 60001
}
I20230913 16:42:39.352691 2959408 coordinator_client_function_meta.cc:253] [GetCreateTableId] SendRequest status=OK
I20230913 16:42:39.352720 2959408 coordinator_client_function_meta.cc:254] [GetCreateTableId] table_id {
  entity_type: ENTITY_TYPE_TABLE
  parent_entity_id: 2
  entity_id: 60002
}
I20230913 16:42:39.359814 2959408 coordinator_client_function_meta.cc:767] [SendCreateIndex] SendRequest status=OK
I20230913 16:42:39.359843 2959408 coordinator_client_function_meta.cc:768] [SendCreateIndex] index_id {
  entity_type: ENTITY_TYPE_INDEX
  parent_entity_id: 2
  entity_id: 60001
}


-------------------------------------------------------------------------------------------------------
server@dingo6 dist [wip-vector-ivf-flat] $ sh create_vector_hnsw.sh 
E20230913 16:43:25.014541 2959767 dingodb_client.cc:817] [main] coordinator url is empty, try to use file://./coor_list
I20230913 16:43:25.014760 2959767 client_interation.cc:42] [Init] Init channel 172.20.61.106:32001
I20230913 16:43:25.020099 2959767 client_interation.cc:42] [Init] Init channel 172.20.61.106:32002
I20230913 16:43:25.020141 2959767 client_interation.cc:42] [Init] Init channel 172.20.61.106:32003
I20230913 16:43:25.020426 2959775 naming_service_thread.cpp:203] brpc::policy::FileNamingService("./coor_list"): added 3
I20230913 16:43:25.020565 2959767 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=0
I20230913 16:43:25.020629 2959767 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=1
I20230913 16:43:25.020694 2959767 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=3
I20230913 16:43:25.027835 2959767 coordinator_interaction.h:217] [SendRequestByService] name_service_channel_ connect with meta server finished. response errcode: 0, leader_addr: 172.20.61.106:32001
I20230913 16:43:25.027873 2959767 coordinator_client_function_meta.cc:253] [GetCreateTableId] SendRequest status=OK
I20230913 16:43:25.027906 2959767 coordinator_client_function_meta.cc:254] [GetCreateTableId] table_id {
  entity_type: ENTITY_TYPE_TABLE
  parent_entity_id: 2
  entity_id: 60003
}
I20230913 16:43:25.030951 2959767 coordinator_client_function_meta.cc:253] [GetCreateTableId] SendRequest status=OK
I20230913 16:43:25.030982 2959767 coordinator_client_function_meta.cc:254] [GetCreateTableId] table_id {
  entity_type: ENTITY_TYPE_TABLE
  parent_entity_id: 2
  entity_id: 60004
}
I20230913 16:43:25.031080 2959767 coordinator_client_function_meta.cc:731] [SendCreateIndex] max_elements=2000000, dimension=1024
I20230913 16:43:25.038030 2959767 coordinator_client_function_meta.cc:767] [SendCreateIndex] SendRequest status=OK
I20230913 16:43:25.038091 2959767 coordinator_client_function_meta.cc:768] [SendCreateIndex] index_id {
  entity_type: ENTITY_TYPE_INDEX
  parent_entity_id: 2
  entity_id: 60003
}
server@dingo6 dist [wip-vector-ivf-flat] $ 

---------------------------------------------------------------------------------------------------------------------------------------

server@dingo6 dist [wip-vector-ivf-flat] $ sh get_index_metrics_flat.sh 
E20230913 16:46:34.758925 2961427 dingodb_client.cc:817] [main] coordinator url is empty, try to use file://./coor_list
I20230913 16:46:34.759140 2961427 client_interation.cc:42] [Init] Init channel 172.20.61.106:32001
I20230913 16:46:34.764081 2961427 client_interation.cc:42] [Init] Init channel 172.20.61.106:32002
I20230913 16:46:34.764120 2961427 client_interation.cc:42] [Init] Init channel 172.20.61.106:32003
I20230913 16:46:34.764420 2961430 naming_service_thread.cpp:203] brpc::policy::FileNamingService("./coor_list"): added 3
I20230913 16:46:34.764550 2961427 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=0
I20230913 16:46:34.764609 2961427 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=1
I20230913 16:46:34.764674 2961427 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=3
W20230913 16:46:34.770601 2961427 coordinator_interaction.h:208] [SendRequestByService] name_service_channel_ connect with meta server success by service name, connected to: 172.20.61.106:32002 found new leader: 172.20.61.106:32001
I20230913 16:46:34.771205 2961427 coordinator_client_function_meta.cc:803] [SendGetIndexMetrics] SendRequest status=OK
I20230913 16:46:34.771235 2961427 coordinator_client_function_meta.cc:804] [SendGetIndexMetrics] index_metrics {
  id {
    entity_type: ENTITY_TYPE_INDEX
    parent_entity_id: 2
    entity_id: 60001
  }
  index_metrics {
    max_key: "\377\377\377\377\377\377\377\377\377\377"
    part_count: 1
  }
}

server@dingo6 dist [wip-vector-ivf-flat] $ sh  get_index_metrics_hnsw.sh 
E20230913 16:47:03.191905 2961657 dingodb_client.cc:817] [main] coordinator url is empty, try to use file://./coor_list
I20230913 16:47:03.192103 2961657 client_interation.cc:42] [Init] Init channel 172.20.61.106:32001
I20230913 16:47:03.197158 2961657 client_interation.cc:42] [Init] Init channel 172.20.61.106:32002
I20230913 16:47:03.197201 2961657 client_interation.cc:42] [Init] Init channel 172.20.61.106:32003
I20230913 16:47:03.197441 2961660 naming_service_thread.cpp:203] brpc::policy::FileNamingService("./coor_list"): added 3
I20230913 16:47:03.197501 2961657 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=0
I20230913 16:47:03.197559 2961657 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=1
I20230913 16:47:03.197623 2961657 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=3
I20230913 16:47:03.203999 2961657 coordinator_interaction.h:217] [SendRequestByService] name_service_channel_ connect with meta server finished. response errcode: 0, leader_addr: 172.20.61.106:32001
I20230913 16:47:03.204036 2961657 coordinator_client_function_meta.cc:803] [SendGetIndexMetrics] SendRequest status=OK
I20230913 16:47:03.204051 2961657 coordinator_client_function_meta.cc:804] [SendGetIndexMetrics] index_metrics {
  id {
    entity_type: ENTITY_TYPE_INDEX
    parent_entity_id: 2
    entity_id: 60003
  }
  index_metrics {
    max_key: "\377\377\377\377\377\377\377\377\377\377"
    part_count: 1
  }
}


server@dingo6 dist [wip-vector-ivf-flat] $ sh   get_index_range_flat.sh 
E20230913 16:47:35.796321 2961936 dingodb_client.cc:817] [main] coordinator url is empty, try to use file://./coor_list
I20230913 16:47:35.796511 2961936 client_interation.cc:42] [Init] Init channel 172.20.61.106:32001
I20230913 16:47:35.801590 2961936 client_interation.cc:42] [Init] Init channel 172.20.61.106:32002
I20230913 16:47:35.801633 2961936 client_interation.cc:42] [Init] Init channel 172.20.61.106:32003
I20230913 16:47:35.801957 2961944 naming_service_thread.cpp:203] brpc::policy::FileNamingService("./coor_list"): added 3
I20230913 16:47:35.802021 2961936 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=0
I20230913 16:47:35.802103 2961936 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=1
I20230913 16:47:35.802206 2961936 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=3
I20230913 16:47:35.808157 2961936 coordinator_interaction.h:217] [SendRequestByService] name_service_channel_ connect with meta server finished. response errcode: 0, leader_addr: 172.20.61.106:32001
I20230913 16:47:35.808195 2961936 coordinator_client_function_meta.cc:607] [SendGetIndexRange] SendRequest status=OK
I20230913 16:47:35.808230 2961936 coordinator_client_function_meta.cc:608] [SendGetIndexRange] index_range {
  range_distribution {
    id {
      entity_type: ENTITY_TYPE_PART
      parent_entity_id: 60002
      entity_id: 80001
    }
    range {
      start_key: "\000\000\000\000\000\000\352b"
      end_key: "\000\000\000\000\000\000\352c"
    }
    leader {
      host: "172.20.61.106"
      port: 31003
    }
    voters {
      host: "172.20.61.106"
      port: 31001
    }
    voters {
      host: "172.20.61.106"
      port: 31002
    }
    voters {
      host: "172.20.61.106"
      port: 31003
    }
    regionmap_epoch: 1002
    storemap_epoch: 1006
    region_epoch {
      conf_version: 1
      version: 1
    }
  }
}
I20230913 16:47:35.813370 2961936 coordinator_client_function_meta.cc:611] [SendGetIndexRange] region_id=[80001]range=[000000000000ea62,000000000000ea63] leader=[172.20.61.106:31003]
server@dingo6 dist [wip-vector-ivf-flat] $ 


server@dingo6 dist [wip-vector-ivf-flat] $ sh     get_index_range_hnsw.sh 
E20230913 16:51:39.622434 2963628 dingodb_client.cc:817] [main] coordinator url is empty, try to use file://./coor_list
I20230913 16:51:39.622630 2963628 client_interation.cc:42] [Init] Init channel 172.20.61.106:32001
I20230913 16:51:39.627666 2963628 client_interation.cc:42] [Init] Init channel 172.20.61.106:32002
I20230913 16:51:39.627712 2963628 client_interation.cc:42] [Init] Init channel 172.20.61.106:32003
I20230913 16:51:39.627970 2963634 naming_service_thread.cpp:203] brpc::policy::FileNamingService("./coor_list"): added 3
I20230913 16:51:39.628043 2963628 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=0
I20230913 16:51:39.628104 2963628 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=1
I20230913 16:51:39.628168 2963628 coordinator_interaction.cc:65] [InitByNameService] Init channel by service_name file://./coor_list service_type=3
W20230913 16:51:39.634270 2963628 coordinator_interaction.h:208] [SendRequestByService] name_service_channel_ connect with meta server success by service name, connected to: 172.20.61.106:32002 found new leader: 172.20.61.106:32001
I20230913 16:51:39.635108 2963628 coordinator_client_function_meta.cc:607] [SendGetIndexRange] SendRequest status=OK
I20230913 16:51:39.635138 2963628 coordinator_client_function_meta.cc:608] [SendGetIndexRange] index_range {
  range_distribution {
    id {
      entity_type: ENTITY_TYPE_PART
      parent_entity_id: 60004
      entity_id: 80002
    }
    range {
      start_key: "\000\000\000\000\000\000\352d"
      end_key: "\000\000\000\000\000\000\352e"
    }
    leader {
      host: "172.20.61.106"
      port: 31001
    }
    voters {
      host: "172.20.61.106"
      port: 31003
    }
    voters {
      host: "172.20.61.106"
      port: 31001
    }
    voters {
      host: "172.20.61.106"
      port: 31002
    }
    regionmap_epoch: 1002
    storemap_epoch: 1006
    region_epoch {
      conf_version: 1
      version: 1
    }
  }
}
I20230913 16:51:39.640605 2963628 coordinator_client_function_meta.cc:611] [SendGetIndexRange] region_id=[80002]range=[000000000000ea64,000000000000ea65] leader=[172.20.61.106:31001]
server@dingo6 dist [wip-vector-ivf-flat] $ 
