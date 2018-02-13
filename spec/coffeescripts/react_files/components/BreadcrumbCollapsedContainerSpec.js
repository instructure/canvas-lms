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
  'jsx/files/BreadcrumbCollapsedContainer'
  'compiled/models/Folder'
  'compiled/react_files/modules/filesEnv'
  '../mockFilesENV.coffee'
  '../../helpers/stubRouterContext.coffee'
], ($, React, ReactDOM, TestUtils, BreadcrumbCollapsedContainer, Folder, filesEnv, mockFilesENV, stubRouterContext) ->
  simulate = TestUtils.Simulate
  simulateNative = TestUtils.SimulateNative

  QUnit.module 'BreadcrumbsCollapsedContainer',
    setup: ->
      folder = new Folder(name: 'Test Folder', urlPath: 'test_url', url: 'stupid')
      folder.url = -> "stupid"
      props = foldersToContain: [folder]

      bcc = stubRouterContext(BreadcrumbCollapsedContainer, props)
      @bcc = TestUtils.renderIntoDocument(React.createElement(bcc))

    teardown: ->
      ReactDOM.unmountComponentAtNode(@bcc.getDOMNode().parentNode)

  test 'BCC: opens breadcumbs on mouse enter', ->
    $node = $(@bcc.getDOMNode())
    simulateNative.mouseOver(@bcc.getDOMNode())
    equal $node.find('.open').length, 1, "should have class of open"

  test 'BCC: opens breadcrumbs on focus', ->
    $node = $(@bcc.getDOMNode())
    simulate.focus(@bcc.getDOMNode())
    equal $node.find('.open').length, 1, "should have class of open"

  test 'BCC: closes breadcrumbs on mouse leave', ->
    clock = sinon.useFakeTimers()

    $node = $(@bcc.getDOMNode())
    simulateNative.mouseOut(@bcc.getDOMNode())
    clock.tick(200)
    equal $node.find('.closed').length, 1, "should have class of closed"

    clock.restore()

  test 'BCC: closes breadcrumbs on blur', ->
    clock = sinon.useFakeTimers()
    simulate.blur(@bcc.getDOMNode())
    clock.tick(200)

    $node = $(@bcc.getDOMNode())
    simulateNative.mouseOut(@bcc.getDOMNode())
    clock.tick(200)
    equal $node.find('.closed').length, 1, "should have class of closed"

    clock.restore()

