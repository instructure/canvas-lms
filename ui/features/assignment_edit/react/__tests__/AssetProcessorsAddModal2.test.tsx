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
import {render, waitFor} from '@testing-library/react'
import {AssetProcessorsAddModal} from '../AssetProcessorsAddModal'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {act, renderHook} from '@testing-library/react-hooks'
import {handleExternalContentMessages} from '@canvas/external-tools/messages'
import {
  mockDeepLinkResponse,
  mockInvalidDeepLinkResponse,
  mockDoFetchApi,
  mockTools as tools,
} from './assetProcessorsTestHelpers'
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

  it('is opened by calling the showToolList function in the useAssetProcessorsAddModalState hook', async () => {
    const {result} = renderHook(() => useAssetProcessorsAddModalState())

    act(() => {
      result.current.actions.close()
    })

    expect(result.current.state.tag).toBe('closed')

    act(() => {
      result.current.actions.showToolList()
    })

    expect(result.current.state.tag).toBe('toolList')
  })

  it('launches the tool when the AssetProcessorsCard is clicked', async () => {
    const toolWithId22 = tools.find(tool => tool.definition_id === '22')
    expect(toolWithId22).not.toBeUndefined()

    const {getByText, getByTitle, queryAllByTestId} = renderModal()
    const open = renderHook(() => useAssetProcessorsAddModalState(s => s.actions)).result.current
      .showToolList
    act(() => open())

    await waitFor(
      () => {
        expect(getByText('Add a document processing app')).toBeInTheDocument()

        const cards = queryAllByTestId('asset-processor-card')
        expect(cards.length).toBeGreaterThan(0)

        const foundCard = cards.find(card => card.textContent?.includes(toolWithId22!.name))
        expect(foundCard).toBeDefined()
        return foundCard
      },
      {timeout: 3000},
    ).then(toolCard => {
      act(() => toolCard!.click())
    })

    const iframe = await waitFor(() => getByTitle('Configure new document processing app'))
    expect(iframe).toHaveAttribute(
      'src',
      '/courses/123/external_tools/22/resource_selection?display=borderless&launch_type=ActivityAssetProcessor&secure_params=my-secure-params',
    )
    expect(iframe.style.width).toBe('600px')
    expect(iframe.style.height).toBe('500px')
  })

  describe('when valid deep linking response is received from the launch', () => {
    it('closes the modal and send calls the onProcessorResponse callback with the content items', async () => {
      const mockOnProcessorResponse = jest.fn()

      const validToolId = '22'
      const validTool = tools.find(tool => tool.definition_id === validToolId)
      expect(validTool).not.toBeUndefined()

      const validResponse = {...mockDeepLinkResponse}
      expect(validResponse.tool_id).toBe(validToolId)

      const mockHECM = handleExternalContentMessages as jest.Mock
      mockHECM.mockImplementation(({onDeepLinkingResponse}) => {
        setTimeout(() => onDeepLinkingResponse(validResponse), 0)
        return () => {}
      })

      render(
        <MockedQueryClientProvider client={queryClient}>
          <AssetProcessorsAddModal
            courseId={123}
            secureParams={'my-secure-params'}
            onProcessorResponse={mockOnProcessorResponse}
          />
        </MockedQueryClientProvider>,
      )

      const {result} = renderHook(() => useAssetProcessorsAddModalState())

      act(() => {
        result.current.actions.launchTool(validTool!)
      })

      await waitFor(() => {
        expect(mockOnProcessorResponse).toHaveBeenCalledWith({
          tool: validTool,
          data: validResponse,
        })
      })
    })
  })

  describe('when invalid deep linking response is received from the launch', () => {
    it('renders error message', async () => {
      const mockOnProcessorResponse = jest.fn()

      render(
        <MockedQueryClientProvider client={queryClient}>
          <AssetProcessorsAddModal
            courseId={123}
            secureParams={'my-secure-params'}
            onProcessorResponse={mockOnProcessorResponse}
          />
        </MockedQueryClientProvider>,
      )

      const matchingTool = tools.find(
        tool => tool.definition_id === mockInvalidDeepLinkResponse.tool_id,
      )
      expect(matchingTool).not.toBeUndefined()

      const mockHECM = handleExternalContentMessages as jest.Mock
      mockHECM.mockImplementation(({onDeepLinkingResponse}) => {
        setTimeout(() => onDeepLinkingResponse(mockInvalidDeepLinkResponse), 0)
        return () => {}
      })

      const {result} = renderHook(() => useAssetProcessorsAddModalState())

      act(() => {
        result.current.actions.launchTool(matchingTool!)
      })

      await waitFor(() => {
        expect(mockOnProcessorResponse).toHaveBeenCalledWith({
          tool: matchingTool,
          data: mockInvalidDeepLinkResponse,
        })
      })
    })
  })

  it('closes the modal when tool sends lti.close message', async () => {
    const {result} = renderHook(() => useAssetProcessorsAddModalState())

    act(() => {
      result.current.actions.close()
    })

    expect(result.current.state.tag).toBe('closed')

    act(() => {
      result.current.actions.showToolList()
    })

    expect(result.current.state.tag).toBe('toolList')

    act(() => {
      result.current.actions.launchTool(tools[0])
    })

    expect(result.current.state.tag).toBe('toolLaunch')
    expect('tool' in result.current.state && result.current.state.tool).toBe(tools[0])

    act(() => {
      result.current.actions.close()
    })

    expect(result.current.state.tag).toBe('closed')
  })
})
