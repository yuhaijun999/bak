#!/bin/bash

./dingodb_unit_test  --gtest_filter=VectorIndexHnswSimdTest.*  --vector_index_hnsw_smid_test_dimension=512  --vector_index_hnsw_smid_test_data_base_size=10000000  --vector_index_hnsw_smid_test_enable_simd=true
