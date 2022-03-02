/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

/* 
  Due to an issue with babel-plugin-istanbul, we get different versions of
  coverage reports, for example:

  "<...>/src/app.js": {"path":"<...>/src/app.js","statementMap":{"0":{"start"...
  vs
  "<...>/src/aws.js": {"data":{"path":"<...>/src/aws.js","statementMap":{"0":{"start"...

  The difference is the added "data" key, which when present, will crash istanbul-merge
  with the error:
  Error: Invalid file coverage object, missing keys, found:data

  This script loops through all our js generated coverage reports and strips
  the "data" key where present so we can merge all coverage reports into one

  Currently this script is called from ~/buid/new-jenkins/js/coverage-report.sh
  which is in turn called from Jenkinsfile.coverage
*/

const fs = require('fs')

const dirArgs = process.argv.slice(2)

const normalizeJestCoverage = obj => {
  const result = {...obj}

  Object.entries(result).forEach(([k, v]) => {
    if (v.data) result[k] = v.data
  })

  return result
}

// Get the contents of the directory and loop over it.
const dirName = dirArgs[0]
fs.readdir(dirName, function (err, list) {
  for (let i = 0; i < list.length; i++) {
    // Get the contents of each file on iteration.
    const filename = list[i]

    fs.readFile(dirName + '/' + filename, function (err, data) {
      const parsedData = JSON.parse(data)
      const cleanedCoverage = normalizeJestCoverage(parsedData)
      fs.writeFileSync(
        dirArgs[1] + filename.slice(0, -5) + '-out.json',
        JSON.stringify(cleanedCoverage, null, 4)
      )
    })
  }
})
