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

const {IgnorePlugin} = require('webpack')
const {getAllFiles, isPartitionMatch, makeSortedPartitions} = require('./partitioning.utils')

const CONTEXT_COFFEESCRIPT_SPEC = 'spec/coffeescripts'
const CONTEXT_JSX_SPEC = 'spec/javascripts/jsx'
const UI_FEATURES_SPEC = 'ui/features'
const UI_SHARED_SPEC = 'ui/shared'

const QUNIT_SPEC = /Spec$/

const RESOURCE_JSA_SPLIT_SPEC = /^\.\/[a-f].*Spec$/
const RESOURCE_JSG_SPLIT_SPEC = /^\.\/g.*Spec$/
const RESOURCE_JSH_SPLIT_SPEC = /^\.\/[h-z].*Spec$/

exports.createPlugin = ({group, nodeIndex, nodeTotal}) => {
  let checkResource = () => {
    throw new Error(`Unknown JSPEC_GROUP ${group}`)
  }

  if (group === 'coffee') {
    let partitions = null

    if (!isNaN(nodeIndex) && !isNaN(nodeTotal)) {
      const allFiles = getAllFiles(CONTEXT_COFFEESCRIPT_SPEC, filePath => {
        const relativePath = filePath.replace(CONTEXT_COFFEESCRIPT_SPEC, '.').replace(/\.js$/, '')

        return QUNIT_SPEC.test(relativePath) ? relativePath : null
      })

      partitions = makeSortedPartitions(allFiles, nodeTotal)
    }

    checkResource = (resource, context) => {
      return (
        (context.endsWith(CONTEXT_JSX_SPEC) && QUNIT_SPEC.test(resource)) ||
        (partitions &&
          context.endsWith(CONTEXT_COFFEESCRIPT_SPEC) &&
          QUNIT_SPEC.test(resource) &&
          !isPartitionMatch(resource, partitions, nodeIndex)) ||
        (partitions &&
          context.endsWith(UI_FEATURES_SPEC) &&
          // FIXME: Unlike the other specs, webpack is including the suffix
          (resource = resource.replace(/\.js$/, '')) &&
          QUNIT_SPEC.test(resource) &&
          !isPartitionMatch(resource, partitions, nodeIndex))
      )
    }
  } else if (group === 'jsa') {
    checkResource = (resource, context) => {
      return (
        context.endsWith(CONTEXT_COFFEESCRIPT_SPEC) ||
        context.endsWith(UI_FEATURES_SPEC) ||
        context.endsWith(UI_SHARED_SPEC) ||
        (context.endsWith(CONTEXT_JSX_SPEC) &&
          QUNIT_SPEC.test(resource) &&
          !RESOURCE_JSA_SPLIT_SPEC.test(resource))
      )
    }
  } else if (group === 'jsg') {
    let partitions = null

    if (!isNaN(nodeIndex) && !isNaN(nodeTotal)) {
      const allFiles = getAllFiles(CONTEXT_JSX_SPEC, filePath => {
        const relativePath = filePath.replace(CONTEXT_JSX_SPEC, '.').replace(/\.js$/, '')

        return RESOURCE_JSG_SPLIT_SPEC.test(relativePath) ? relativePath : null
      })

      partitions = makeSortedPartitions(allFiles, nodeTotal)
    }

    checkResource = (resource, context) => {
      return (
        context.endsWith(CONTEXT_COFFEESCRIPT_SPEC) ||
        context.endsWith(UI_FEATURES_SPEC) ||
        context.endsWith(UI_SHARED_SPEC) ||
        (context.endsWith(CONTEXT_JSX_SPEC) &&
          QUNIT_SPEC.test(resource) &&
          !RESOURCE_JSG_SPLIT_SPEC.test(resource)) ||
        (partitions &&
          context.endsWith(CONTEXT_JSX_SPEC) &&
          QUNIT_SPEC.test(resource) &&
          RESOURCE_JSG_SPLIT_SPEC.test(resource) &&
          !isPartitionMatch(resource, partitions, nodeIndex))
      )
    }
  } else if (group === 'jsh') {
    checkResource = (resource, context) => {
      return (
        context.endsWith(CONTEXT_COFFEESCRIPT_SPEC) ||
        context.endsWith(UI_FEATURES_SPEC) ||
        context.endsWith(UI_SHARED_SPEC) ||
        (context.endsWith(CONTEXT_JSX_SPEC) &&
          QUNIT_SPEC.test(resource) &&
          !RESOURCE_JSH_SPLIT_SPEC.test(resource))
      )
    }
  }

  return new IgnorePlugin({checkResource})
}

exports.CONTEXT_COFFEESCRIPT_SPEC = CONTEXT_COFFEESCRIPT_SPEC
exports.UI_FEATURES_SPEC = UI_FEATURES_SPEC
exports.UI_SHARED_SPEC = UI_SHARED_SPEC
exports.CONTEXT_JSX_SPEC = CONTEXT_JSX_SPEC
exports.QUNIT_SPEC = QUNIT_SPEC
