/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen, cleanup} from '@testing-library/react'
import CustomForbiddenWordsSection from '../CustomForbiddenWordsSection'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

vi.mock('../apiClient')

const server = setupServer(
  http.get('/api/v1/accounts/:accountId/settings', () => {
    return HttpResponse.json({
      password_policy: {
        common_passwords_attachment_id: null,
      },
    })
  }),
  // Handler for file info requests (used when checking current attachment)
  http.get('/api/v1/files/:fileId', () => {
    return HttpResponse.json({
      id: 123,
      display_name: 'forbidden_words.txt',
    })
  }),
)

describe('CustomForbiddenWordsSection Component', () => {
  beforeAll(() => {
    server.listen()
    if (!window.ENV) {
      // @ts-expect-error
      window.ENV = {}
    }
    window.ENV.DOMAIN_ROOT_ACCOUNT_ID = '1'
  })

  afterAll(() => {
    server.close()
    // @ts-expect-error
    delete window.ENV.DOMAIN_ROOT_ACCOUNT_ID
  })

  afterEach(() => {
    server.resetHandlers()
    cleanup()
  })

  describe('when no file is uploaded', () => {

    it('shows “Upload” button but not “Current Custom List”', async () => {
      render(
        // @ts-expect-error
        <CustomForbiddenWordsSection
          setNewlyUploadedAttachmentId={() => {}}
          onCustomForbiddenWordsEnabledChange={() => {}}
          currentAttachmentId={123}
          passwordPolicyHashExists={true}
        />,
      )
      const uploadButton = await screen.findByTestId('uploadButton')
      expect(uploadButton).toBeInTheDocument()
      expect(uploadButton).toBeDisabled()
      expect(screen.queryByText('Current Custom List')).not.toBeInTheDocument()
    })
  })
})
