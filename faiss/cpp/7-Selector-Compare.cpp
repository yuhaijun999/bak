/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <iterator>
#include <random>
#include <set>
#include <vector>
#include "faiss/MetricType.h"
#include "faiss/utils/random.h"
#include "faiss/utils/utils.h"

#include <faiss/impl/IDSelector.h>

// 64-bit int
using idx_t = faiss::idx_t;
using namespace faiss; // NOLINT

struct IDSelectorSet : IDSelector {
    explicit IDSelectorSet(size_t n, const idx_t* ids) {
        array_indexs_.rehash(n);
        for (size_t i = 0; i < n; i++) {
            array_indexs_.insert(ids[i]);
        }
    }

    bool is_member(idx_t id) const final {
        return array_indexs_.find(id) != array_indexs_.end();
    }

    ~IDSelectorSet() override {}

   private: // NOLINT
    std::unordered_set<idx_t> array_indexs_;
};

template <typename T>
void test_selector(
        const std::vector<idx_t>& xids,
        const std::vector<int>& perm,
        const std::string& name) {
    double total = 0.0;

    double t0 = getmillisecs();

    T selector(xids.size(), xids.data());

    double t1 = getmillisecs();

    auto diff = t1 - t0;
    total += diff;

    std::cout << name << " load : " << diff << " ms" << std::endl;

    t0 = getmillisecs();

    for (auto id : perm) {
        selector.is_member(id);
    }

    t1 = getmillisecs();

    diff = t1 - t0;
    total += diff;

    std::cout << name << " search : " << diff << " ms" << std::endl;

    std::cout << name << " total : " << total << " ms" << std::endl
              << std::endl;
}

int main(int argc, char* argv[]) {
    int nb = 1000;

    std::vector<idx_t> xids;
    xids.resize(nb);

    for (idx_t i = 0; i < xids.size(); i++) {
        xids[i] = i;
    }

    // std::vector<int> perm(xids.size());
    std::vector<int> perm(10000000);

    rand_perm(perm.data(), perm.size(), 1234 + 1 + 0 * 15486557L);

    test_selector<IDSelectorArray>(xids, perm, "IDSelectorArray");
    test_selector<IDSelectorSet>(xids, perm, "IDSelectorSet");
    test_selector<IDSelectorBatch>(xids, perm, "IDSelectorBatch");

    return 0;
}
