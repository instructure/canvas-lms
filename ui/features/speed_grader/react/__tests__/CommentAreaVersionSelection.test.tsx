/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import fakeEnv from '@canvas/test-utils/fakeENV'

vi.mock('../CommentLibrary', () => {
  return {
    default: function MockCommentLibraryV1() {
      return <div data-testid="comment-library-v1">CommentLibrary V1</div>
    },
  }
})

vi.mock('../CommentLibraryV2/CommentLibrary', () => {
  return {
    CommentLibrary: function MockCommentLibraryV2() {
      return <div data-testid="comment-library-v2">CommentLibrary V2</div>
    },
  }
})

import CommentArea from '../CommentArea'

describe('CommentArea - Comment Library Version Selection', () => {
  let getTextAreaRefMock: ReturnType<typeof vi.fn>

  const defaultProps = () => ({
    getTextAreaRef: getTextAreaRefMock,
    courseId: '1',
    userId: '1',
    useRCELite: false,
    handleCommentChange: vi.fn(),
    currentText: '',
    readOnly: false,
  })

  beforeEach(() => {
    getTextAreaRefMock = vi.fn()
  })

  afterEach(() => {
    vi.clearAllMocks()
    fakeEnv.teardown()
  })

  it('renders CommentLibraryV2 when use_comment_library_v2 flag is enabled', () => {
    fakeEnv.setup({
      assignment_comment_library_feature_enabled: true,
      use_comment_library_v2: true,
    })
    const {getByTestId} = render(<CommentArea {...defaultProps()} />)

    expect(getByTestId('comment-library-v2')).toBeInTheDocument()
  })

  it('renders CommentLibrary V1 when use_comment_library_v2 flag is disabled', () => {
    fakeEnv.setup({
      assignment_comment_library_feature_enabled: true,
      use_comment_library_v2: false,
    })
    const {getByTestId} = render(<CommentArea {...defaultProps()} />)

    expect(getByTestId('comment-library-v1')).toBeInTheDocument()
  })
})
