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

import {extend} from '@canvas/backbone/utils'
import {has} from 'lodash'
import {Model} from '@canvas/backbone'
import DefaultUrlMixin from '@canvas/backbone/DefaultUrlMixin'

extend(ExternalTool, Model)

function ExternalTool() {
  return ExternalTool.__super__.constructor.apply(this, arguments)
}

ExternalTool.mixin(DefaultUrlMixin)

ExternalTool.prototype.initialize = function () {
  ExternalTool.__super__.initialize.apply(this, arguments)
  if (has(this, 'url')) {
    return delete this.url
  }
}

ExternalTool.prototype.resourceName = 'external_tools'

ExternalTool.prototype.computedAttributes = [
  {
    name: 'custom_fields_string',
    deps: ['custom_fields'],
  },
]

ExternalTool.prototype.urlRoot = function () {
  return '/api/v1/' + this._contextPath() + '/create_tool_with_verification'
}

ExternalTool.prototype.custom_fields_string = function () {
  let k, v
  return function () {
    const ref = this.get('custom_fields')
    const results = []
    for (k in ref) {
      v = ref[k]
      results.push(k + '=' + v)
    }
    return results
  }
    .call(this)
    .join('\n')
}

ExternalTool.prototype.launchUrl = function (launchType, options) {
  if (options == null) {
    options = {}
  }
  const params = (function () {
    const results = []
    for (const key in options) {
      const value = options[key]
      results.push(key + '=' + value)
    }
    return results
  })()
  let url =
    '/' +
    this._contextPath() +
    '/external_tools/' +
    this.id +
    '/resource_selection?launch_type=' +
    launchType
  if (params.length > 0) {
    url = url + '&' + params.join('&')
  }
  return url
}

ExternalTool.prototype.assetString = function () {
  return 'context_external_tool_' + this.id
}

export default ExternalTool
