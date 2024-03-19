#!/bin/bash
cd /home/server/work/dingo-store
sed -i 's|replica = table_definition.replica()|replica = 1|g' ./src/coordinator/coordinator_control_meta.cc
