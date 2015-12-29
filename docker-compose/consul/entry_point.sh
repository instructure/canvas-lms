#!/bin/bash
rm -rf /tmp/consul
consul agent -node canvas-consul -server -client=0.0.0.0 -bootstrap-expect 1 -data-dir /tmp/consul
