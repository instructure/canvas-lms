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

const assert = require('assert')
const fs = require('fs')
const {IgnorePlugin} = require('webpack')

const CONTEXT_COFFEESCRIPT_SPEC = 'spec/coffeescripts'
const CONTEXT_EMBER_GRADEBOOK_SPEC = 'ui/features/screenreader_gradebook/ember'
const CONTEXT_JSX_SPEC = 'spec/javascripts/jsx'

const RESOURCE_COFFEESCRIPT_SPEC = /Spec$/
const RESOURCE_EMBER_GRADEBOOK_SPEC = /\.spec$/
const RESOURCE_JSX_SPEC = /Spec$/

const RESOURCE_JSA_SPLIT_SPEC = /^\.\/[a-f].*Spec$/
const RESOURCE_JSG_SPLIT_SPEC = /^\.\/g.*Spec$/
const RESOURCE_JSH_SPLIT_SPEC = /^\.\/[h-z].*Spec$/

exports.createPlugin = ({group, nodeIndex, nodeTotal}) => {
  let ignoreResource = () => {
    throw new Error(`Unknown JSPEC_GROUP ${group}`)
  }

  if (group === 'coffee') {
    let partitions = null

    if (!isNaN(nodeIndex) && !isNaN(nodeTotal)) {
      const allFiles = []

      getAllFiles(CONTEXT_COFFEESCRIPT_SPEC, allFiles, filePath => {
        const relativePath = filePath
          .replace(CONTEXT_COFFEESCRIPT_SPEC, '.')
          .replace(/\.(coffee|js)$/, '')

        return RESOURCE_COFFEESCRIPT_SPEC.test(relativePath) ? relativePath : null
      })

      getAllFiles(CONTEXT_EMBER_GRADEBOOK_SPEC, allFiles, filePath => {
        const relativePath = filePath
          .replace(CONTEXT_EMBER_GRADEBOOK_SPEC, '.')
          .replace(/\.(coffee|js)$/, '')

        return RESOURCE_EMBER_GRADEBOOK_SPEC.test(relativePath) ? relativePath : null
      })

      partitions = makeSortedPartitions(allFiles, nodeTotal)
    }

    ignoreResource = (resource, context) => {
      return (
        (context.endsWith(CONTEXT_JSX_SPEC) && RESOURCE_JSX_SPEC.test(resource)) ||
        (partitions &&
          context.endsWith(CONTEXT_COFFEESCRIPT_SPEC) &&
          RESOURCE_COFFEESCRIPT_SPEC.test(resource) &&
          !isPartitionMatch(resource, partitions, nodeIndex)) ||
        (partitions &&
          context.endsWith(CONTEXT_EMBER_GRADEBOOK_SPEC) &&
          // FIXME: Unlike the other specs, webpack is including the suffix
          (resource = resource.replace(/\.(coffee|js)$/, '')) &&
          RESOURCE_EMBER_GRADEBOOK_SPEC.test(resource) &&
          !isPartitionMatch(resource, partitions, nodeIndex))
      )
    }
  } else if (group === 'jsa') {
    ignoreResource = (resource, context) => {
      return (
        context.endsWith(CONTEXT_COFFEESCRIPT_SPEC) ||
        context.endsWith(CONTEXT_EMBER_GRADEBOOK_SPEC) ||
        (context.endsWith(CONTEXT_JSX_SPEC) &&
          RESOURCE_JSX_SPEC.test(resource) &&
          !RESOURCE_JSA_SPLIT_SPEC.test(resource))
      )
    }
  } else if (group === 'jsg') {
    let partitions = null

    if (!isNaN(nodeIndex) && !isNaN(nodeTotal)) {
      const allFiles = getAllFiles(CONTEXT_JSX_SPEC, [], filePath => {
        const relativePath = filePath.replace(CONTEXT_JSX_SPEC, '.').replace(/\.js$/, '')

        return RESOURCE_JSG_SPLIT_SPEC.test(relativePath) ? relativePath : null
      })

      partitions = makeSortedPartitions(allFiles, nodeTotal)
    }

    ignoreResource = (resource, context) => {
      return (
        context.endsWith(CONTEXT_COFFEESCRIPT_SPEC) ||
        context.endsWith(CONTEXT_EMBER_GRADEBOOK_SPEC) ||
        (context.endsWith(CONTEXT_JSX_SPEC) &&
          RESOURCE_JSX_SPEC.test(resource) &&
          !RESOURCE_JSG_SPLIT_SPEC.test(resource)) ||
        (partitions &&
          context.endsWith(CONTEXT_JSX_SPEC) &&
          RESOURCE_JSX_SPEC.test(resource) &&
          RESOURCE_JSG_SPLIT_SPEC.test(resource) &&
          !isPartitionMatch(resource, partitions, nodeIndex))
      )
    }
  } else if (group === 'jsh') {
    ignoreResource = (resource, context) => {
      return (
        context.endsWith(CONTEXT_COFFEESCRIPT_SPEC) ||
        context.endsWith(CONTEXT_EMBER_GRADEBOOK_SPEC) ||
        (context.endsWith(CONTEXT_JSX_SPEC) &&
          RESOURCE_JSX_SPEC.test(resource) &&
          !RESOURCE_JSH_SPLIT_SPEC.test(resource))
      )
    }
  }

  return new IgnorePlugin({checkResource: ignoreResource})
}

const getAllFiles = (dirPath, arrayOfFiles, callback) => {
  const files = fs.readdirSync(dirPath)

  files.forEach(file => {
    if (fs.statSync(dirPath + '/' + file).isDirectory()) {
      arrayOfFiles = getAllFiles(dirPath + '/' + file, arrayOfFiles, callback)
    } else {
      const filePath = callback(dirPath + '/' + file)

      if (filePath) {
        arrayOfFiles.push(filePath)
      }
    }
  })

  return arrayOfFiles
}

const isPartitionMatch = (resource, partitions, partitionIndex) => {
  return isNaN(partitionIndex) || partitions[partitionIndex].indexOf(resource) >= 0
}

const makeSortedPartitions = (arr, partitionCount) => {
  const sortedArr = arr.sort()
  const sortedArrLength = sortedArr.length
  const chunkSize = Math.ceil(sortedArrLength / partitionCount)
  const R = []

  for (let i = 0; i < sortedArrLength; i += chunkSize) {
    R.push(sortedArr.slice(i, i + chunkSize))
  }

  assert(R.length <= partitionCount)

  return R
}

exports.CONTEXT_COFFEESCRIPT_SPEC = CONTEXT_COFFEESCRIPT_SPEC
exports.CONTEXT_EMBER_GRADEBOOK_SPEC = CONTEXT_EMBER_GRADEBOOK_SPEC
exports.CONTEXT_JSX_SPEC = CONTEXT_JSX_SPEC
exports.RESOURCE_COFFEESCRIPT_SPEC = RESOURCE_COFFEESCRIPT_SPEC
exports.RESOURCE_EMBER_GRADEBOOK_SPEC = RESOURCE_EMBER_GRADEBOOK_SPEC
exports.RESOURCE_JSA_SPLIT_SPEC = RESOURCE_JSA_SPLIT_SPEC
exports.RESOURCE_JSG_SPLIT_SPEC = RESOURCE_JSG_SPLIT_SPEC
exports.RESOURCE_JSH_SPLIT_SPEC = RESOURCE_JSH_SPLIT_SPEC
exports.RESOURCE_JSX_SPEC = RESOURCE_JSX_SPEC
