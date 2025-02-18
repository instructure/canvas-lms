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
import {createEvent, fireEvent, render, waitFor} from '@testing-library/react'
import SubmissionCommentUpdateForm from '../SubmissionCommentUpdateForm'

describe('SubmissionCommentUpdateForm', () => {
  let props: any
  let wrapper: ReturnType<typeof mountComponent>
  let ref: React.RefObject<SubmissionCommentUpdateForm>
  let target: HTMLElement

  function mountComponent() {
    ref = React.createRef()
    return render(<SubmissionCommentUpdateForm {...props} ref={ref} />, {container: target})
  }

  const getCancelButton = () => wrapper.getByTestId('comment-cancel-button')
  const getSubmitButton = () => wrapper.getByTestId('comment-submit-button')
  const getTextarea = async () => {
    await waitFor(() => expect(wrapper.container.querySelector('textarea')).toBeInTheDocument())
    return wrapper.container.querySelector('textarea') as HTMLTextAreaElement
  }

  const commonTestCases = () => {
    test('initializes with the original comment in the textarea', async () => {
      wrapper = mountComponent()
      expect(await getTextarea()).toHaveValue('A comment')
    })

    test('"Submit" button is present even if there is no text entered in the comment area', async () => {
      props.comment = ''
      wrapper = mountComponent()
      expect(await getTextarea()).toHaveValue('')
    })

    test('"Cancel" button is present even if there is no text entered in the comment area', () => {
      props.comment = ''
      wrapper = mountComponent()
      expect(getCancelButton()).toBeInTheDocument()
    })

    test('"Submit" button is present if the content is all spaces', () => {
      props.comment = '    '
      wrapper = mountComponent()
      expect(getSubmitButton()).toBeInTheDocument()
    })

    test('"Cancel" button is present if the content is all spaces', () => {
      props.comment = '    '
      wrapper = mountComponent()
      expect(getCancelButton()).toBeInTheDocument()
    })

    test('"Submit" button is present if there is text entered in the comment area', () => {
      wrapper = mountComponent()
      expect(getSubmitButton()).toBeInTheDocument()
    })

    test('"Cancel" button is present if there is text entered in the comment area', () => {
      wrapper = mountComponent()
      expect(getCancelButton()).toBeInTheDocument()
    })

    test('"Submit" button is disabled if the current comment is the same as the comment prop passed in', () => {
      wrapper = mountComponent()
      expect(getSubmitButton()).toBeDisabled()
    })

    test('"Cancel" button is enabled if the current comment is the same as the comment prop passed in', () => {
      wrapper = mountComponent()
      expect(getCancelButton()).not.toBeDisabled()
    })

    test('"Submit" button is disabled if the current comment after trimming is the same as the comment prop passed', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: '    A comment    '}})
      expect(getSubmitButton()).toBeDisabled()
    })

    test('"Cancel" button is enabled if the current comment after trimming is the same as the comment prop passed', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: '    A comment    '}})
      expect(getCancelButton()).not.toBeDisabled()
    })

    test('"Submit" button is disabled if the all the content in the comment is removed', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: ''}})
      expect(getSubmitButton()).toBeDisabled()
    })

    test('"Cancel" button is enabled if the all the content in the comment is removed', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: ''}})
      expect(getCancelButton()).not.toBeDisabled()
    })

    test('"Submit" button is disabled if the all the content in the comment is removed except for spaces', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: '     '}})
      expect(getSubmitButton()).toBeDisabled()
    })

    test('"Cancel" button is enabled if the all the content in the comment is removed except for spaces', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: '     '}})
      expect(getCancelButton()).not.toBeDisabled()
    })

    test('"Submit" button is disabled while processing', async () => {
      props.processing = true
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'A changed comment'}})
      expect(getSubmitButton()).toBeDisabled()
    })

    test('"Cancel" button is disabled while processing', async () => {
      props.processing = true
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'A changed comment'}})
      expect(getCancelButton()).toBeDisabled()
    })

    test('"Submit" button is enabled if the comment is changed and is not empty', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'A changed comment'}})
      expect(getSubmitButton()).not.toBeDisabled()
    })

    test('"Cancel" button is enabled if the comment is changed and is not empty', async () => {
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'A changed comment'}})
      expect(getCancelButton()).not.toBeDisabled()
    })

    test('"Submit" button has the text "Submit"', () => {
      wrapper = mountComponent()
      expect(getSubmitButton().textContent).toEqual('Submit')
    })

    test('"Cancel" button has the text "Cancel"', () => {
      wrapper = mountComponent()
      expect(getCancelButton().textContent).toEqual('Cancel')
    })

    test('"Submit" button label reads "Update Comment"', () => {
      wrapper = mountComponent()
      expect(getSubmitButton().getAttribute('label')).toEqual('Update Comment')
    })

    test('"Cancel" button label reads "Cancel Updating Comment"', () => {
      wrapper = mountComponent()
      expect(getCancelButton().getAttribute('label')).toEqual('Cancel Updating Comment')
    })

    test('the default action is prevented when the button is clicked', async () => {
      props.updateSubmissionComment = jest.fn(() => Promise.resolve())
      wrapper = mountComponent()
      const preventDefault = jest.fn()
      fireEvent.change(await getTextarea(), {
        target: {value: 'A changed comment'},
      })
      const clickEvent = createEvent.click(getSubmitButton(), {
        preventDefault,
        button: 1,
      })
      fireEvent(getSubmitButton(), clickEvent)
      expect(clickEvent.defaultPrevented).toBe(true)
    })

    test('clicking the "Submit" button calls setProcessing (with true) and updateSubmissionComment', async () => {
      props.updateSubmissionComment = jest.fn(() => Promise.resolve())
      props.setProcessing = jest.fn()
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'A changed comment'}})
      fireEvent.click(getSubmitButton())
      expect(props.setProcessing).toHaveBeenCalledTimes(1)
      expect(props.setProcessing).toHaveBeenCalledWith(true)
      expect(props.updateSubmissionComment).toHaveBeenCalledTimes(1)
      expect(props.updateSubmissionComment).toHaveBeenLastCalledWith('A changed comment', '23')
    })

    test('clicking the "Cancel" button triggers cancelCommenting', async () => {
      props.cancelCommenting = jest.fn()
      wrapper = mountComponent()
      fireEvent.change(await getTextarea(), {target: {value: 'A changed comment'}})
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
      comment: 'A comment',
      id: '23',
      updateSubmissionComment() {},
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

    test('focuses on the textarea when mounted', async () => {
      wrapper = mountComponent()
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

    test('focuses on the textarea when mounted', async () => {
      wrapper = mountComponent()
      expect(await getTextarea()).toHaveFocus()
    })

    commonTestCases()
  })
})
