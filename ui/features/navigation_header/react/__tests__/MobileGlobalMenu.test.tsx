// Copyright (C) 2024 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import fakeENV from '@canvas/test-utils/fakeENV'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {type MockedFunction} from 'vitest'
import MobileGlobalMenu from '../MobileGlobalMenu'
import {useSwitchExperience} from '../mutations/useSwitchExperience'
import {
  type ExternalTool,
  filterAndProcessTools,
  getExternalApps,
  type ProcessedTool,
} from '../utils'

vi.mock('../utils', () => ({
  getExternalApps: vi.fn(),
  filterAndProcessTools: vi.fn(),
}))

vi.mock('../mutations/useSwitchExperience', () => ({
  useSwitchExperience: vi.fn(),
}))

const mockedFilterAndProcessTools = filterAndProcessTools as MockedFunction<
  typeof filterAndProcessTools
>
const mockedGetExternalApps = getExternalApps as MockedFunction<typeof getExternalApps>
const mockedUseSwitchExperience = useSwitchExperience as MockedFunction<
  typeof useSwitchExperience
>

describe('MobileGlobalMenu', () => {
  beforeEach(() => {
    mockedUseSwitchExperience.mockReturnValue({mutate: vi.fn()} as any)
  })

  afterEach(() => {
    cleanup()
  })

  const setup = (
    processedTools: ProcessedTool[] = [],
    externalTools: ExternalTool[] = [],
    hasCareer: boolean = false,
  ) => {
    mockedFilterAndProcessTools.mockReturnValue(processedTools)
    mockedGetExternalApps.mockResolvedValue(externalTools)

    const queryClient = new QueryClient()

    queryClient.setQueryData(['experience_summary'], {
      available_apps: hasCareer ? ['career_learner'] : [],
    })
    return render(
      <MockedQueryClientProvider client={queryClient}>
        <MobileGlobalMenu onDismiss={() => {}} />
      </MockedQueryClientProvider>,
    )
  }

  it('renders tools list from processed tools', async () => {
    setup([
      {
        label: 'Tool 1',
        toolId: 'tool-1',
        toolImg: 'img/tool1.png',
        href: 'http://tool1.com',
        svgPath: null,
      },
      {
        label: 'Tool 2',
        toolId: 'tool-2',
        toolImg: null,
        href: 'http://tool2.com',
        svgPath: 'path-to-svg',
      },
    ] as ProcessedTool[])
    expect(await screen.findByText('Tool 1')).toBeInTheDocument()
    expect(await screen.findByText('Tool 2')).toBeInTheDocument()
    expect(screen.getByText('Tool 1').closest('a')).toHaveAttribute('href', 'http://tool1.com')
    expect(screen.getByText('Tool 2').closest('a')).toHaveAttribute('href', 'http://tool2.com')
    expect(screen.getByText('Tool 1').closest('a')?.querySelector('img')).toHaveAttribute(
      'src',
      'img/tool1.png',
    )
    const svg = screen.getByText('Tool 2').closest('a')?.querySelector('svg')
    expect(svg).toBeInTheDocument()
    expect(svg).toContainHTML('path-to-svg')
  })

  it('handles empty tools gracefully', async () => {
    const empty_tools: ProcessedTool[] = []
    mockedFilterAndProcessTools.mockReturnValue(empty_tools)
    setup()
    expect(await screen.queryByText('Tool 1')).not.toBeInTheDocument()
    expect(await screen.queryByText('Tool 2')).not.toBeInTheDocument()
  })

  it('should not render invalid tools', async () => {
    const valid_tool_id_derived_from_label = 'Valid Tool'
    const invalid_tool_id_derived_from_label = ''
    setup([
      {
        label: valid_tool_id_derived_from_label,
        toolId: 'tool-1',
        toolImg: 'img/tool1.png',
        href: 'http://tool1.com',
        svgPath: null,
      },
      {
        label: invalid_tool_id_derived_from_label,
        toolId: 'tool-2',
        toolImg: null,
        href: 'http://tool2.com',
        svgPath: 'path-to-svg',
      },
    ] as ProcessedTool[])
    expect(await screen.queryByText(valid_tool_id_derived_from_label)).toBeInTheDocument()
    expect(await screen.queryByText('Tool 2')).not.toBeInTheDocument()
  })

  it('uses customFields.url when present', async () => {
    mockedGetExternalApps.mockResolvedValueOnce([
      {
        href: 'https://custom.example.com',
        label: 'Custom URL Tool',
        svgPath: '',
        imgSrc: 'https://example.com/icon.png',
      },
    ] as ExternalTool[])
    setup([
      {
        label: 'Custom URL Tool',
        toolId: 'custom-url-tool',
        toolImg: 'https://example.com/icon.png',
        href: 'https://custom.example.com',
        svgPath: null,
      },
    ] as ProcessedTool[])
    expect(await screen.findByText('Custom URL Tool')).toBeInTheDocument()
    expect(screen.getByText('Custom URL Tool').closest('a')).toHaveAttribute(
      'href',
      'https://custom.example.com',
    )
  })

  it('uses globalNavigation.url when customFields.url is not present', async () => {
    mockedGetExternalApps.mockResolvedValueOnce([
      {
        href: 'https://global.example.com',
        label: 'Global URL Tool',
        svgPath: '',
        imgSrc: 'https://example.com/icon.png',
      },
    ] as ExternalTool[])
    setup([
      {
        label: 'Global URL Tool',
        toolId: 'global-url-tool',
        toolImg: 'https://example.com/icon.png',
        href: 'https://global.example.com',
        svgPath: null,
      },
    ] as ProcessedTool[])
    expect(await screen.findByText('Global URL Tool')).toBeInTheDocument()
    expect(screen.getByText('Global URL Tool').closest('a')).toHaveAttribute(
      'href',
      'https://global.example.com',
    )
  })

  it('sets href to null if both customFields.url and globalNavigation.url are not present', async () => {
    mockedGetExternalApps.mockResolvedValueOnce([
      {
        href: null,
        label: 'No URL Tool',
        svgPath: '',
        imgSrc: 'https://example.com/icon.png',
      },
    ] as ExternalTool[])
    setup([
      {
        label: 'No URL Tool',
        toolId: 'no-url-tool',
        toolImg: 'https://example.com/icon.png',
        href: null,
        svgPath: null,
      },
    ] as ProcessedTool[])
    expect(await screen.findByText('No URL Tool')).toBeInTheDocument()
    expect(screen.getByText('No URL Tool').closest('a')).toHaveAttribute('href', '#')
  })

  it('should handle tools with null image correctly and use fallback icon', async () => {
    const externalTools: ExternalTool[] = [
      {
        label: 'Tool with Null Image',
        imgSrc: null,
        href: 'http://tool-null-image.com',
        svgPath: null,
      },
    ]
    setup(
      [
        {
          label: 'Tool with Null Image',
          toolId: 'tool-null-image',
          toolImg: null,
          href: 'http://tool-null-image.com',
          svgPath: null,
        },
      ] as ProcessedTool[],
      externalTools,
    )
    expect(await screen.findByText('Tool with Null Image')).toBeInTheDocument()
    expect(screen.getByText('Tool with Null Image').closest('a')).toHaveAttribute(
      'href',
      'http://tool-null-image.com',
    )
    const fallbackIcon = screen.getByTestId('IconExternalLinkLine')
    expect(fallbackIcon).toBeInTheDocument()
  })

  it('renders Canvas Career link when career enrollment is available', async () => {
    setup([], [], true)
    expect(await screen.findByText('Canvas Career')).toBeInTheDocument()
  })

  it('calls switchExperience mutate when Canvas Career link clicked', async () => {
    const mutateMock = vi.fn()
    mockedUseSwitchExperience.mockReturnValue({mutate: mutateMock} as any)
    setup([], [], true)
    const link = await screen.findByText('Canvas Career')
    await userEvent.click(link)
    await waitFor(() => {
      expect(mutateMock).toHaveBeenCalled()
    })
  })
})
