define [
  'jquery'
  'react'
  'jsx/shared/modal-buttons'
], ($, React, ModalButtons) ->

  TestUtils = React.addons.TestUtils

  module 'ModalButtons',
  test "applies className", ->
    component = TestUtils.renderIntoDocument(ModalButtons(className: "cat", footerClassName: "dog"))

    ok $(component.getDOMNode()).hasClass("cat"), "has parent class"
    ok $(component.getDOMNode()).find(".dog").length == 1, "Finds footer class name"

    React.unmountComponentAtNode(component.getDOMNode().parentNode)
  test "renders children", ->
    mB = ModalButtons({},
      React.createElement('div', className: "cool_div"))

    component = TestUtils.renderIntoDocument(mB)

    ok $(component.getDOMNode()).find('.cool_div').length == 1, "renders the child component"
    React.unmountComponentAtNode(component.getDOMNode().parentNode)

