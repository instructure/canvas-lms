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
import {createEvent, fireEvent, render, screen, waitFor} from '@testing-library/react'
import SubmissionCommentUpdateForm from '../SubmissionCommentUpdateForm'

describe('SubmissionCommentUpdateForm', () => {
  let props: any
  let wrapper: any
  let ref: any

  function mountComponent() {
    ref = React.createRef()
    return render(<SubmissionCommentUpdateForm {...props} ref={ref} />)
  }

  beforeEach(() => {
    props = {
      cancelCommenting() {},
      comment: 'A comment',
      id: '23',
      updateSubmissionComment() {},
      processing: false,
      setProcessing() {},
    }
  })

  test('initializes with the original comment in the textarea', () => {
    wrapper = mountComponent()
    expect(wrapper.container.querySelector('textarea')).toHaveValue('A comment')
  })

  test('"Submit" button is present even if there is no text entered in the comment area', () => {
    props.comment = ''
    wrapper = mountComponent()
    expect(wrapper.container.querySelector('textarea')).toHaveValue('')
  })

  test('"Cancel" button is present even if there is no text entered in the comment area', () => {
    props.comment = ''
    wrapper = mountComponent()
    expect(screen.getByTestId('comment-cancel-button')).toBeInTheDocument()
  })

  test('"Submit" button is present if the content is all spaces', () => {
    props.comment = '    '
    wrapper = mountComponent()
    expect(screen.getByTestId('comment-submit-button')).toBeInTheDocument()
  })

  test('"Cancel" button is present if the content is all spaces', () => {
    props.comment = '    '
    wrapper = mountComponent()
    expect(screen.getByTestId('comment-cancel-button')).toBeInTheDocument()
  })

  test('"Submit" button is present if there is text entered in the comment area', () => {
    wrapper = mountComponent()
    expect(screen.getByTestId('comment-submit-button')).toBeInTheDocument()
  })

  test('"Cancel" button is present if there is text entered in the comment area', () => {
    wrapper = mountComponent()
    expect(screen.getByTestId('comment-cancel-button')).toBeInTheDocument()
  })

  test('"Submit" button is disabled if the current comment is the same as the comment prop passed in', () => {
    wrapper = mountComponent()
    expect(screen.getByTestId('comment-submit-button')).toBeDisabled()
  })

  test('"Cancel" button is enabled if the current comment is the same as the comment prop passed in', () => {
    wrapper = mountComponent()
    expect(screen.getByTestId('comment-cancel-button')).not.toBeDisabled()
  })

  test('"Submit" button is disabled if the current comment after trimming is the same as the comment prop passed', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {
      target: {value: '    A comment    '},
    })
    expect(screen.getByTestId('comment-submit-button')).toBeDisabled()
  })

  test('"Cancel" button is enabled if the current comment after trimming is the same as the comment prop passed', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {
      target: {value: '    A comment    '},
    })
    expect(screen.getByTestId('comment-cancel-button')).not.toBeDisabled()
  })

  test('"Submit" button is disabled if the all the content in the comment is removed', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: ''}})
    expect(screen.getByTestId('comment-submit-button')).toBeDisabled()
  })

  test('"Cancel" button is enabled if the all the content in the comment is removed', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: ''}})
    expect(screen.getByTestId('comment-cancel-button')).not.toBeDisabled()
  })

  test('"Submit" button is disabled if the all the content in the comment is removed except for spaces', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: '     '}})
    expect(screen.getByTestId('comment-submit-button')).toBeDisabled()
  })

  test('"Cancel" button is enabled if the all the content in the comment is removed except for spaces', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {target: {value: '     '}})
    expect(screen.getByTestId('comment-cancel-button')).not.toBeDisabled()
  })

  test('"Submit" button is disabled while processing', () => {
    props.processing = true
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {
      target: {value: 'A changed comment'},
    })
    expect(screen.getByTestId('comment-submit-button')).toBeDisabled()
  })

  test('"Cancel" button is disabled while processing', () => {
    props.processing = true
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {
      target: {value: 'A changed comment'},
    })
    expect(screen.getByTestId('comment-cancel-button')).toBeDisabled()
  })

  test('"Submit" button is enabled if the comment is changed and is not empty', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {
      target: {value: 'A changed comment'},
    })
    expect(screen.getByTestId('comment-submit-button')).not.toBeDisabled()
  })

  test('"Cancel" button is enabled if the comment is changed and is not empty', () => {
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {
      target: {value: 'A changed comment'},
    })
    expect(screen.getByTestId('comment-cancel-button')).not.toBeDisabled()
  })

  test('"Submit" button has the text "Submit"', () => {
    wrapper = mountComponent()
    expect(screen.getByTestId('comment-submit-button').textContent).toEqual('Submit')
  })

  test('"Cancel" button has the text "Cancel"', () => {
    wrapper = mountComponent()
    expect(screen.getByTestId('comment-cancel-button').textContent).toEqual('Cancel')
  })

  test('"Submit" button label reads "Update Comment"', () => {
    wrapper = mountComponent()
    expect(screen.getByTestId('comment-submit-button').getAttribute('label')).toEqual(
      'Update Comment'
    )
  })

  test('"Cancel" button label reads "Cancel Updating Comment"', () => {
    wrapper = mountComponent()
    expect(screen.getByTestId('comment-cancel-button').getAttribute('label')).toEqual(
      'Cancel Updating Comment'
    )
  })

  test('TextArea has a placeholder message', () => {
    wrapper = mountComponent()
    expect(wrapper.container.querySelector('TextArea').getAttribute('placeholder')).toEqual(
      'Leave a comment'
    )
  })

  test('TextArea has a label', () => {
    wrapper = mountComponent()
    const screenReaderSpan = wrapper.container.querySelector('label > span > span > span')
    expect(screenReaderSpan.textContent).toEqual('Leave a comment')
  })

  test('focuses on the textarea when mounted', () => {
    wrapper = mountComponent()
    ref.current.componentDidMount()
    expect(wrapper.container.querySelector('TextArea').matches(':focus')).toBe(true)
  })

  test('the default action is prevented when the button is clicked', async () => {
    props.updateSubmissionComment = jest.fn(() => Promise.resolve())
    wrapper = mountComponent()
    const preventDefault = jest.fn()
    fireEvent.change(wrapper.container.querySelector('textarea'), {
      target: {value: 'A changed comment'},
    })
    const clickEvent = createEvent.click(screen.getByTestId('comment-submit-button'), {
      preventDefault,
      button: 1,
    })
    fireEvent(screen.getByTestId('comment-submit-button'), clickEvent)
    expect(clickEvent.defaultPrevented).toBe(true)
  })

  test('clicking the "Submit" button calls setProcessing', () => {
    props.updateSubmissionComment = jest.fn(() => Promise.resolve())
    props.setProcessing = jest.fn()
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {
      target: {value: 'A changed comment'},
    })
    fireEvent.click(screen.getByTestId('comment-submit-button'))
    expect(props.setProcessing).toHaveBeenCalledTimes(1)
    expect(props.setProcessing).toHaveBeenCalledWith(true)
    expect(props.updateSubmissionComment).toHaveBeenCalledTimes(1)
    expect(props.updateSubmissionComment).toHaveBeenLastCalledWith('A changed comment', '23')
  })

  test('clicking the "Cancel" button triggers cancelCommenting', () => {
    props.cancelCommenting = jest.fn()
    wrapper = mountComponent()
    fireEvent.change(wrapper.container.querySelector('textarea'), {
      target: {value: 'A changed comment'},
    })
    fireEvent.click(screen.getByTestId('comment-cancel-button'))
    expect(props.cancelCommenting).toHaveBeenCalledTimes(1)
  })
})
