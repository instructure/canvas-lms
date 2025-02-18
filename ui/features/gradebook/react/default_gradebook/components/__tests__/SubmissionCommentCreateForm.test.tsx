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
import {fireEvent, render, waitFor} from '@testing-library/react'
import SubmissionCommentCreateForm from '../SubmissionCommentCreateForm'
import {ViewProps} from '@instructure/ui-view'

describe('SubmissionCommentCreateForm', () => {
  let props: any
  let wrapper: ReturnType<typeof mountComponent>
  let ref: React.RefObject<SubmissionCommentCreateForm>
  let target: HTMLElement

  function mountComponent() {
    ref = React.createRef()
    return render(<SubmissionCommentCreateForm {...props} ref={ref} />, {container: target})
  }

  const queryCancelButton = () => wrapper.queryByTestId('comment-cancel-button')
  const getCancelButton = () => wrapper.getByTestId('comment-cancel-button')
  const querySubmitButton = () => wrapper.queryByTestId('comment-submit-button')
  const getSubmitButton = () => wrapper.getByTestId('comment-submit-button')
  const getTextarea = async () => {
    await waitFor(() => expect(wrapper.container.querySelector('textarea')).toBeInTheDocument())
    return wrapper.container.querySelector('textarea') as HTMLTextAreaElement
  }

  const commonTestCases = () => {
    test('"Submit" button is not present if there is no text entered in the comment area', () => {
      wrapper = mountComponent()
      expect(querySubmitButton()).not.toBeInTheDocument()
    })

    test('"Cancel" button is not present if there is no text entered in the comment area', () => {
      wrapper = mountComponent()
      expect(queryCancelButton()).not.toBeInTheDocument()
    })

    test('"Submit" button is not present if the content is all spaces', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: '   '}})
      expect(querySubmitButton()).not.toBeInTheDocument()
    })

    test('"Cancel" button is not present if the content is all spaces', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: '   '}})
      expect(queryCancelButton()).not.toBeInTheDocument()
    })

    test('"Submit" button is present, with proper text, if there is text entered in the comment area', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'some message'}})
      expect(getSubmitButton()).toBeInTheDocument()
      expect(getSubmitButton()).toHaveTextContent('Submit')
      expect(getSubmitButton()).not.toBeDisabled()
    })

    test('"Cancel" button is present, with proper text, if there is text entered in the comment area', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {
        target: {value: 'some message'},
      })
      expect(getCancelButton()).toBeInTheDocument()
      expect(getCancelButton()).toHaveTextContent('Cancel')
      expect(getCancelButton()).not.toBeDisabled()
    })

    test('the default action is prevented when handlePublishComment runs', async () => {
      props.createSubmissionComment = jest.fn()
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'some message'}})
      const event = {preventDefault: jest.fn()} as unknown as React.MouseEvent<ViewProps>
      ref.current?.handlePublishComment(event)
      expect(event.preventDefault).toHaveBeenCalledTimes(1)
    })

    test('"Submit" button is disabled while processing', async () => {
      props.processing = true
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'some message'}})
      expect(getSubmitButton()).toBeDisabled()
    })

    test('"Submit" button label reads "Submit Comment"', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'some message'}})
      expect(getSubmitButton().getAttribute('label')).toEqual('Submit Comment')
    })

    test('clicking the "Submit" button calls setProcessing (with true) and createSubmissionComment', async () => {
      props.createSubmissionComment = jest.fn()
      props.setProcessing = jest.fn()
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'some message'}})
      fireEvent.click(getSubmitButton())
      expect(props.setProcessing).toHaveBeenCalledTimes(1)
      expect(props.setProcessing).toHaveBeenLastCalledWith(true)
      expect(props.createSubmissionComment).toHaveBeenCalledTimes(1)
      expect(props.createSubmissionComment).toHaveBeenCalledWith('some message')
    })

    test('clicking the "Submit" button clears the comment field', async () => {
      props.createSubmissionComment = jest.fn()
      wrapper = mountComponent()
      const textarea = await getTextarea()
      fireEvent.change(textarea, {target: {value: 'some message'}})
      fireEvent.click(getSubmitButton())
      expect(textarea).toHaveValue('')
    })

    test('clicking the "Cancel" button calls createSubmissionComment', async () => {
      props.cancelCommenting = jest.fn()
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'some message'}})
      fireEvent.click(getCancelButton())
      expect(props.cancelCommenting).toHaveBeenCalledTimes(1)
    })

    test('clicking the "Cancel" button clears the comment field', async () => {
      wrapper = mountComponent()
      const textarea = await getTextarea()
      fireEvent.change(textarea, {target: {value: 'some message'}})
      fireEvent.click(getCancelButton())
      expect(textarea).toHaveValue('')
    })

    test('clicking the "Cancel" button triggers cancelCommenting', async () => {
      props.cancelCommenting = jest.fn()
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'some message'}})
      fireEvent.click(getCancelButton())
      expect(props.cancelCommenting).toHaveBeenCalledTimes(1)
    })
  }

  beforeEach(() => {
    // This is needed to silence the following error:
    // "[Alert] The 'screenReaderOnly' prop must be used in conjunction with 'liveRegion'"
    // Copied from ui/shared/rce/react/__tests__/CanvasRce.test.jsx
    const div = document.createElement('div')
    div.id = 'fixture'
    div.innerHTML = '<div id="flash_screenreader_holder" role="alert"/><div id="target"/>'
    document.body.appendChild(div)

    target = document.getElementById('target') as HTMLElement

    props = {
      cancelCommenting() {},
      createSubmissionComment() {},
      processing: false,
      setProcessing() {},
    }
  })

  afterEach(() => {
    const fixture = document.getElementById('fixture')
    if (fixture) document.body.removeChild(fixture)
  })

  describe('with RCE Lite enabled', () => {
    beforeEach(() => {
      window.ENV.FEATURES.rce_lite_enabled_speedgrader_comments = true
    })

    test('renders RCE input', async () => {
      const {container, queryByTestId} = mountComponent()
      await waitFor(() => {
        expect(container.querySelector('textarea[id="comment_rce_textarea"]')).toBeInTheDocument()
      })
      expect(queryByTestId('comment-textarea')).not.toBeInTheDocument()
    })

    test('focuses on the textarea after a successful comment post', async () => {
      props.createSubmissionComment = jest.fn()
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'some message'}})
      fireEvent.click(getSubmitButton())
      await getTextarea()

      expect(ref.current).not.toBeNull()
      expect(ref.current?.rceRef.current).not.toBeNull()
      expect(ref.current?.rceRef.current?.focused).toBe(true)
    })

    commonTestCases()
  })

  describe('with RCE Lite disabled', () => {
    beforeEach(() => {
      window.ENV.FEATURES.rce_lite_enabled_speedgrader_comments = false
    })

    test('renders regular input', () => {
      const {getByTestId, queryByText} = mountComponent()
      expect(getByTestId('comment-textarea')).toBeInTheDocument()
      // RCE displays a loading text initially
      expect(queryByText(/Loading/)).not.toBeInTheDocument()
    })

    test('TextArea has a placeholder message', () => {
      wrapper = mountComponent()
      const textarea = wrapper.getByPlaceholderText('Leave a comment')
      expect(textarea).toBeInTheDocument()
    })

    test('TextArea has a label', () => {
      wrapper = mountComponent()
      const textarea = wrapper.getByLabelText('Leave a comment')
      expect(textarea).toBeInTheDocument()
    })

    test('focuses on the textarea after a successful comment post', async () => {
      props.createSubmissionComment = jest.fn()
      wrapper = mountComponent()
      if (ref.current) jest.spyOn(ref.current, 'focusTextarea')
      const textarea = await getTextarea()
      fireEvent.change(textarea, {target: {value: 'some message'}})
      fireEvent.click(getSubmitButton())
      expect(ref.current?.focusTextarea).toHaveBeenCalledTimes(1)
      expect(textarea).toHaveFocus()
    })

    commonTestCases()
  })
})
