/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {AttachmentUploadSpinner} from '../AttachmentUploadSpinner'

const setup = props => {
  return render(
    <AttachmentUploadSpinner
      sendMessage={Function.prototype}
      isMessageSending={true}
      pendingUploads={['fake upload']}
      {...props}
    />
  )
}

describe('AttachmentUploadSpinner', () => {
  it('renders with default message and label', async () => {
    const {findByText, findByTitle} = setup()

    expect(await findByText('Please wait while we upload attachments.')).toBeInTheDocument()
    expect(await findByTitle('Uploading Files')).toBeInTheDocument()
  })

  it('renders with custom message and label', async () => {
    const label = 'test-label-123'
    const message = 'test-message-123'
    const {findByText, findByTitle} = setup({label, message})

    expect(await findByText(message)).toBeInTheDocument()
    expect(await findByTitle(label)).toBeInTheDocument()
  })
})
