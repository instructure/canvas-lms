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

import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'
import {render, waitForElementToBeRemoved} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {AssetProcessors} from '../AssetProcessors'
import {
  AssetProcessorsAddModalOnProcessorResponseFn,
  AssetProcessorsAddModalProps,
} from '../AssetProcessorsAddModal'
import {useAssetProcessorsAddModalState} from '../hooks/AssetProcessorsAddModalState'
import {useAssetProcessorsState} from '../hooks/AssetProcessorsState'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {mockDeepLinkResponse, mockDoFetchApi, mockTools} from './assetProcessorsTestHelpers'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/external-tools/messages')
jest.mock('@canvas/alerts/react/FlashAlert')

let onProcessorResponseCb: null | AssetProcessorsAddModalOnProcessorResponseFn = null

jest.mock('../AssetProcessorsAddModal', () => ({
  AssetProcessorsAddModal: ({onProcessorResponse}: AssetProcessorsAddModalProps) => {
    onProcessorResponseCb = onProcessorResponse
    return <div>Mock-AssetProcessorsAddModal</div>
  },
}))

const hideErrorsMocked = jest.fn()

describe('AssetProcessors', () => {
  const queryClient = new QueryClient()
  let oldWindowOpen: typeof window.open
  let state: ReturnType<typeof useAssetProcessorsState.getState>

  const initialAttachedProcessors = (): ExistingAttachedAssetProcessor[] => [
    {
      id: 1,
      tool_id: 2,
      tool_name: 'tool name',
      tool_placement_label: 'tool label',
      title: 'ap title',
      text: 'ap text',
      icon_or_tool_icon_url: 'http://instructure.com/icon.png',
      iframe: {
        width: 600,
        height: 500,
      },
    },
  ]

  const processorWithWindowSettings = (): ExistingAttachedAssetProcessor[] => [
    {
      id: 2,
      tool_id: 3,
      tool_name: 'window tool',
      title: 'window title',
      text: 'window text',
      icon_or_tool_icon_url: 'http://instructure.com/icon.png',
      window: {
        width: 800,
        height: 700,
      },
    },
  ]

  beforeEach(() => {
    state = useAssetProcessorsState.getState()
    queryClient.setQueryData(['assetProcessors', 123], mockTools)
    const launchDefsUrl = '/api/v1/courses/123/lti_apps/launch_definitions'
    mockDoFetchApi(launchDefsUrl, doFetchApi as jest.Mock)

    // Mock window.open for testing
    oldWindowOpen = window.open
    window.open = jest.fn()
  })

  afterEach(() => {
    useAssetProcessorsState.setState(state)
    window.open = oldWindowOpen
    jest.clearAllMocks()
  })

  function renderAssetProcessors(aps = initialAttachedProcessors()) {
    return render(
      <MockedQueryClientProvider client={queryClient}>
        <AssetProcessors
          initialAttachedProcessors={aps}
          courseId={123}
          secureParams="my-secure-params"
          hideErrors={hideErrorsMocked}
        />
      </MockedQueryClientProvider>,
    )
  }

  it('has an add button that launches the Add modal', () => {
    const {getByText} = renderAssetProcessors()
    let tag = renderHook(() => useAssetProcessorsAddModalState(s => s.state.tag)).result.current
    expect(tag).toBe('closed')
    const addButton = getByText('Add Document Processing App')
    addButton.click()
    tag = renderHook(() => useAssetProcessorsAddModalState(s => s.state.tag)).result.current
    expect(tag).toBe('toolList')
  })

  it('shows the initial attached processors', () => {
    const {getByText} = renderAssetProcessors()
    expect(getByText('tool label · ap title')).toBeInTheDocument()
  })

  it('adds attached processors sent by the modal', async () => {
    const {getByText} = renderAssetProcessors()
    onProcessorResponseCb!({tool: mockTools[1], data: mockDeepLinkResponse})
    expect(getByText('t2 · Lti 1.3 Tool Title')).toBeInTheDocument()
  })

  it('shows flash messages when the deep linking response contains "msg" or "errormsg"', () => {
    renderAssetProcessors()

    onProcessorResponseCb!({tool: mockTools[1], data: {...mockDeepLinkResponse, msg: 'hello'}})
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'Message from document processing app: hello',
    })

    const mockFlashErrorFn = jest.fn()
    ;(showFlashError as jest.Mock).mockImplementation(() => mockFlashErrorFn)
    onProcessorResponseCb!({tool: mockTools[1], data: {...mockDeepLinkResponse, errormsg: 'oopsy'}})
    expect(showFlashError).toHaveBeenCalledWith('Error from document processing app: oopsy')
  })

  it('shows a flash message when the deep linking response has no processors', () => {
    renderAssetProcessors()
    onProcessorResponseCb!({tool: mockTools[1], data: {...mockDeepLinkResponse, content_items: []}})

    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'The document processing app returned with no processors to attach.',
    })
  })

  it('removes attached processors when the delete menu item is clicked', async () => {
    const {queryByText, getByText} = renderAssetProcessors()
    onProcessorResponseCb!({tool: mockTools[1], data: mockDeepLinkResponse})
    expect(getByText('t2 · Lti 1.3 Tool Title')).toBeInTheDocument()
    getByText('Actions for document processing app: t2 · Lti 1.3 Tool Title').click()
    getByText('Delete').click()
    expect(getByText('Confirm Delete')).toBeInTheDocument()
    getByText('Delete').click()
    if (queryByText('t2 · Lti 1.3 Tool Title')) {
      await waitForElementToBeRemoved(() => queryByText('t2 · Lti 1.3 Tool Title'))
    }
    expect(hideErrorsMocked).toHaveBeenCalled()
  })

  it('allows removing existing attached processors', async () => {
    const {queryByText, getByText} = renderAssetProcessors()
    expect(getByText('tool label · ap title')).toBeInTheDocument()
    getByText('Actions for document processing app: tool label · ap title').click()
    getByText('Delete').click()
    expect(getByText('Confirm Delete')).toBeInTheDocument()
    getByText('Delete').click()
    if (queryByText('tool label · ap title')) {
      await waitForElementToBeRemoved(() => queryByText('tool label · ap title'))
    }
  })

  it('allows modifying existing attached processors', async () => {
    const {getByText} = renderAssetProcessors()
    expect(getByText('tool label · ap title')).toBeInTheDocument()
    getByText('Actions for document processing app: tool label · ap title').click()
    getByText('Modify').click()
    expect(getByText('Modify settings for tool label · ap title')).toBeInTheDocument()

    const iframe = document.querySelector('iframe')
    expect(iframe).toBeInTheDocument()
    expect(iframe?.src).toContain('/asset_processors/1/launch')

    expect(iframe).toHaveStyle(`width: 600px`)
    expect(iframe).toHaveStyle(`height: 500px`)
  })

  it('does not allow modifying not saved attached processors', async () => {
    const {getByText, queryByText} = renderAssetProcessors()
    onProcessorResponseCb!({tool: mockTools[1], data: mockDeepLinkResponse})
    expect(getByText('t2 · Lti 1.3 Tool Title')).toBeInTheDocument()
    getByText('Actions for document processing app: t2 · Lti 1.3 Tool Title').click()
    expect(getByText('Delete')).toBeInTheDocument()
    expect(queryByText('Modify')).not.toBeInTheDocument()
  })

  it('displays the external link icon when windowSettings are provided', () => {
    const {getByText, getByTestId} = renderAssetProcessors(processorWithWindowSettings())
    expect(getByText('window tool · window title')).toBeInTheDocument()

    // Open the menu to show the Modify option
    getByText('Actions for document processing app: window tool · window title').click()
    // Check that the external link icon is displayed
    expect(getByTestId('external-link-icon')).toBeInTheDocument()
  })

  it('opens a new window with correct parameters when window settings are defined', () => {
    const {getByText} = renderAssetProcessors(processorWithWindowSettings())
    expect(getByText('window tool · window title')).toBeInTheDocument()

    // Open the menu to show the Modify option
    getByText('Actions for document processing app: window tool · window title').click()
    getByText('Modify').click()

    expect(window.open).toHaveBeenCalledWith(
      '/asset_processors/2/launch',
      '_blank',
      'width=800,height=700',
    )

    // Modal should not be opened
    expect(document.querySelector('iframe')).not.toBeInTheDocument()
  })

  it('uses targetName from windowSettings if provided', () => {
    const processor = processorWithWindowSettings()[0]
    const processorWithTargetName = {
      ...processor,
      window: {
        ...processor.window,
        targetName: 'custom-window-name',
      },
    }

    const {getByText} = renderAssetProcessors([processorWithTargetName])
    getByText('Actions for document processing app: window tool · window title').click()
    getByText('Modify').click()

    expect(window.open).toHaveBeenCalledWith(
      '/asset_processors/2/launch',
      'custom-window-name',
      'width=800,height=700',
    )
  })

  it('uses windowFeatures from windowSettings if provided', () => {
    const processor = processorWithWindowSettings()[0]
    const processorWithCustomFeatures = {
      ...processor,
      window: {
        ...processor.window,
        windowFeatures: 'width=1000,height=900,toolbar=yes',
      },
    }

    const {getByText} = renderAssetProcessors([processorWithCustomFeatures])
    getByText('Actions for document processing app: window tool · window title').click()
    getByText('Modify').click()

    expect(window.open).toHaveBeenCalledWith(
      '/asset_processors/2/launch',
      '_blank',
      'width=1000,height=900,toolbar=yes',
    )
  })

  it('has an element with asset_processors_errors class where backend errors are shown', () => {
    const {getByTestId} = renderAssetProcessors()
    const el = getByTestId('asset-processor-errors')
    expect(el).toBeInTheDocument()
    expect(el.id).toBe('asset_processors_errors')
  })
})
