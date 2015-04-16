define [
  'jquery',
  'jsx/shared/modal',
  'react',
  'jsx/shared/modal-content',
  'jsx/shared/modal-buttons'
], ($, Modal, React, ModalContent, ModalButtons) ->

  TestUtils = React.addons.TestUtils

  module 'Modal',
    teardown: ->
      React.unmountComponentAtNode(@component.getDOMNode().parentNode)

  test  'has a default class of, "ReactModal__Content--canvas"', ->
    @component = TestUtils.renderIntoDocument(Modal(
      isOpen: true,
      title: "Hello",
        "Inner content"
      ))

    ok $('.ReactModalPortal').find('.ReactModal__Content--canvas').length == 1

  test  'can create a custom content class', ->
    @component = TestUtils.renderIntoDocument(Modal(
      isOpen: true,
      className: 'custom_class_name'
      title: "Hello",
        "Inner content"
      ))

    ok $('.ReactModalPortal').find('.custom_class_name').length == 1, "allows custom content class name"

  test  'can create a custom overlay class name', ->
    @component = TestUtils.renderIntoDocument(Modal(
      isOpen: true,
      overlayClassName: 'custom_overlay_class_name'
      title: "Hello",
        "Inner content"
      ))

    ok $('.ReactModalPortal').find('.custom_overlay_class_name').length == 1, "allows custom overlay class name"

  test  'renders ModalContent inside of modal', ->
    @component = TestUtils.renderIntoDocument(Modal(
      isOpen: true,
      overlayClassName: 'custom_overlay_class_name'
      title: "Hello",
        ModalContent {className: 'childContent'},
          "word"
      ))

    ok $('.ReactModalPortal').find('.childContent').length == 1, "puts child content in the modal"

  test  'renders ModalButtons inside of modal', ->
    @component = TestUtils.renderIntoDocument(Modal(
      isOpen: true,
      overlayClassName: 'custom_overlay_class_name'
      title: "Hello",
        ModalButtons {className: 'buttonContent'},
          "buttons here"
      ))

    ok $('.ReactModalPortal').find('.buttonContent').length == 1, "puts button component in the modal"

  test 'closes the modal with the X function when the X is pressed', ->
    functionCalled = false
    mockFunction = ->
      functionCalled = true
      
    @component = TestUtils.renderIntoDocument(Modal({
      isOpen: true,
      onRequestClose: ->
      title: "Hello"
      closeWithX: mockFunction
    },
      ModalButtons {className: 'buttonContent'},
        "buttons here"
      ))

    TestUtils.Simulate.click(@component.refs.closeWithX.getDOMNode())
    # how do you know the modal isn't there? check a class, maybe check the state of the modal
    ok functionCalled, "calls closeWithX"
    equal @component.state.modalIsOpen, false, "modal open state is false"
    equal $('.ReactModal__Layout').length, 0, "html elements aren't on the page"

  test "updates modalIsOpen when props change", ->
    @component = TestUtils.renderIntoDocument(Modal({
      isOpen: false
      onRequestClose: ->
      title: "Hello"
    }
    ,
      ModalButtons {className: 'buttonContent'},
        "buttons here"
      ))

    equal @component.state.modalIsOpen, false, "props are false"
    @component.componentWillReceiveProps(isOpen: true)
    ok @component.state.modalIsOpen, "props change to true"

  test "closeModal() set modal open state to false and calls onRequestClose", ->
    calledOnRequestClose = false
    oRC = ->
      calledOnRequestClose = true
    @component = TestUtils.renderIntoDocument(Modal({
      isOpen: true
      onRequestClose: oRC
      title: "Hello"
    }
    ,
      ModalButtons {className: 'buttonContent'},
        "buttons here"
      ))

    @component.closeModal()
    equal @component.state.modalIsOpen, false, "closes modal"
    ok calledOnRequestClose, "calls on request close"
