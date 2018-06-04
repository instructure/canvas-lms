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

import {shallow} from 'enzyme'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import Header from 'jsx/assignments/ModerationHeader'

QUnit.module('ModerationHeader', {
  setup() {
    this.props = {
      anonymousModeratedMarkingEnabled: false,
      muted: false,
      onPublishClick() {},
      onReviewClick() {},
      onUnmuteClick() {},
      published: false,
      selectedStudentCount: 0,
      inflightAction: {
        review: false,
        publish: false,
        unmute: false
      },
      permissions: {editGrades: true}
    }
  },
  teardown() {
    this.props = null
  }
})

test('it renders', function() {
  const HeaderElement = <Header {...this.props} />
  const header = TestUtils.renderIntoDocument(HeaderElement)
  const headerNode = ReactDOM.findDOMNode(header)
  ok(headerNode, 'the DOM node mounted')
  ReactDOM.unmountComponentAtNode(headerNode.parentNode)
})

test('renders the publish button if the user has edit permissions', function() {
  const HeaderElement = <Header {...this.props} />
  const header = TestUtils.renderIntoDocument(HeaderElement)
  const headerNode = ReactDOM.findDOMNode(header)
  ok(header.publishBtn)
  ReactDOM.unmountComponentAtNode(headerNode.parentNode)
})

test('does not render the publish button if the user does not have edit permissions', function() {
  this.props.permissions.editGrades = false
  const HeaderElement = <Header {...this.props} />
  const header = TestUtils.renderIntoDocument(HeaderElement)
  const headerNode = ReactDOM.findDOMNode(header)
  notOk(header.publishBtn)
  ReactDOM.unmountComponentAtNode(headerNode.parentNode)
})

test('sets buttons to disabled if published prop is true', function() {
  this.props.published = true
  const HeaderElement = <Header {...this.props} />
  const header = TestUtils.renderIntoDocument(HeaderElement)
  const headerNode = ReactDOM.findDOMNode(header)
  const addReviewerBtnNode = ReactDOM.findDOMNode(header.refs.addReviewerBtn)
  const publishBtnNode = header.publishBtn
  ok(addReviewerBtnNode.disabled, 'add reviewers button is disabled')
  ok(publishBtnNode.disabled, 'publish button is disabled')
  ReactDOM.unmountComponentAtNode(headerNode.parentNode)
})

test('disables Publish button if publish action is in flight', function() {
  this.props.inflightAction.publish = true
  const HeaderElement = <Header {...this.props} />
  const header = TestUtils.renderIntoDocument(HeaderElement)
  const headerNode = ReactDOM.findDOMNode(header)
  const publishBtnNode = header.publishBtn
  ok(publishBtnNode.disabled, 'publish button is disabled')
  ReactDOM.unmountComponentAtNode(headerNode.parentNode)
})

test('disables Add Reviewer button if selectedStudentCount is 0', function() {
  const HeaderElement = <Header {...this.props} />
  const header = TestUtils.renderIntoDocument(HeaderElement)
  const headerNode = ReactDOM.findDOMNode(header)
  const addReviewerBtnNode = ReactDOM.findDOMNode(header.refs.addReviewerBtn)
  ok(addReviewerBtnNode.disabled, 'add reviewers button is disabled')
  ReactDOM.unmountComponentAtNode(headerNode.parentNode)
})

test('enables Add Reviewer button if selectedStudentCount > 0', function() {
  this.props.selectedStudentCount = 1
  const HeaderElement = <Header {...this.props} />
  const header = TestUtils.renderIntoDocument(HeaderElement)
  const headerNode = ReactDOM.findDOMNode(header)
  const addReviewerBtnNode = ReactDOM.findDOMNode(header.refs.addReviewerBtn)
  notOk(addReviewerBtnNode.disabled, 'add reviewers button is disabled')
  ReactDOM.unmountComponentAtNode(headerNode.parentNode)
})

