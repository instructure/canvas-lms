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

define(
  [
    'react',
    'react-addons-test-utils',
    'jsx/editor/SwitchEditorControl',
    'jsx/shared/rce/RichContentEditor'
  ],
  (React, TestUtils, SwitchEditorControl, RichContentEditor) => {
    QUnit.module('SwitchEditorControl', {
      setup() {
        sinon.stub(RichContentEditor, 'callOnRCE')
      },

      teardown() {
        RichContentEditor.callOnRCE.restore()
      }
    })

    test('changes text on each click', () => {
      let textarea = {}
      let element = React.createElement(SwitchEditorControl, {textarea: textarea})
      let component = TestUtils.renderIntoDocument(element)
      let link = TestUtils.findRenderedDOMComponentWithTag(component, 'a')
      equal(link.props.className, 'switch-views__link__html')
      TestUtils.Simulate.click(link.getDOMNode())
      equal(link.props.className, 'switch-views__link__rce')
    })

    test('passes textarea through to editor for toggling', () => {
      let textarea = {id: 'the text area'}
      let element = React.createElement(SwitchEditorControl, {textarea: textarea})
      let component = TestUtils.renderIntoDocument(element)
      let link = TestUtils.findRenderedDOMComponentWithTag(component, 'a')
      TestUtils.Simulate.click(link.getDOMNode())
      ok(RichContentEditor.callOnRCE.calledWith(textarea))
    })
  }
)
