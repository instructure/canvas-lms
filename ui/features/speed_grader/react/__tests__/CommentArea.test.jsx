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
import {render} from '@testing-library/react'
import CommentArea from '../CommentArea'
import fakeEnv from '@canvas/test-utils/fakeENV'

describe('CommentArea', () => {
  let getTextAreaRefMock

  const defaultProps = () => {
    return {
      getTextAreaRef: getTextAreaRefMock,
      courseId: '1',
      userId: '1',
    }
  }

  beforeEach(() => {
    getTextAreaRefMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
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
})
