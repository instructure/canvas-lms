define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'react-modal'
  'jsx/external_apps/components/ManageAppListButton',
], (React, ReactDOM, TestUtils, Modal, ManageAppListButton) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  Modal.setAppElement(wrapper)

  onUpdateAccessToken = ->

  createElement = ->
    React.createElement(ManageAppListButton, {
      onUpdateAccessToken: onUpdateAccessToken
    })

  renderComponent = ->
    ReactDOM.render(createElement(), wrapper)

  module 'ExternalApps.ManageAppListButton',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'open and close modal', ->
    component = renderComponent({})
    Simulate.click(component.getDOMNode())
    ok component.state.modalIsOpen, 'modal is open'
    ok component.refs.btnClose
    ok component.refs.btnUpdateAccessToken
    Simulate.click(component.refs.btnClose.getDOMNode())
    ok !component.state.modalIsOpen, 'modal is not open'
    ok !component.refs.btnClose
    ok !component.refs.btnUpdateAccessToken

  test 'maskedAccessToken', ->
    component = renderComponent({})
    equal component.maskedAccessToken(null), null
    equal component.maskedAccessToken('token'), 'token...'
