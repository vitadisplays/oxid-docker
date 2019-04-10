#!/bin/bash

echo "$0: getting oxid source"

cd /tmp
rm -rf oxideshop_ce
git clone --depth 1 "https://github.com/OXID-eSales/oxideshop_ce.git" oxideshop_ce --branch b-5.3-ce
rm -rf !$/.git

wget "https://raw.githubusercontent.com/OXID-eSales/oxideshop_demodata_ce/b-5.3/src/demodata.sql" -P oxideshop_ce/source/setup/sql/
rm oxideshop_ce/source/setup/sql/initial_data.sql

cd oxideshop_ce/source/application/views
git clone --depth 1 "https://github.com/OXID-eSales/flow_theme.git" flow --branch b-1.0
rm -rf !$/.git
cp -R flow/out/flow ../../out/

cd /tmp
cp -R oxideshop_ce/source/. "$1/"

rm -rf oxideshop_ce