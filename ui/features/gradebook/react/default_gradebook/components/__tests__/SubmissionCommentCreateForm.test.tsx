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
import {fireEvent, render} from '@testing-library/react'
import SubmissionCommentCreateForm from '../SubmissionCommentCreateForm'

describe('SubmissionCommentCreateForm', () => {
  let props: any
  let wrapper: any
  let ref: any

  function mountComponent() {
    ref = React.createRef()
    return render(<SubmissionCommentCreateForm {...props} ref={ref} />)
  }

  function cancelButton() {
    return wrapper.container.querySelectorAll('button')[0]
  }

  function submitButton() {
    return wrapper.container.querySelectorAll('button')[1]
  }

  function cancelButtonComponent() {
    return wrapper.container.querySelectorAll('Button')[0]
  }

  function submitButtonComponent() {
    return wrapper.container.querySelectorAll('Button')[1]
  }

  beforeEach(() => {
    props = {
      cancelCommenting() {},
      createSubmissionComment() {},
      processing: false,
      setProcessing() {},
    }
  })

  test('"Submit" button is not present if there is no text entered in the comment area', () => {
    wrapper = mountComponent()
    expect(submitButton()).toBe(undefined)
  })

  test('"Cancel" button is not present if there is no text entered in the comment area', () => {
    wrapper = mountComponent()
    expect(cancelButton()).toBe(undefined)
  })

  test('"Submit" button is not present if the content is all spaces', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: '   '}})
    expect(submitButton()).toBe(undefined)
  })

  test('"Cancel" button is not present if the content is all spaces', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: '   '}})
    expect(cancelButton()).toBe(undefined)
  })

  test('"Submit" button is present, with proper text, if there is text entered in the comment area', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: 'some message'}})
    expect(submitButton()).toBeInTheDocument()
    expect(submitButton()).toHaveTextContent('Submit')
    expect(submitButtonComponent()).not.toBeDisabled()
  })

  test('"Cancel" button is present, with proper text, if there is text entered in the comment area', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: 'some message'}})
    expect(cancelButton()).toBeInTheDocument()
    expect(cancelButton()).toHaveTextContent('Cancel')
    expect(cancelButtonComponent()).not.toBeDisabled()
  })

  test('TextArea is empty, with label and placeholder', () => {
    wrapper = mountComponent()
    expect(wrapper.container.querySelector('TextArea')).toHaveValue('')
    expect(wrapper.container.querySelector('TextArea').placeholder).toEqual('Leave a comment')
    expect(wrapper.container.querySelector('label').textContent).toEqual('Leave a comment')
  })

  test('the default action is prevented when handlePublishComment runs', () => {
    props.createSubmissionComment = jest.fn()
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: 'some message'}})
    const event = {
      preventDefault: jest.fn(),
    }
    ref.current.handlePublishComment(event)
    expect(event.preventDefault).toHaveBeenCalledTimes(1)
  })

  test('focuses on the textarea after a successful comment post', () => {
    props.createSubmissionComment = jest.fn()
    wrapper = mountComponent()
    ref.current.focusTextarea = jest.fn()
    fireEvent.change(wrapper.container.querySelector('Textarea'), {target: {value: 'some message'}})
    fireEvent.click(submitButton())
    expect(ref.current.focusTextarea).toHaveBeenCalledTimes(1)
  })

  test('"Submit" button is disabled while processing', () => {
    props.processing = true
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: 'some message'}})
    expect(submitButtonComponent()).toBeDisabled()
  })

  test('"Submit" button label reads "Submit Comment"', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: 'some message'}})
    expect(submitButton().getAttribute('label')).toEqual('Submit Comment')
  })

  test('clicking the "Submit" button calls setProcessing (with true) and createSubmissionComment', () => {
    props.createSubmissionComment = jest.fn()
    props.setProcessing = jest.fn()
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: 'some message'}})
    fireEvent.click(submitButton())
    expect(props.setProcessing).toHaveBeenCalledTimes(1)
    expect(props.setProcessing).toHaveBeenLastCalledWith(true)
    expect(props.createSubmissionComment).toHaveBeenCalledTimes(1)
  })

  test('clicking the "Submit" button clears the comment field', () => {
    props.createSubmissionComment = jest.fn()
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: 'some message'}})
    fireEvent.click(submitButton())
    expect(wrapper.container.querySelector('textarea')).toHaveValue('')
  })

  test('clicking the "Cancel" button triggers cancelCommenting', () => {
    props.cancelCommenting = jest.fn()
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: 'some message'}})
    fireEvent.click(cancelButton())
    expect(props.cancelCommenting).toHaveBeenCalledTimes(1)
  })
})
