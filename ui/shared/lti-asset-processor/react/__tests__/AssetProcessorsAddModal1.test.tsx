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

import {render} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {AssetProcessorsAddModal} from '../AssetProcessorsAddModal'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {mockToolsForAssignment as tools} from './assetProcessorsTestHelpers'
import {AssetProcessorType} from '@canvas/lti/model/AssetProcessor'

vi.mock('@canvas/external-tools/messages')

const server = setupServer(
  http.get('/api/v1/courses/:courseId/lti_apps/launch_definitions', ({request}) => {
    const url = new URL(request.url)
    const placements = url.searchParams.get('placements[]')
    return HttpResponse.json(placements === 'ActivityAssetProcessor' ? tools : [])
  }),
)

describe('AssetProcessorsAddModal', () => {
  let mockOnProcessorResponse: any
  const queryClient = new QueryClient()

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    mockOnProcessorResponse = vi.fn()
    queryClient.setQueryData(['assetProcessors', 123], tools)
  })

  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
    vi.clearAllMocks()
  })

  function renderModal() {
    return render(
      <MockedQueryClientProvider client={queryClient}>
        <AssetProcessorsAddModal
          courseId={123}
          secureParams={'my-secure-params'}
          onProcessorResponse={mockOnProcessorResponse}
          type="ActivityAssetProcessorContribution"
        />
      </MockedQueryClientProvider>,
    )
  }

  it('starts hidden/closed (with no dialog)', () => {
    const {queryByText} = renderModal()
    expect(queryByText('Add A Document Processing App')).toBeNull()
    expect(
      queryByText('Choose the document processing app that you wish to add to this assignment.'),
    ).toBeNull()
  })
})
