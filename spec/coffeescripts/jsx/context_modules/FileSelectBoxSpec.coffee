#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/context_modules/FileSelectBox'
], ($, React, ReactDOM, TestUtils, FileSelectBox) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  renderComponent = ->
    ReactDOM.render(React.createFactory(FileSelectBox)({contextString: 'test_3'}), wrapper)

  QUnit.module 'FileSelectBox',
    setup: ->
      @server = sinon.fakeServer.create()

      @folders = [{
          "full_name": "course files",
          "id": 112,
          "parent_folder_id": null,
        },{
          "full_name": "course files/A",
          "id": 113,
          "parent_folder_id": 112,
        },{
          "full_name": "course files/C",
          "id": 114,
          "parent_folder_id": 112,
        },{
          "full_name": "course files/B",
          "id": 115,
          "parent_folder_id": 112,
        },{
          "full_name": "course files/NoFiles",
          "id": 116,
          "parent_folder_id": 112,
        }]

      @files = [{
          "id": 1,
          "folder_id": 112
          "display_name": "cf-1"
        },{
          "id": 2,
          "folder_id": 113
          "display_name": "A-1"
        },{
          "id": 3,
          "folder_id": 114
          "display_name": "C-1"
        },{
          "id": 4,
          "folder_id": 115
          "display_name": "B-1"
        }]


      @server.respondWith "GET", /\/tests\/3\/files/, [200, { "Content-Type": "application/json" }, JSON.stringify(@files)]
      @server.respondWith "GET", /\/tests\/3\/folders/, [200, { "Content-Type": "application/json" }, JSON.stringify(@folders)]

      @component = renderComponent()

    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'it renders', ->
    ok @component.isMounted()

  test 'it should alphabetize the folder list', ->
    @server.respond()
    # This also tests that folders without files are not shown.
    childrenLabels = $(@component.refs.selectBox.getDOMNode()).children('optgroup').toArray().map( (x) -> x.label)
    expected = ['course files', 'course files/A', 'course files/B', 'course files/C']
    deepEqual childrenLabels, expected

  test 'it should show the loading state while files are loading', ->
    # Has aria-busy attr set to true for a11y
    equal $(this.component.refs.selectBox.getDOMNode()).attr('aria-busy'), 'true'
    equal $(this.component.refs.selectBox.getDOMNode()).children()[1].text, 'Loading...'
    @server.respond()
    # Make sure those things disappear when the content actually loads
    equal $(this.component.refs.selectBox.getDOMNode()).attr('aria-busy'), 'false'
    loading = $(this.component.refs.selectBox.getDOMNode()).children().toArray().filter( (x) -> x.text == 'Loading...')
    equal loading.length, 0
