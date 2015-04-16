define [
  'jquery'
  'react'
  'jsx/shared/modal-content'
], ($, React, ModalContent) ->

  TestUtils = React.addons.TestUtils

  module 'ModalContent',
  test "applies className to parent node", ->
    component = TestUtils.renderIntoDocument(ModalContent(className: 'cat'))

    ok $(component.getDOMNode()).hasClass('cat'), "applies class name"

    React.unmountComponentAtNode(component.getDOMNode().parentNode)
  test "renders children components", ->
    mC = ModalContent({},
      React.createElement('div', className: 'my_fun_div')
    )
    component = TestUtils.renderIntoDocument(mC)

    ok $(component.getDOMNode()).find('.my_fun_div'), "inserts child component elements"

    React.unmountComponentAtNode(component.getDOMNode().parentNode)
