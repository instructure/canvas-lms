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
import 'jquery-migrate'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import ModalButtons from '@canvas/modal/react/buttons'

QUnit.module('ModalButtons')

test('applies className', () => {
  const ModalButtonsElement = <ModalButtons className="cat" footerClassName="dog" />
  const component = TestUtils.renderIntoDocument(ModalButtonsElement)
  ok($(ReactDOM.findDOMNode(component)).hasClass('cat'), 'has parent class')
  ok($(ReactDOM.findDOMNode(component)).find('.dog').length === 1, 'Finds footer class name')
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
})

test('renders children', () => {
  const mB = (
    <ModalButtons>
      <div className="cool_div" />
    </ModalButtons>
  )
  const component = TestUtils.renderIntoDocument(mB)
  ok(
    $(ReactDOM.findDOMNode(component)).find('.cool_div').length === 1,
    'renders the child component'
  )
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
})
