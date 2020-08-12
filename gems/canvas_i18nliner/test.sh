#!/bin/bash
set -e

yarn install || yarn install --network-concurrency 1
yarn test
