#!/usr/bin/env python3

import subprocess
import json
import os
import shutil

def fp(message):
    print(message, flush=True)

def main():
    results = {}
    for node in os.listdir("./coverage_nodes"):
        if not os.path.isdir('./coverage_nodes/{}'.format(node)):
            continue
        with open('./coverage_nodes/{}/spec_coverage/.resultset.json'.format(node)) as json_file:
            resultset = json.load(json_file)
        fp(node)
        for process in resultset:
            key = "{}:{}".format(node, process)
            results[key] = resultset[process]
    for process in results:
        fp(process)
    with open('./coverage_nodes/.resultset.json', 'w') as results_file:
        json.dump(results, results_file)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        fp("")
