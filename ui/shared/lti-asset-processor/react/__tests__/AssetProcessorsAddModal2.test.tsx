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
import doFetchApi from '@canvas/do-fetch-api-effect'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {AssetProcessorsAddModal} from '../AssetProcessorsAddModal'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {act, renderHook} from '@testing-library/react-hooks'
import {handleExternalContentMessages} from '@canvas/external-tools/messages'
import {
  mockDeepLinkResponse,
  mockInvalidDeepLinkResponse,
  mockDoFetchApi,
  mockToolsForAssignment as assignmentTools,
  mockToolsForDiscussions as discussionTools,
  mockContributionDeepLinkResponse,
} from './assetProcessorsTestHelpers'
import {useAssetProcessorsAddModalState} from '../hooks/AssetProcessorsAddModalState'
import {useAssetProcessorsToolsList} from '../hooks/useAssetProcessorsToolsList'
import {monitorLtiMessages} from '@canvas/lti/jquery/messages'
import {AssetProcessorType} from '@canvas/lti/model/AssetProcessor'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/external-tools/messages')

describe('AssetProcessorsAddModal', () => {
  let mockOnProcessorResponse: jest.Mock
  const queryClient = new QueryClient()
  let mockedDoFetchApi: jest.Mock

  beforeEach(() => {
    mockOnProcessorResponse = jest.fn()
    const launchDefsUrl = '/api/v1/courses/123/lti_apps/launch_definitions'
    mockedDoFetchApi = mockDoFetchApi(launchDefsUrl, doFetchApi as jest.Mock)
  })

  afterEach(() => {
    queryClient.clear()
    jest.clearAllMocks()
  })

  function renderModal(type: AssetProcessorType) {
    return render(
      <MockedQueryClientProvider client={queryClient}>
        <AssetProcessorsAddModal
          courseId={123}
          secureParams={'my-secure-params'}
          onProcessorResponse={mockOnProcessorResponse}
          type={type}
        />
      </MockedQueryClientProvider>,
    )
  }

  function toolsForType(type: AssetProcessorType) {
    return type === 'ActivityAssetProcessor' ? assignmentTools : discussionTools
  }

  describe('Modal state management', () => {
    it('opens and closes the modal correctly', async () => {
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
  })

  describe.each([
    {
      type: 'ActivityAssetProcessor' as AssetProcessorType,
      tool_id: '22',
      mockResponse: mockDeepLinkResponse,
    },
    {
      type: 'ActivityAssetProcessorContribution' as AssetProcessorType,
      tool_id: '22',
      mockResponse: mockContributionDeepLinkResponse,
    },
  ])('with type $type', ({type, tool_id, mockResponse}) => {
    const tool = toolsForType(type).find(tool => tool.definition_id === tool_id)

    it(`launches the tool with correct launch_type with correct dimensions`, async () => {
      const {getByText, getByTitle, queryAllByTestId} = renderModal(type)
      const open = renderHook(() => useAssetProcessorsAddModalState(s => s.actions)).result.current
        .showToolList
      act(() => open())

      await waitFor(
        () => {
          expect(getByText('Add A Document Processing App')).toBeInTheDocument()

          const cards = queryAllByTestId('asset-processor-card')
          expect(cards).toHaveLength(4)
          const foundCard = cards.find(card => card.textContent?.includes(tool!.name))
          expect(foundCard).toBeDefined()
          return foundCard
        },
        {timeout: 3000},
      ).then(toolCard => {
        act(() => toolCard!.click())
      })

      expect(mockedDoFetchApi).toHaveBeenCalledWith({
        path: '/api/v1/courses/123/lti_apps/launch_definitions',
        params: {'placements[]': type},
      })

      const iframe = await waitFor(() => getByTitle('Configure new document processing app'))
      expect(iframe).toHaveAttribute(
        'src',
        `/courses/123/external_tools/22/resource_selection?display=borderless&launch_type=${type}&secure_params=my-secure-params`,
      )
      const {selection_width, selection_height} = tool!.placements[type]!
      expect(iframe.style.width).toBe(selection_width + 'px')
      expect(iframe.style.height).toBe(selection_height + 'px')
    })

    it(`handles valid deep linking response for ${type}`, async () => {
      const mockOnProcessorResponse = jest.fn()

      const validResponse = {...mockResponse}
      expect(validResponse.tool_id).toBe(tool_id)

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
            type={type}
          />
        </MockedQueryClientProvider>,
      )

      const {result} = renderHook(() => useAssetProcessorsAddModalState())

      act(() => {
        result.current.actions.launchTool(tool!)
      })

      await waitFor(() => {
        expect(mockOnProcessorResponse).toHaveBeenCalledWith({
          tool: tool,
          data: validResponse,
        })
      })
    })

    it(`handles invalid deep linking response for ${type}`, async () => {
      const mockOnProcessorResponse = jest.fn()
      const matchingTool = toolsForType(type).find(
        tool => tool.definition_id === mockInvalidDeepLinkResponse.tool_id,
      )
      expect(matchingTool).not.toBeUndefined()

      const mockHECM = handleExternalContentMessages as jest.Mock
      mockHECM.mockImplementation(({onDeepLinkingResponse}) => {
        setTimeout(() => onDeepLinkingResponse(mockInvalidDeepLinkResponse), 0)
        return () => {}
      })

      render(
        <MockedQueryClientProvider client={queryClient}>
          <AssetProcessorsAddModal
            courseId={123}
            secureParams={'my-secure-params'}
            onProcessorResponse={mockOnProcessorResponse}
            type={type}
          />
        </MockedQueryClientProvider>,
      )

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
      result.current.actions.launchTool(assignmentTools[0])
    })

    expect(result.current.state.tag).toBe('toolLaunch')
    expect('tool' in result.current.state && result.current.state.tool).toBe(assignmentTools[0])

    const {getByTitle} = renderModal('ActivityAssetProcessor')
    const iframe = (await waitFor(() =>
      getByTitle('Configure new document processing app'),
    )) as HTMLIFrameElement
    const source = iframe.contentWindow as Window
    // If we don't overwrite postMessage we get some strange internal error in jsdom's postMessage
    jest.spyOn(source, 'postMessage').mockImplementation(() => {})

    monitorLtiMessages()

    act(() => {
      fireEvent(
        window,
        new MessageEvent('message', {
          data: {subject: 'lti.close'},
          origin: window.location.origin,
          source: iframe.contentWindow,
        }),
      )
    })

    await waitFor(() => {
      expect(result.current.state.tag).toBe('closed')
    })
  })
})
