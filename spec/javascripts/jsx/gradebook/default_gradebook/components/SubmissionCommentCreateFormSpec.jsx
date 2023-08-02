/* * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'
import {mount} from 'enzyme'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import SubmissionCommentCreateForm from 'ui/features/gradebook/react/default_gradebook/components/SubmissionCommentCreateForm'

QUnit.module('SubmissionCommentCreateForm', hooks => {
  let props
  let wrapper

  function mountComponent() {
    return mount(<SubmissionCommentCreateForm {...props} />)
  }

  function cancelButton() {
    return wrapper.find('button').at(0)
  }

  function submitButton() {
    return wrapper.find('button').at(1)
  }

  function cancelButtonComponent() {
    return wrapper.find('Button').at(0)
  }

  function submitButtonComponent() {
    return wrapper.find('Button').at(1)
  }

  hooks.beforeEach(() => {
    props = {
      cancelCommenting() {},
      createSubmissionComment() {},
      processing: false,
      setProcessing() {},
    }
  })

  hooks.afterEach(() => {
    wrapper.unmount()
  })

  test('"Submit" button is not present if there is no text entered in the comment area', () => {
    wrapper = mountComponent()
    strictEqual(submitButton().length, 0)
  })

  test('"Cancel" button is not present if there is no text entered in the comment area', () => {
    wrapper = mountComponent()
    strictEqual(cancelButton().length, 0)
  })

  test('"Submit" button is not present if the content is all spaces', () => {
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: '   '}})
    strictEqual(submitButton().length, 0)
  })

  test('"Cancel" button is not present if the content is all spaces', () => {
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: '   '}})
    strictEqual(cancelButton().length, 0)
  })

  test('"Submit" button is present if there is text entered in the comment area', () => {
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    strictEqual(submitButton().length, 1)
  })

  test('"Cancel" button is present if there is text entered in the comment area', () => {
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    strictEqual(cancelButton().length, 1)
  })

  test('"Submit" button is not disabled', () => {
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    strictEqual(submitButtonComponent().prop('disabled'), false)
  })

  test('"Cancel" button is not disabled', () => {
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    strictEqual(cancelButtonComponent().prop('disabled'), false)
  })

  test('"Submit" button has the text "Submit"', () => {
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    strictEqual(submitButton().text(), 'Submit')
  })

  test('"Cancel" button has the text "Cancel"', () => {
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    strictEqual(cancelButton().text(), 'Cancel')
  })

  test('TextArea is empty', () => {
    wrapper = mountComponent()
    strictEqual(wrapper.find('TextArea').first().prop('value'), '')
  })

  test('TextArea has a placeholder message', () => {
    wrapper = mountComponent()
    strictEqual(wrapper.find('TextArea').first().prop('placeholder'), 'Leave a comment')
  })

  test('TextArea has a label', () => {
    wrapper = mountComponent()
    ok(wrapper.find('label').contains(<ScreenReaderContent>Leave a comment</ScreenReaderContent>))
  })

  test('the default action is prevented when the button is clicked', () => {
    props.createSubmissionComment = sinon.stub().resolves()
    wrapper = mountComponent()
    const event = {
      preventDefault: sinon.stub(),
    }
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    submitButton().simulate('click', event)
    strictEqual(event.preventDefault.callCount, 1)
  })

  test('focuses on the textarea after a successful comment post', () => {
    props.createSubmissionComment = sinon.stub().resolves()
    wrapper = mountComponent()
    const focusTextArea = sinon.stub(wrapper.instance().textarea, 'focus')
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    submitButton().simulate('click')
    strictEqual(focusTextArea.callCount, 1)
  })

  test('"Submit" button is disabled while processing', () => {
    props.processing = true
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    strictEqual(submitButtonComponent().prop('disabled'), true)
  })

  test('"Submit" button label reads "Submit Comment"', () => {
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    strictEqual(submitButton().prop('label'), 'Submit Comment')
  })

  test('clicking the "Submit" button calls setProcessing', () => {
    props.createSubmissionComment = sinon.stub().resolves()
    props.setProcessing = sinon.stub()
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    submitButton().simulate('click')
    strictEqual(props.setProcessing.callCount, 1)
  })

  test('clicking the "Submit" button calls setProcessing with true', () => {
    props.createSubmissionComment = sinon.stub().resolves()
    props.setProcessing = sinon.stub()
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    submitButton().simulate('click')
    strictEqual(props.setProcessing.firstCall.args[0], true)
  })

  test('createSubmissionComment is called when the comment is valid and the "Submit" button is clicked', () => {
    props.createSubmissionComment = sinon.stub().resolves()
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'some message'}})
    submitButton().simulate('click')
    strictEqual(props.createSubmissionComment.callCount, 1)
  })

  test('clicking the "Submit" button clears the comment field', () => {
    props.createSubmissionComment = sinon.stub().resolves()
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'a message'}})
    submitButton().simulate('click')
    strictEqual(wrapper.find('textarea').prop('value'), '')
  })

  test('clicking the "Cancel" button triggers cancelCommenting', () => {
    props.cancelCommenting = sinon.stub()
    wrapper = mountComponent()
    wrapper.find('textarea').simulate('change', {target: {value: 'a message'}})
    cancelButton().simulate('click')
    strictEqual(props.cancelCommenting.callCount, 1)
  })
})
