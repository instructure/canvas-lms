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
import {render, screen} from '@testing-library/react'
import {AssetProcessorsForDiscussion} from '../AssetProcessorsForDiscussion'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {LtiLaunchDefinition} from '@canvas/select-content-dialog/jquery/select_content_dialog'
import {useAssetProcessorsToolsList} from '@canvas/lti-asset-processor/react/hooks/useAssetProcessorsToolsList'
import {
  AssetProcessorsState,
  useAssetProcessorsState,
} from '@canvas/lti-asset-processor/react/hooks/AssetProcessorsState'

vi.mock('@canvas/lti-asset-processor/react/hooks/useAssetProcessorsToolsList', () => ({
  useAssetProcessorsToolsList: vi.fn(),
}))

const queryClient = new QueryClient()

describe('AssetProcessorsForDiscussion', () => {
  const initialAttachedProcessors: ExistingAttachedAssetProcessor[] = [
    {
      id: 2,
      tool_id: 2,
      title: 'Another Processor',
      tool_name: 'Another Tool',
      icon_or_tool_icon_url: 'https://example.com/another-icon.png',
    },
  ]

  beforeEach(() => {
    vi.resetAllMocks()
  })

  const mockUseAssetProcessorsToolsList = (tools: LtiLaunchDefinition[]) => {
    ;(useAssetProcessorsToolsList as ReturnType<typeof vi.fn>).mockReturnValue({
      data: tools,
      isLoading: false,
      isError: false,
    })
  }

  const renderComponent = () => {
    return render(
      <QueryClientProvider client={queryClient}>
        <AssetProcessorsForDiscussion courseId={1} secureParams={''} hideErrors={() => {}} />
      </QueryClientProvider>,
    )
  }

  let state: AssetProcessorsState

  beforeEach(() => {
    state = useAssetProcessorsState.getState()
  })

  afterEach(() => {
    useAssetProcessorsState.setState(state)
  })

  it('renders the asset processors', () => {
    useAssetProcessorsState.getState().setFromExistingAttachedProcessors(initialAttachedProcessors)
    mockUseAssetProcessorsToolsList([])
    renderComponent()

    expect(screen.getByText('Document Processing App(s)')).toBeInTheDocument()
    expect(screen.getByText('Another Tool · Another Processor')).toBeInTheDocument()
  })

  it('does not render the component when there are no available tools or processors', () => {
    useAssetProcessorsState.getState().setFromExistingAttachedProcessors([])
    mockUseAssetProcessorsToolsList([])
    const {container} = renderComponent()
    expect(container).toBeEmptyDOMElement()
  })

  it('renders the component when where are no processors but tools are available', () => {
    const tool: LtiLaunchDefinition = {
      definition_type: 'ContextExternalTool',
      definition_id: '1',
      name: 'Test Tool',
      url: 'https://example.com/tool',
      description: 'This is a test tool',
      domain: 'https://example.com',
      placements: {
        ActivityAssetProcessorContribution: {
          message_type: 'LtiDeepLinkingRequest',
          url: 'https://example.com/tool/launch',
          title: 'bar',
          selection_width: 0,
          selection_height: 0,
        },
      },
    }

    useAssetProcessorsState.getState().setFromExistingAttachedProcessors([])
    mockUseAssetProcessorsToolsList([tool])

    renderComponent()
    expect(screen.getByText('Document Processing App(s)')).toBeInTheDocument()
    expect(screen.queryByTestId('asset_processors[0]')).not.toBeInTheDocument()
  })
})
