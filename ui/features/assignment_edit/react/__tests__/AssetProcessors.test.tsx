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
import {render, waitForElementToBeRemoved} from "@testing-library/react"
import {QueryClient} from "@tanstack/react-query"
import {MockedQueryClientProvider} from "@canvas/test-utils/query"
import {renderHook} from "@testing-library/react-hooks"
import {mockDeepLinkResponse, mockDoFetchApi, mockTools} from './assetProcessorsTestHelpers'
import {AssetProcessorsAddModalOnProcessorResponseFn, AssetProcessorsAddModalProps} from '../AssetProcessorsAddModal'
import {ExistingAttachedAssetProcessor, useAssetProcessorsState} from '../hooks/AssetProcessorsState'
import {AssetProcessors} from '../AssetProcessors'
import {useAssetProcessorsAddModalState} from '../hooks/AssetProcessorsAddModalState'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/external-tools/messages')

let onProcessorResponseCb: null | AssetProcessorsAddModalOnProcessorResponseFn = null

jest.mock('../AssetProcessorsAddModal', () => ({
  AssetProcessorsAddModal: ({onProcessorResponse}: AssetProcessorsAddModalProps) => {
    onProcessorResponseCb = onProcessorResponse
    return (<div>Mock-AssetProcessorsAddModal</div>)
  }
}))

describe('AssetProcessors', () => {
  const queryClient = new QueryClient()
  let state: ReturnType<typeof useAssetProcessorsState.getState>
  const initialAttachedProcessors: ExistingAttachedAssetProcessor[] = [
    {
      id: 1,
      context_external_tool_id: 2,
      context_external_tool_name: "tool name",
      title: "ap title",
      text: "ap text",
      icon: {url: "http://instructure.com/icon.png"}
    }
  ]


  beforeEach(() => {
    state = useAssetProcessorsState.getState()
    queryClient.setQueryData(['assetProcessors', 123], mockTools)
    const launchDefsUrl = '/api/v1/courses/123/lti_apps/launch_definitions'
    mockDoFetchApi(launchDefsUrl, doFetchApi as jest.Mock)
  })

  afterEach(() => {
    useAssetProcessorsState.setState(state)
  })

  function renderAssetProcessors() {
    return render(
      <MockedQueryClientProvider client={queryClient}>
        <AssetProcessors initialAttachedProcessors={initialAttachedProcessors} courseId={123} secureParams="my-secure-params" />
      </MockedQueryClientProvider>
    )
  }

  it('has an add button that launches the Add modal', () => {
    const {getByText} = renderAssetProcessors()
    let tag = renderHook(() => useAssetProcessorsAddModalState(s => s.state.tag)).result.current
    expect(tag).toBe("closed")
    const addButton = getByText('Add Document Processing App')
    addButton.click()
    tag = renderHook(() => useAssetProcessorsAddModalState(s => s.state.tag)).result.current
    expect(tag).toBe("toolList")
  })

  it('shows the initial attached processors', () => {
    const {getByText} = renderAssetProcessors()
    expect(getByText("tool name · ap title")).toBeInTheDocument()
  })

  it('adds attached processors sent by the modal', async () => {
    const {getByText} = renderAssetProcessors()
    onProcessorResponseCb!({ tool: mockTools[1], data: mockDeepLinkResponse })
    expect(getByText("t2 · Lti 1.3 Tool Title")).toBeInTheDocument()
  })

  it('removes attached processors when the delete menu item is clicked', async () => {
    const {queryByText, getByText} = renderAssetProcessors()
    onProcessorResponseCb!({ tool: mockTools[1], data: mockDeepLinkResponse })
    expect(getByText("t2 · Lti 1.3 Tool Title")).toBeInTheDocument()
    getByText("Actions for document processing app: t2 · Lti 1.3 Tool Title").click()
    getByText("Delete").click()
    expect(getByText("Confirm Delete")).toBeInTheDocument()
    getByText("Delete").click()
    if (queryByText("t2 · Lti 1.3 Tool Title")) {
      await waitForElementToBeRemoved(() => queryByText("t2 · Lti 1.3 Tool Title"))
    }
  })

  it('allows removing existing attached processors', async () => {
    const {queryByText, getByText} = renderAssetProcessors()
    expect(getByText("tool name · ap title")).toBeInTheDocument()
    getByText("Actions for document processing app: tool name · ap title").click()
    getByText("Delete").click()
    expect(getByText("Confirm Delete")).toBeInTheDocument()
    getByText("Delete").click()
    if (queryByText("tool name · ap title")) {
      await waitForElementToBeRemoved(() => queryByText("tool name · ap title"))
    }
  })
})
