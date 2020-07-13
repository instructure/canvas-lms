/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

process.env.NODE_ENV = 'test'

const assert = require('assert')
const fs = require('fs')
const path = require('path')
const webpack = require('webpack')
const testWebpackConfig = require('./frontend_build/baseWebpackConfig')

const CONTEXT_COFFEESCRIPT_SPEC = 'spec/coffeescripts'
const CONTEXT_EMBER_GRADEBOOK_SPEC = 'app/coffeescripts/ember'
const CONTEXT_JSX_SPEC = 'spec/javascripts/jsx'

const RESOURCE_COFFEESCRIPT_SPEC = /Spec$/
const RESOURCE_EMBER_GRADEBOOK_SPEC = /\.spec$/
const RESOURCE_JSX_SPEC = /Spec$/

const RESOURCE_JSA_SPLIT_SPEC = /^\.\/[a-f].*Spec$/
const RESOURCE_JSG_SPLIT_SPEC = /^\.\/g.*Spec$/
const RESOURCE_JSH_SPLIT_SPEC = /^\.\/[h-z].*Spec$/

testWebpackConfig.entry = undefined

testWebpackConfig.plugins.push(
  new webpack.DefinePlugin({
    CONTEXT_COFFEESCRIPT_SPEC: JSON.stringify(CONTEXT_COFFEESCRIPT_SPEC),
    CONTEXT_EMBER_GRADEBOOK_SPEC: JSON.stringify(CONTEXT_EMBER_GRADEBOOK_SPEC),
    CONTEXT_JSX_SPEC: JSON.stringify(CONTEXT_JSX_SPEC),
    RESOURCE_COFFEESCRIPT_SPEC,
    RESOURCE_EMBER_GRADEBOOK_SPEC,
    RESOURCE_JSX_SPEC
  })
)

testWebpackConfig.plugins.push(new webpack.EnvironmentPlugin({
  JSPEC_PATH: null,
  JSPEC_GROUP: null,
  A11Y_REPORT: false,
  SENTRY_DSN: null,
  GIT_COMMIT: null
}))

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

if (process.env.JSPEC_GROUP) {
  const nodeIndex = +process.env.CI_NODE_INDEX
  const nodeTotal = +process.env.CI_NODE_TOTAL

  let ignoreResource = () => {
    throw new Error(`Unknown JSPEC_GROUP ${process.env.JSPEC_GROUP}`)
  }

  if (process.env.JSPEC_GROUP === 'coffee') {
    let partitions = null

    if (!isNaN(nodeIndex) && !isNaN(nodeTotal)) {
      const allFiles = []

      getAllFiles(CONTEXT_COFFEESCRIPT_SPEC, allFiles, filePath => {
        const relativePath = filePath.replace(CONTEXT_COFFEESCRIPT_SPEC, '.').replace(/\.(coffee|js)$/, '')

        return RESOURCE_COFFEESCRIPT_SPEC.test(relativePath) ? relativePath : null
      })

      getAllFiles(CONTEXT_EMBER_GRADEBOOK_SPEC, allFiles, filePath => {
        const relativePath = filePath.replace(CONTEXT_EMBER_GRADEBOOK_SPEC, '.').replace(/\.(coffee|js)$/, '')

        return RESOURCE_EMBER_GRADEBOOK_SPEC.test(relativePath) ? relativePath : null
      })

      partitions = makeSortedPartitions(allFiles, nodeTotal)
    }

    ignoreResource = (resource, context) => {
      return (
        (context.endsWith(CONTEXT_JSX_SPEC) && RESOURCE_JSX_SPEC.test(resource)) ||
        (
          partitions &&
            context.endsWith(CONTEXT_COFFEESCRIPT_SPEC) &&
            RESOURCE_COFFEESCRIPT_SPEC.test(resource) &&
            !isPartitionMatch(resource, partitions, nodeIndex)
        ) ||
        (
          partitions &&
            context.endsWith(CONTEXT_EMBER_GRADEBOOK_SPEC) &&
            // FIXME: Unlike the other specs, webpack is including the suffix
            (resource = resource.replace(/\.(coffee|js)$/, '')) &&
            RESOURCE_EMBER_GRADEBOOK_SPEC.test(resource) &&
            !isPartitionMatch(resource, partitions, nodeIndex)
        )
      )
    }
  } else if (process.env.JSPEC_GROUP === 'jsa') {
    ignoreResource = (resource, context) => {
      return (
        context.endsWith(CONTEXT_COFFEESCRIPT_SPEC) ||
        context.endsWith(CONTEXT_EMBER_GRADEBOOK_SPEC) ||
        (context.endsWith(CONTEXT_JSX_SPEC) &&
          RESOURCE_JSX_SPEC.test(resource) &&
          !RESOURCE_JSA_SPLIT_SPEC.test(resource))
      )
    }
  } else if (process.env.JSPEC_GROUP === 'jsg') {
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
  } else if (process.env.JSPEC_GROUP === 'jsh') {
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

  testWebpackConfig.plugins.push(
    new webpack.IgnorePlugin({
      checkResource: ignoreResource
    })
  )
}

if (process.env.SENTRY_DSN) {
  const SentryCliPlugin = require('@sentry/webpack-plugin');
  testWebpackConfig.plugins.push(new SentryCliPlugin({
    release: process.env.GIT_COMMIT,
    include: [
      path.resolve(__dirname, 'public/javascripts'),
      path.resolve(__dirname, 'app/jsx'),
      path.resolve(__dirname, 'app/coffeescripts'),
      path.resolve(__dirname, 'spec/javascripts/jsx'),
      path.resolve(__dirname, 'spec/coffeescripts')
    ],
    ignore: [
      path.resolve(__dirname, 'public/javascripts/translations'),
      /bower\//
    ]
  }));
}

testWebpackConfig.resolve.alias[CONTEXT_EMBER_GRADEBOOK_SPEC] = path.resolve(__dirname, CONTEXT_EMBER_GRADEBOOK_SPEC)
testWebpackConfig.resolve.alias[CONTEXT_COFFEESCRIPT_SPEC] = path.resolve(__dirname, CONTEXT_COFFEESCRIPT_SPEC)
testWebpackConfig.resolve.alias[CONTEXT_JSX_SPEC] = path.resolve(__dirname, CONTEXT_JSX_SPEC)
testWebpackConfig.resolve.alias['spec/jsx'] = path.resolve(__dirname, 'spec/javascripts/jsx')
testWebpackConfig.resolve.extensions.push('.coffee')
testWebpackConfig.mode = 'development'
testWebpackConfig.module.rules.unshift({
  test: [
    /\/spec\/coffeescripts\//,
    /\/spec_canvas\/coffeescripts\//,
    // Some plugins use a special spec_canvas path for their specs
    /\/spec\/javascripts\/jsx\//,
    /\/ember\/.*\/tests\//
  ],

  // Our spec files expect qunit's global `test`, `module`, `asyncTest` and `start` variables.
  // These imports loaders make it so they are avalable as local variables
  // inside of a closure, without truly making them globals.
  // We should get rid of this and just change our actual source to s/test/qunit.test/ and s/module/qunit.module/
  loaders: [
    'imports-loader?test=>QUnit.test',
  ]
})

module.exports = testWebpackConfig
