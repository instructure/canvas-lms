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

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import Breadcrumbs from 'jsx/files/Breadcrumbs'
import Folder from 'compiled/models/Folder'
import fakeENV from '../../../../coffeescripts/helpers/fakeENV'
import filesEnv from 'compiled/react_files/modules/filesEnv'

QUnit.module('Files Breadcrumbs Component', {
  setup() {
    fakeENV.setup({context_asset_string: 'course_1'})
    filesEnv.baseUrl = '/courses/1/files'
  },
  teardown() {
    $('#fixtures').empty()
    fakeENV.teardown()
  }
})

test('generates the home, rootFolder, and other links', () => {
  const sampleProps = {
    rootTillCurrentFolder: [
      new Folder({context_type: 'course', context_id: 1}),
      new Folder({name: 'test_folder_name', full_name: 'course_files/test_folder_name'})
    ],
    contextAssetString: 'course_1'
  }

  const component = TestUtils.renderIntoDocument(
    <Breadcrumbs {...sampleProps} />,
    $('#fixtures')[0]
  )

  const links = TestUtils.scryRenderedDOMComponentsWithTag(component, 'a')
  ok(links.length === 4)
  equal(new URL(links[0].href).pathname, '/', 'correct home url')
  equal(new URL(links[2].href).pathname, '/courses/1/files', 'rootFolder link has correct url')
  equal(new URL(links[3].href).pathname, '/courses/1/files/folder/test_folder_name', 'correct url for child')
  equal(ReactDOM.findDOMNode(links[3]).text, 'test_folder_name', 'shows folder names')
})
