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
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'

jest.mock('@canvas/do-fetch-api-effect/apiRequest')
jest.mock('../apiClient')

const mockedExecuteApiRequest = executeApiRequest as jest.MockedFunction<typeof executeApiRequest>

describe('CustomForbiddenWordsSection Component', () => {
  beforeAll(() => {
    if (!window.ENV) {
      // @ts-expect-error
      window.ENV = {}
    }
    window.ENV.DOMAIN_ROOT_ACCOUNT_ID = '1'
  })

  afterAll(() => {
    // @ts-expect-error
    delete window.ENV.DOMAIN_ROOT_ACCOUNT_ID
  })

  afterEach(() => {
    jest.clearAllMocks()
    cleanup()
  })

  beforeEach(() => {
    mockedExecuteApiRequest.mockResolvedValue({
      status: 200,
      data: {
        password_policy: {
          common_passwords_attachment_id: null,
        },
      },
    })
  })

  describe('when no file is uploaded', () => {
    beforeEach(() => {
      mockedExecuteApiRequest.mockResolvedValue({
        status: 200,
        data: {
          password_policy: {
            common_passwords_attachment_id: null,
          },
        },
      })
    })

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
