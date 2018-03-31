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
import Modal from 'jsx/shared/modal'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import ModalContent from 'jsx/shared/modal-content'
import ModalButtons from 'jsx/shared/modal-buttons'

QUnit.module('Modal', {
  setup() {
    return $('body').append('<div id=application />')
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(this.component.getDOMNode().parentNode)
    return $('#application').remove()
  }
})

test('has a default class of, "ReactModal__Content--canvas"', function() {
  const ModalElement = (
    <Modal isOpen title="Hello">
      inner content
    </Modal>
  )
  this.component = TestUtils.renderIntoDocument(ModalElement)
  ok($('.ReactModalPortal').find('.ReactModal__Content--canvas').length === 1)
})

test('can create a custom content class', function() {
  this.component = TestUtils.renderIntoDocument(
    <Modal isOpen className="custom_class_name" title="Hello">
      Inner content
    </Modal>
  )
  ok(
    $('.ReactModalPortal').find('.custom_class_name').length === 1,
    'allows custom content class name'
  )
})

test('can create a custom overlay class name', function() {
  this.component = TestUtils.renderIntoDocument(
    <Modal isOpen overlayClassName="custom_overlay_class_name" title="Hello">
      Inner content
    </Modal>
  )
  ok(
    $('.ReactModalPortal').find('.custom_overlay_class_name').length === 1,
    'allows custom overlay class name'
  )
})

test('renders ModalContent inside of modal', function() {
  this.component = TestUtils.renderIntoDocument(
    <Modal isOpen overlayClassName="custom_overlay_class_name" title="Hello">
      <ModalContent className="childContent">word</ModalContent>
    </Modal>
  )
  ok($('.ReactModalPortal').find('.childContent').length === 1, 'puts child content in the modal')
})

test('renders ModalButtons inside of modal', function() {
  this.component = TestUtils.renderIntoDocument(
    <Modal isOpen overlayClassName="custom_overlay_class_name" title="Hello">
      <ModalButtons className="buttonContent">buttons here</ModalButtons>
    </Modal>
  )
  ok(
    $('.ReactModalPortal').find('.buttonContent').length === 1,
    'puts button component in the modal'
  )
})

test('closes the modal with the X function when the X is pressed', function() {
  let functionCalled = false
  const mockFunction = () => (functionCalled = true)
  this.component = TestUtils.renderIntoDocument(
    <Modal isOpen onRequestClose={function() {}} title="Hello" closeWithX={mockFunction}>
      <ModalButtons className="buttonContent">buttons here</ModalButtons>
    </Modal>
  )
  TestUtils.Simulate.click(this.component.closeBtn)
  ok(functionCalled, 'calls closeWithX')
  equal(this.component.state.modalIsOpen, false, 'modal open state is false')
  equal($('.ReactModal__Layout').length, 0, "html elements aren't on the page")
})

test('updates modalIsOpen when props change', function() {
  this.component = TestUtils.renderIntoDocument(
    <Modal isOpen={false} onRequestClose={function() {}} title="Hello">
      <ModalButtons className="buttonContent">buttons here</ModalButtons>
    </Modal>
  )
  equal(this.component.state.modalIsOpen, false, 'props are false')
  this.component.componentWillReceiveProps({isOpen: true})
  ok(this.component.state.modalIsOpen, 'props change to true')
})

test('Sets the iframe allowances', function() {
  const spy = sinon.spy()
  this.component = TestUtils.renderIntoDocument(
    <Modal
      isOpen
      onRequestClose={function() {}}
      title="Hello"
      closeWithX={function() {}}
      onAfterOpen={spy}
    >
      <ModalButtons className="buttonContent">buttons here</ModalButtons>
    </Modal>
  )
  ok(spy.called)
})

test('closeModal() set modal open state to false and calls onRequestClose', function() {
  let calledOnRequestClose = false
  const oRC = () => (calledOnRequestClose = true)
  this.component = TestUtils.renderIntoDocument(
    <Modal isOpen onRequestClose={oRC} title="Hello">
      <ModalButtons className="buttonContent">buttons here</ModalButtons>
    </Modal>
  )
  this.component.closeModal()
  equal(this.component.state.modalIsOpen, false, 'closes modal')
  ok(calledOnRequestClose, 'calls on request close')
})

test("doesn't default to attaching to body", function() {
  this.component = TestUtils.renderIntoDocument(
    <Modal isOpen className="custom_class_name" title="Hello">
      Inner content
    </Modal>
  )
  equal($('body').attr('aria-hidden'), undefined, "doesn't attach aria-hidden to body")
})

test('defaults to attaching to #application', function() {
  this.component = TestUtils.renderIntoDocument(
    <Modal isOpen className="custom_class_name" title="Hello">
      Inner content
    </Modal>
  )
  equal($('#application').attr('aria-hidden'), 'true', 'attaches to application')
})

test('removes aria-hidden from #application when closed', function() {
  this.component = TestUtils.renderIntoDocument(
    <Modal onRequestClose={function() {}} isOpen className="custom_class_name" title="Hello">
      Inner content
    </Modal>
  )
  this.component.closeModal()
  equal($('#application').attr('aria-hidden'), undefined, 'removes aria-hidden attribute')
})

test('appElement sets react modals app element', function() {
  this.component = TestUtils.renderIntoDocument(
    <Modal appElement={$('#fixtures')[0]} isOpen className="custom_class_name" title="Hello">
      Inner content
    </Modal>
  )
  equal($('#fixtures').attr('aria-hidden'), 'true', 'attaches to the specified dom element')
})

test('removes aria-hidden from custom setElement property when closed', function() {
  this.component = TestUtils.renderIntoDocument(
    <Modal
      onRequestClose={function() {}}
      appElement={$('#fixtures')[0]}
      isOpen
      className="custom_class_name"
      title="Hello"
    >
      Inner content
    </Modal>
  )
  this.component.closeModal()
  equal($('#fixtures').attr('aria-hidden'), undefined, 'no aria-hidden attribute on element')
})
