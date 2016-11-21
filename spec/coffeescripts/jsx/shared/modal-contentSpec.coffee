define [
  'jquery'
  'react'
  'react-dom'
  'jsx/shared/modal-content'
], ($, React, ReactDOM, ModalContent) ->

  TestUtils = React.addons.TestUtils

  module 'ModalContent'

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
