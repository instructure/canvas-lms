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

import doFetchApi from '@canvas/do-fetch-api-effect'
import {render} from '@testing-library/react'
import {AssetProcessorsAddModal} from '../AssetProcessorsAddModal'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {act, renderHook} from '@testing-library/react-hooks'
import {mockDoFetchApi, mockTools as tools} from './assetProcessorsTestHelpers'
import {useAssetProcessorsAddModalState} from '../hooks/AssetProcessorsAddModalState'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/external-tools/messages')

describe('AssetProcessorsAddModal', () => {
  let mockOnProcessorResponse: jest.Mock
  const queryClient = new QueryClient()

  beforeEach(() => {
    mockOnProcessorResponse = jest.fn()

    queryClient.setQueryData(['assetProcessors', 123], tools)
    const launchDefsUrl = '/api/v1/courses/123/lti_apps/launch_definitions'
    mockDoFetchApi(launchDefsUrl, doFetchApi as jest.Mock)
  })

  afterEach(() => {
    queryClient.clear()
    jest.clearAllMocks()
  })

  function renderModal() {
    return render(
      <MockedQueryClientProvider client={queryClient}>
        <AssetProcessorsAddModal
          courseId={123}
          secureParams={'my-secure-params'}
          onProcessorResponse={mockOnProcessorResponse}
        />
      </MockedQueryClientProvider>,
    )
  }

  it('starts hidden/closed (with no dialog)', () => {
    const {queryByText} = renderModal()
    expect(queryByText('Configure settings for t1.')).toBeNull()
    expect(queryByText('Add a document processing app')).toBeNull()
    expect(
      queryByText('Choose the document processing app that you wish to add to this assignment.'),
    ).toBeNull()
  })
})
