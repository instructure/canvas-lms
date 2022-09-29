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

import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import SwitchEditorControl from '@canvas/editor-toggle/react/SwitchEditorControl'
import RichContentEditor from '@canvas/rce/RichContentEditor'

QUnit.module('SwitchEditorControl', {
  setup() {
    sinon.stub(RichContentEditor, 'callOnRCE')
  },

  teardown() {
    RichContentEditor.callOnRCE.restore()
  },
})

test('changes text on each click', () => {
  const textarea = {}
  const element = React.createElement(SwitchEditorControl, {textarea})
  const component = TestUtils.renderIntoDocument(element)
  const link = TestUtils.findRenderedDOMComponentWithTag(component, 'a')
  equal(link.className, 'switch-views__link switch-views__link__html')
  TestUtils.Simulate.click(ReactDOM.findDOMNode(link))
  equal(link.className, 'switch-views__link switch-views__link__rce')
})

test('passes textarea through to editor for toggling', () => {
  const textarea = {id: 'the text area'}
  const element = React.createElement(SwitchEditorControl, {textarea})
  const component = TestUtils.renderIntoDocument(element)
  const link = TestUtils.findRenderedDOMComponentWithTag(component, 'a')
  TestUtils.Simulate.click(ReactDOM.findDOMNode(link))
  ok(RichContentEditor.callOnRCE.calledWith(textarea))
})