test('disables Add Reviewer button if review action is in flight', function() {
  this.props.selectedStudentCount = 1
  this.props.inflightAction.review = true
  const HeaderElement = <Header {...this.props} />
  const header = TestUtils.renderIntoDocument(HeaderElement)
  const headerNode = ReactDOM.findDOMNode(header)
  const addReviewerBtnNode = ReactDOM.findDOMNode(header.refs.addReviewerBtn)
  ok(addReviewerBtnNode.disabled, 'add reviewers button is disabled')
  ReactDOM.unmountComponentAtNode(headerNode.parentNode)
})

test('calls onReviewClick prop when review button is clicked', function() {
  let called = false
  this.props.selectedStudentCount = 1 // Since the default (0) means the button will be disabled
  this.props.onReviewClick = function() {
    called = true
  }
  const HeaderElement = <Header {...this.props} />
  const header = TestUtils.renderIntoDocument(HeaderElement)
  const addReviewerBtnNode = ReactDOM.findDOMNode(header.refs.addReviewerBtn)
  TestUtils.Simulate.click(addReviewerBtnNode)
  ok(called, 'onReviewClick was called')
})

test('show information message when published', function() {
  this.props.published = true
  const HeaderElement = <Header {...this.props} />
  const header = TestUtils.renderIntoDocument(HeaderElement)
  const headerNode = ReactDOM.findDOMNode(header)
  const message = TestUtils.findRenderedDOMComponentWithClass(header, 'ic-notification')
  ok(message, 'found the flash messge')
  ReactDOM.unmountComponentAtNode(headerNode.parentNode)
})

QUnit.module('ModerationHeader#unmuteAssignmentButton', (hooks) => {
  let props
  let renderHeader
  let wrapper
  let unmuteButtonSelector

  hooks.beforeEach(() => {
    props = {
      anonymousModeratedMarkingEnabled: true,
      muted: true,
      onPublishClick() {},
      onReviewClick() {},
      onUnmuteClick() {},
      published: false,
      selectedStudentCount: 0,
      inflightAction: {
        review: false,
        publish: false,
        unmute: false
      },
      permissions: {editGrades: true}
    }

    renderHeader = () => {
      wrapper = shallow(<Header {...props} />)
    }

    unmuteButtonSelector = '.ModeratedGrading__Header-UnmuteBtn'
  })

  hooks.afterEach(() => {
    wrapper.unmount()
  })

  test('renders the unmute button if Anonymous Moderated Marking is enabled', () => {
    renderHeader()
    strictEqual(wrapper.find(unmuteButtonSelector).exists(), true)
  })

  test('does not render the unmute button if Anonymous Moderated Marking is not enabled', () => {
    props.anonymousModeratedMarkingEnabled = false

    renderHeader()
    strictEqual(wrapper.find(unmuteButtonSelector).exists(), false)
  })

  test('enables the unmute button if the assignment is published and muted', () => {
    props.published = true
    props.muted = true

    renderHeader()
    strictEqual(wrapper.find(unmuteButtonSelector).prop('disabled'), false)
  })

  test('disables the unmute button if the assignment is not published', () => {
    props.published = false

    renderHeader()
    strictEqual(wrapper.find(unmuteButtonSelector).prop('disabled'), true)
  })

  test('disables the unmute button if the assignment is published but not muted', () => {
    props.published = true
    props.muted = false

    renderHeader()
    strictEqual(wrapper.find(unmuteButtonSelector).prop('disabled'), true)
  })

  test('disables the unmute button if the unmute action is in flight', () => {
    props.inflightAction.unmute = true

    renderHeader()
    strictEqual(wrapper.find(unmuteButtonSelector).prop('disabled'), true)
  })

  test('has the text "Display to Students"', () => {
    renderHeader()
    strictEqual(wrapper.find(unmuteButtonSelector).first().text(), 'Display to Students')
  })
})
