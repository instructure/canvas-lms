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
import {
  AssetProcessorsForAssignment,
  AssetProcessorsForAssignmentProps,
} from '../AssetProcessorsForAssignment'
import {ExistingAttachedAssetProcessor, AssetProcessorType} from '@canvas/lti/model/AssetProcessor'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {LtiLaunchDefinition} from '@canvas/select-content-dialog/jquery/select_content_dialog'
import {useAssetProcessorsToolsList} from '@canvas/lti-asset-processor/react/hooks/useAssetProcessorsToolsList'

vi.mock('@canvas/lti-asset-processor/react/hooks/useAssetProcessorsToolsList', () => ({
  useAssetProcessorsToolsList: vi.fn(),
}))

const queryClient = new QueryClient()

describe('AssetProcessorsForAssignment', () => {
  const initialAttachedProcessors: ExistingAttachedAssetProcessor[] = [
    {
      id: 1,
      title: 'Test Processor',
      text: 'This is a test processor',
      tool_id: 1,
      tool_name: 'Test Tool',
      tool_placement_label: 'Test Placement',
      icon_or_tool_icon_url: 'https://example.com/icon.png',
      iframe: {
        width: 800,
        height: 600,
      },
      window: {
        width: 800,
        height: 600,
      },
    },
    {
      id: 2,
      title: 'Another Processor',
      tool_id: 2,
      tool_name: 'Another Tool',
      icon_or_tool_icon_url: 'https://example.com/another-icon.png',
    },
  ]

  const toolWithAssetProcessorPlacement: LtiLaunchDefinition = {
    definition_type: 'ContextExternalTool',
    definition_id: '1',
    name: 'Test Tool',
    url: 'https://example.com/tool',
    description: 'This is a test tool',
    domain: 'https://example.com',
    placements: {
      ActivityAssetProcessor: {
        message_type: 'LtiDeepLinkingRequest',
        url: 'https://example.com/tool/launch',
        title: 'bar',
        selection_width: 1000,
        selection_height: 800,
      },
    },
  }

  const props = {
    courseId: 1,
    initialAttachedProcessors,
  }

  beforeEach(() => {
    vi.resetAllMocks()
  })

  const mockUseAssetProcessorsToolsList = (tools: LtiLaunchDefinition[]) => {
    ;(useAssetProcessorsToolsList as any).mockReturnValue({
      data: tools,
      isLoading: false,
      isError: false,
    })
  }

  const renderComponent = (overrides: Partial<AssetProcessorsForAssignmentProps> = {}) => {
    const propsToRender = {...props, ...overrides}
    return render(
      <QueryClientProvider client={queryClient}>
        <AssetProcessorsForAssignment secureParams={''} hideErrors={() => {}} {...propsToRender} />
      </QueryClientProvider>,
    )
  }

  it('renders the asset processors', () => {
    mockUseAssetProcessorsToolsList([])
    renderComponent()

    expect(screen.getByText('Document Processing App(s)')).toBeInTheDocument()
    expect(screen.getByTestId('asset_processors[0]')).toBeInTheDocument()
    expect(screen.getByText('Test Placement · Test Processor')).toBeInTheDocument()
    expect(screen.getByText('This is a test processor')).toBeInTheDocument()
    expect(screen.getByTestId('asset_processors[1]')).toBeInTheDocument()
    expect(screen.getByText('Another Tool · Another Processor')).toBeInTheDocument()
  })

  it('does not render the component when there are no available tools or processors', () => {
    mockUseAssetProcessorsToolsList([])
    const {container} = renderComponent({initialAttachedProcessors: []})
    expect(container).toBeEmptyDOMElement()
  })

  it('renders the component when where are no processors but tools are available', () => {
    mockUseAssetProcessorsToolsList([toolWithAssetProcessorPlacement])

    renderComponent({initialAttachedProcessors: []})
    expect(screen.getByText('Document Processing App(s)')).toBeInTheDocument()
    expect(screen.queryByTestId('asset_processors[0]')).not.toBeInTheDocument()
  })

  it('uses ActivityAssetProcessor type for querying tools', () => {
    const mockToolsList = vi.fn().mockReturnValue({
      data: [],
      isLoading: false,
      isError: false,
    })
    ;(useAssetProcessorsToolsList as any).mockImplementation(mockToolsList)

    renderComponent({initialAttachedProcessors: []})

    expect(mockToolsList).toHaveBeenCalledWith(1, 'ActivityAssetProcessor')
  })
})
