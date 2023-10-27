/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {AttachmentDisplay} from '../AttachmentDisplay'
import {responsiveQuerySizes} from '../../../utils'

const setup = props => {
  return render(
    <AttachmentDisplay
      setAttachment={() => {}}
      setAttachmentToUpload={() => {}}
      responsiveQuerySizes={responsiveQuerySizes}
      {...props}
    />
  )
}

describe('AttachmentDisplay', () => {
  afterEach(() => {
    window.ENV = {}
  })

  it('displays AttachButton when there is no attachment', () => {
    window.ENV.can_attach_entries = true
    const {queryByText} = setup({canAttach: window.ENV.can_attach_entries})
    expect(queryByText('Attach')).toBeTruthy()
  })

  it('does not display AttachButton when can_attach_entries is false', () => {
    window.ENV.can_attach_entries = false
    const {queryByText} = setup({canAttach: window.ENV.can_attach_entries})
    expect(queryByText('Attach')).toBeFalsy()
  })

  it('only allows one attachment at a time', () => {
    window.ENV.can_attach_entries = true
    const {queryByTestId} = setup({canAttach: window.ENV.can_attach_entries})
    expect(queryByTestId('attachment-input')).toHaveAttribute('type', 'file')
    expect(queryByTestId('attachment-input')).not.toHaveAttribute('multiple')
  })

  it('displays AttachmentButton when there is an attachment', () => {
    const {queryByText} = setup({
      attachment: {
        _id: 1,
        displayName: 'file_name.file',
        url: 'file_download_example.com',
      },
    })

    expect(queryByText('Attach')).toBeFalsy()
    expect(queryByText('file_name.file')).toBeTruthy()
  })

  it('truncates filenames > 30 characters', () => {
    const {queryByText} = setup({
      attachment: {
        _id: 1,
        displayName: 'Fundamentals of Differential Equations - Exercise 17 _ Quizlet.pdf',
        url: 'file_download_example.com',
      },
    })

    expect(queryByText('Attach')).toBeFalsy()
    expect(queryByText('Fundamentals of Differential E...')).toBeTruthy()
  })
})
