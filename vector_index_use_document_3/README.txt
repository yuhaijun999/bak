1. exec create_vector_flat.sh         region id 80001 
2. exec create_vector_hnsw.sh         region id 80002
3. exec create_vector_ivf_flat.sh     region id 80003



add_vector_flat.sh                      向flat add 10 条数据    *****
create_vector_bruteforce.sh             创建 bruteforce region id 8000301
create_vector_diskann.sh                创建diskann     region od 80001
create_vector_flat_disable_document.sh  创建 flat 不带document 加速
create_vector_flat.sh                   创建 flat 带 document 加速 ******
debug_service_debug.sh                  查看 region id 80001 详细信息 
delete_vector_flat_partial.sh           删除5条数据  80001 **
delete_vector_flat.sh                   删除10条数据 80001 ***
drop_vector_flat.sh                     销毁 flat 80001 ***
merge_region.sh                         合并 80001 和 80002 ***
multi_add_vector_flat.sh                多次add  **
multi_search_vector_flat_top.sh         多次查询  
search_vector_flat_top_2.sh             查看 80002
search_vector_flat_top.sh               查询 80001 ****
split_region.sh                         分裂 80001 为 80001 和 80002
update_vector_flat.sh                   upsert 10 条数据 
vector_display_document_details.sh      展示 80001 详解 document 信息 ****


----------------------------------------------------------------------------
测试带有document 流程
1) create_vector_flat.sh 
2) add_vector_flat.sh
3) search_vector_flat_top.sh
4) delete_vector_flat.sh
5) drop_vector_flat.sh


-------------------------------------------------------------------------------
测试分裂流程
1) create_vector_flat.sh
2) add_vector_flat.sh
3) search_vector_flat_top.sh
4) split_region.sh  80001 and 80002
5) search_vector_flat_top.sh
6) search_vector_flat_top_2.sh

---------------------------------------------------------
测试合并流程
1) create_vector_flat.sh
2) add_vector_flat.sh
3) search_vector_flat_top.sh
4) split_region.sh  80001 and 80002
5) search_vector_flat_top.sh
6) search_vector_flat_top_2.sh
7) merge_region.sh 
8) search_vector_flat_top.sh

---------------------------------------------------------------
查看 某个 region 详细信息

debug_service_debug.sh
vector_display_document_details.sh

