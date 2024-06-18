/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import ExternalTool from '../ExternalTool'

describe('ExternalTool', () => {
  let prevAssetString
  let tool

  beforeEach(() => {
    // Save previous asset string from the environment
    prevAssetString = ENV.context_asset_string
    // Set the desired test condition for the asset string
    ENV.context_asset_string = 'course_3'
    // Initialize the tool instance
    tool = new ExternalTool()
  })

  afterEach(() => {
    // Restore the original environment asset string after each test
    ENV.context_asset_string = prevAssetString
  })

  test('urlRoot', () => {
    expect(tool.urlRoot()).toEqual('/api/v1/courses/3/create_tool_with_verification')
  })
})
