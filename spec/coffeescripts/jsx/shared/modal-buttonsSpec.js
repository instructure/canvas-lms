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
  'jsx/shared/modal-buttons'
], ($, React, ReactDOM, TestUtils, ModalButtons) ->

  QUnit.module 'ModalButtons'

  test "applies className", ->
    ModalButtonsElement = React.createElement(ModalButtons, className: "cat", footerClassName: "dog")
    component = TestUtils.renderIntoDocument(ModalButtonsElement)

    ok $(component.getDOMNode()).hasClass("cat"), "has parent class"
    ok $(component.getDOMNode()).find(".dog").length == 1, "Finds footer class name"

    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

  test "renders children", ->
    mB = React.createElement(ModalButtons, {},
      React.createElement('div', className: "cool_div"))

    component = TestUtils.renderIntoDocument(mB)

    ok $(component.getDOMNode()).find('.cool_div').length == 1, "renders the child component"
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

