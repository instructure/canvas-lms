#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/files/UploadDropZone'
], (React, ReactDOM, {Simulate}, UploadDropZone) ->

  UploadDropZone = React.createFactory(UploadDropZone)

  node = document.querySelector('#fixtures')

  QUnit.module 'UploadDropZone',
    setup: ->
      @uploadZone = ReactDOM.render(UploadDropZone({}), node)

    teardown: ->
      ReactDOM.unmountComponentAtNode(node)

  test 'displays nothing by default', ->
    displayText = @uploadZone.getDOMNode().innerHTML.trim()
    equal(displayText, '')

  test 'displays dropzone when active', ->
    @uploadZone.setState({active: true})
    ok(@uploadZone.getDOMNode().querySelector('.UploadDropZone__instructions'))

  test 'handles drop event on target', ->
    @stub(@uploadZone, 'onDrop')

    @uploadZone.setState({active: true})
    dataTransfer = {
      types: ['Files']
    }

    n = @uploadZone.getDOMNode()
    Simulate.dragEnter(n, {dataTransfer: dataTransfer})
    Simulate.dragOver(n, {dataTransfer: dataTransfer})
    Simulate.drop(n)
    ok(@uploadZone.onDrop.calledOnce, 'handles file drops')
