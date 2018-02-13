/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import TestUtils from 'react-addons-test-utils'
import BreadcrumbCollapsedContainer from 'jsx/files/BreadcrumbCollapsedContainer'
import Folder from 'compiled/models/Folder'
import filesEnv from 'compiled/react_files/modules/filesEnv'
import mockFilesENV from '../mockFilesENV'
import stubRouterContext from '../../helpers/stubRouterContext'

const simulate = TestUtils.Simulate
const simulateNative = TestUtils.SimulateNative

QUnit.module('BreadcrumbsCollapsedContainer', {
  setup() {
    const folder = new Folder({name: 'Test Folder', urlPath: 'test_url', url: 'stupid'})
    folder.url = () => 'stupid'

    const props = {foldersToContain: [folder]}
    const bcc = stubRouterContext(BreadcrumbCollapsedContainer, props)
    this.bcc = TestUtils.renderIntoDocument(React.createElement(bcc))
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(this.bcc.getDOMNode().parentNode)
  }
})

test('BCC: opens breadcumbs on mouse enter', function() {
  const $node = $(this.bcc.getDOMNode())
  simulateNative.mouseOver(this.bcc.getDOMNode())
  equal($node.find('.open').length, 1, 'should have class of open')
})

test('BCC: opens breadcrumbs on focus', function() {
  const $node = $(this.bcc.getDOMNode())
  simulate.focus(this.bcc.getDOMNode())
  equal($node.find('.open').length, 1, 'should have class of open')
})

test('BCC: closes breadcrumbs on mouse leave', function() {
  const clock = sinon.useFakeTimers()
  const $node = $(this.bcc.getDOMNode())
  simulateNative.mouseOut(this.bcc.getDOMNode())
  clock.tick(200)
  equal($node.find('.closed').length, 1, 'should have class of closed')
  clock.restore()
})

test('BCC: closes breadcrumbs on blur', function() {
  const clock = sinon.useFakeTimers()
  simulate.blur(this.bcc.getDOMNode())
  clock.tick(200)
  const $node = $(this.bcc.getDOMNode())
  simulateNative.mouseOut(this.bcc.getDOMNode())
  clock.tick(200)
  equal($node.find('.closed').length, 1, 'should have class of closed')
  clock.restore()
})
