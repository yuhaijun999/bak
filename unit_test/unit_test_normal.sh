#!/bin/bah

set_text_color(){
    echo -e "\033[32m$1\033[0m"
}

set_text_black_color(){
    echo -e "\033[30m$1\033[0m"
}

set_text_red_color(){
    echo -e "\033[31m$1\033[0m"
}

set_text_green_color(){
    echo -e "\033[32m$1\033[0m"
}

set_text_yellow_color(){
    echo -e "\033[33m$1\033[0m"
}

set_text_blue_color(){
    echo -e "\033[34m$1\033[0m"
}

set_text_purple_color(){
    echo -e "\033[35m$1\033[0m"
}

set_text_sky_color(){
    echo -e "\033[36m$1\033[0m"
}

set_text_white_color(){
    echo -e "\033[37m$1\033[0m"
}

exec_test(){
    set_text_red_color "TEST $1 ..............................................................."
    $HOME/work/dingo-store/build/bin/dingodb_unit_test --gtest_filter=$2.*
    sleep 1
}

exec_test "test_codec.cc"                              		CodecTest
exec_test "test_coprocessor_aggregation_manager.cc"    		CoprocessorAggregationManagerTest
exec_test "test_coprocessor.cc"                        	    CoprocessorAggregationManagerTest
exec_test "test_coprocessor_utils.cc"                  		CoprocessorUtilsTest
exec_test "test_rel_expr_helper.cc"                            RelExprHelperTest
exec_test "test_rocks_engine.cc"                               RawRocksEngineTest
exec_test "test_rocks_engine_destroy.cc"                       RawRocksEngineBugTest
exec_test "test_scan.cc"                                       ScanTest
exec_test "test_txn_gc.cc"                                     TxnGcTest
exec_test "test_vector_index_hnsw.cc"                          VectorIndexHnswTest
exec_test "test_vector_index_hnsw_search_param.cc"             VectorIndexHnswSearchParamTest
exec_test "test_vector_index_recall_flat.cc"                   VectorIndexRecallFlatTest
exec_test "test_vector_index_utils.cc"                         VectorIndexUtilsTest
exec_test "test_coprocessor_v2.cc TEST_COPROCESSOR_V2_MOCK"  	CoprocessorTestV2
exec_test "test_scan_v2.cc"                                    ScanV2Test
exec_test "test_scan_with_coprocessor.cc"                      ScanWithCoprocessor
exec_test "test_txn_scan.cc TEST_COPROCESSOR_V2_MOCK"          TxnScanTest
exec_test "test_scan_with_coprocessor_v2.cc TEST_COPROCESSOR_V2_MOCK"                    ScanWithCoprocessorV2
exec_test "test_vector_reader.cc TEST_COPROCESSOR_V2_MOCK "                              VectorIndexReaderTest
exec_test "test_vector_index_flat_search_param.cc"             VectorIndexFlatSearchParamTest
exec_test "test_vector_index_flat_search_limit.cc"             VectorIndexFlatSearchParamLimitTest

#### TODO : error
#exec_test "test_vector_index_flat.cc"                           VectorIndexFlatTest
#exec_test "test_vector_index_ivf_flat.cc"                       VectorIndexIvfFlatTest
#exec_test "test_vector_index_ivf_pq.cc"                         VectorIndexIvfPqTest
#exec_test "test_vector_index_raw_ivf_pq.cc"                     VectorIndexRawIvfPqTest

#slow
#exec_test "test_vector_index_memory.cc"                         VectorIndexMemoryTest
#exec_test "test_vector_index_memory_flat.cc"                    VectorIndexMemoryFlatTest
#exec_test "test_vector_index_memory_hnsw.cc"                    VectorIndexMemoryHnswTest


