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
  'jsx/shared/modal-content'
], ($, React, ReactDOM, TestUtils, ModalContent) ->

  QUnit.module 'ModalContent'

  test "applies className to parent node", ->
    ModalContentElement = React.createElement(ModalContent, className: 'cat')
    component = TestUtils.renderIntoDocument(ModalContentElement)

    ok $(component.getDOMNode()).hasClass('cat'), "applies class name"

    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

  test "renders children components", ->
    mC = React.createElement(ModalContent, {},
      React.createElement('div', className: 'my_fun_div')
    )
    component = TestUtils.renderIntoDocument(mC)

    ok $(component.getDOMNode()).find('.my_fun_div'), "inserts child component elements"

    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)
