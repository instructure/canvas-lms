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

