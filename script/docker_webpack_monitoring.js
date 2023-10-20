#!/usr/bin/env node

/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/* eslint-disable no-constant-condition */
/* eslint-disable no-await-in-loop */

const promisify = require('util').promisify
const exec = promisify(require('child_process').exec)

const BASELINE_CPU_UTILIZATION = 5.0

/**
 * Utilize common command line utilities plus `docker stats` command to monitor Webpack
 *
 * The `docker stats` command gives us info about the current running containers. The third
 * column provides us with CPU utilization percentage. When webpack is running, this value
 * spikes. When webpack finishes processing, it typically falls to a value less than a few percent.
 *
 * This function monitors the utilization and sends a native MacOS alert when webpack finishes
 */
async function monitorWebpack() {
  let webpackFinished = false
  while (1) {
    const {stdout} = await exec("docker stats --no-stream | grep webpack | awk '{print $3}'")
    const currentUtilization = parseFloat(stdout.replace('%', ''))
    if (currentUtilization <= BASELINE_CPU_UTILIZATION && !webpackFinished) {
      webpackFinished = true
      exec(
        'osascript -e \'display notification "Canvas Webpack build finished" with title "Build Finished"\''
      )
    }
    if (currentUtilization > BASELINE_CPU_UTILIZATION && webpackFinished) {
      webpackFinished = false
    }
  }
}

monitorWebpack()
