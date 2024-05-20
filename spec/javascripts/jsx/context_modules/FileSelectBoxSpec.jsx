// Copyright (C) 2015 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import 'jquery-migrate'
import React from 'react'
import ReactDOM from 'react-dom'
import FileSelectBox from '@canvas/select-content-dialog/react/components/FileSelectBox'

let wrapper

const renderComponent = () => {
  const ref = React.createRef()
  ReactDOM.render(<FileSelectBox ref={ref} contextString="test_3" />, wrapper)
  return ref.current
}

const folders = [
  {
    full_name: 'course files',
    id: 112,
    parent_folder_id: null,
  },
  {
    full_name: 'course files/A',
    id: 113,
    parent_folder_id: 112,
  },
  {
    full_name: 'course files/C',
    id: 114,
    parent_folder_id: 112,
  },
  {
    full_name: 'course files/B',
    id: 115,
    parent_folder_id: 112,
  },
  {
    full_name: 'course files/NoFiles',
    id: 116,
    parent_folder_id: 112,
  },
]

const files = [
  {
    id: 1,
    folder_id: 112,
    display_name: 'cf-1',
  },
  {
    id: 2,
    folder_id: 113,
    display_name: 'A-1',
  },
  {
    id: 3,
    folder_id: 114,
    display_name: 'C-1',
  },
  {
    id: 4,
    folder_id: 115,
    display_name: 'B-1',
  },
]

const setupServer = () => {
  const server = sinon.fakeServer.create()
  server.respondWith('GET', /\/tests\/3\/files/, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(files),
  ])
  server.respondWith('GET', /\/tests\/3\/folders/, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(folders),
  ])
  return server
}

QUnit.module('FileSelectBox', {
  setup() {
    wrapper = document.getElementById('fixtures')
    this.server = setupServer()
    this.component = renderComponent()
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test('it renders', function () {
  ok(this.component)
})

test('it should alphabetize the folder list', function () {
  this.server.respond()
  // This also tests that folders without files are not shown.
  const childrenLabels = $(this.component.selectBoxRef)
    .children('optgroup')
    .toArray()
    .map(x => x.label)
  const expected = ['course files', 'course files/A', 'course files/B', 'course files/C']
  deepEqual(childrenLabels, expected)
})

test('it should show the loading state while files are loading', function () {
  // Has aria-busy attr set to true for a11y
  equal($(this.component.selectBoxRef).attr('aria-busy'), 'true')
  equal($(this.component.selectBoxRef).children()[1].text, 'Loading...')
  this.server.respond()
  // Make sure those things disappear when the content actually loads
  equal($(this.component.selectBoxRef).attr('aria-busy'), 'false')
  const loading = $(this.component.selectBoxRef)
    .children()
    .toArray()
    .filter(x => x.text === 'Loading...')
  equal(loading.length, 0)
})

test('it renders Create', function () {
  ReactDOM.unmountComponentAtNode(wrapper)
  this.component = renderComponent()
  ok(wrapper.innerText.match(/\[ Create File\(s\) \]/))
})
