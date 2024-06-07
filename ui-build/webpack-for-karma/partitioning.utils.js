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

/* eslint-disable no-restricted-globals */

const fs = require('fs')
const assert = require('assert')

const getAllFiles = (dirPath, callback) => {
  const files = fs.readdirSync(dirPath)

  return files.reduce((allFiles, file) => {
    const path = `${dirPath}/${file}`
    if (fs.statSync(path).isDirectory()) {
      return allFiles.concat(getAllFiles(path, callback))
    } else {
      const filePath = callback(path)
      return filePath ? allFiles.concat(filePath) : allFiles
    }
  }, [])
}
exports.getAllFiles = getAllFiles

exports.isPartitionMatch = (resource, partitions, partitionIndex) => {
  return isNaN(partitionIndex) || partitions[partitionIndex].indexOf(resource) >= 0
}

exports.makeSortedPartitions = (arr, partitionCount) => {
  const sortedArr = [...arr].sort((a, b) => a - b)
  const sortedArrLength = sortedArr.length
  const chunkSize = Math.ceil(sortedArrLength / partitionCount)
  const R = []

  for (let i = 0; i < sortedArrLength; i += chunkSize) {
    R.push(sortedArr.slice(i, i + chunkSize))
  }

  assert(R.length <= partitionCount)

  return R
}
