/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import CommentArea from '../CommentArea'
import fakeEnv from '@canvas/test-utils/fakeENV'

vi.mock('../CommentLibraryV2/CommentLibrary', () => {
  return {
    // eslint-disable-next-line react/prop-types
    CommentLibrary: function CommentLibrary({setComment, setFocusToTextArea}) {
      return (
        <div data-testid="comment-library-v2">
          <button onClick={() => setComment('Selected comment text')}>Insert Comment</button>
          <button onClick={() => setComment('Line 1\nLine 2\nLine 3')}>Insert Multiline</button>
          <button onClick={() => setFocusToTextArea()}>Focus TextArea</button>
        </div>
      )
    },
  }
})

describe('CommentArea', () => {
  let getTextAreaRefMock
  let handleCommentChangeMock

  const defaultProps = () => {
    return {
      getTextAreaRef: getTextAreaRefMock,
      courseId: '1',
      userId: '1',
      handleCommentChange: handleCommentChangeMock,
    }
  }

  beforeEach(() => {
    getTextAreaRefMock = vi.fn()
    handleCommentChangeMock = vi.fn()
  })

  afterEach(() => {
    vi.clearAllMocks()
    fakeEnv.teardown()
  })

  it('calls getTextAreaRef within TextArea', () => {
    render(<CommentArea {...defaultProps()} />)
    expect(getTextAreaRefMock).toHaveBeenCalled()
  })

  describe('with the comment library flag enabled', () => {
    beforeEach(() => {
      fakeEnv.setup({
        assignment_comment_library_feature_enabled: true,
      })
    })

    it('loads the comment library', () => {
      const {getByText} = render(<CommentArea {...defaultProps()} />)
      expect(getByText('Loading comment library')).toBeInTheDocument()
    })
  })

  describe('with the comment library flag disabled', () => {
    beforeEach(() => {
      fakeEnv.setup({
        assignment_comment_library_feature_enabled: false,
        context_asset_string: 'course_1',
      })
    })

    it('does not load the comment library', () => {
      const {queryByText} = render(<CommentArea {...defaultProps()} />)
      expect(queryByText('Loading comment library')).not.toBeInTheDocument()
    })
  })

  describe('with comment library v2 enabled', () => {
    beforeEach(() => {
      fakeEnv.setup({
        assignment_comment_library_feature_enabled: true,
        use_comment_library_v2: true,
      })
    })

    it('renders CommentLibraryWrapper when v2 flag is enabled', () => {
      const {getByTestId} = render(<CommentArea {...defaultProps()} />)
      expect(getByTestId('comment-library-v2')).toBeInTheDocument()
    })

    it('calls handleCommentChange when setComment is invoked from CommentLibraryWrapper', () => {
      const handleCommentChange = vi.fn()
      const {getByText} = render(
        <CommentArea {...defaultProps()} handleCommentChange={handleCommentChange} />,
      )

      fireEvent.click(getByText('Insert Comment'))
      expect(handleCommentChange).toHaveBeenCalledWith('Selected comment text', false)
    })

    it('focuses textarea when setFocusToTextArea is invoked from CommentLibraryWrapper', () => {
      const mockTextArea = {focus: vi.fn()}
      getTextAreaRefMock.mockImplementation(el => {
        if (el) {
          mockTextArea.focus = vi.fn()
          Object.assign(el, mockTextArea)
        }
      })

      const {getByText} = render(<CommentArea {...defaultProps()} />)

      fireEvent.click(getByText('Focus TextArea'))
      expect(mockTextArea.focus).toHaveBeenCalled()
    })

    describe('with RCE Lite enabled', () => {
      it('calls handleCommentChange when inserting comment', () => {
        const handleCommentChange = vi.fn()

        const {getByText} = render(
          <CommentArea
            {...defaultProps()}
            useRCELite={true}
            handleCommentChange={handleCommentChange}
          />,
        )

        fireEvent.click(getByText('Insert Comment'))

        expect(handleCommentChange).toHaveBeenCalledWith('Selected comment text', false)
      })

      it('renders without crashing when useRCELite is true', () => {
        const {container} = render(<CommentArea {...defaultProps()} useRCELite={true} />)
        expect(container).toBeInTheDocument()
      })
    })
  })
})
