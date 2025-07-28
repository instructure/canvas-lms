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

import {
  type ExternalTool,
  filterAndProcessTools,
  getExternalApps,
  type ProcessedTool,
} from '../utils'
import axios from '@canvas/axios'

jest.mock('@canvas/axios')
const mockedAxios = axios as jest.Mocked<typeof axios>

describe('utils.ts', () => {
  describe('getExternalApps', () => {
    beforeEach(() => {
      const default_mock_response: ExternalTool[] = []
      mockedAxios.get.mockResolvedValue({data: default_mock_response})
    })

    afterEach(() => {
      jest.resetAllMocks()
    })

    it('handles empty array response from the API', async () => {
      const result = await getExternalApps()
      expect(result).toEqual([])
    })

    it('processes valid tools correctly', async () => {
      mockedAxios.get.mockResolvedValueOnce({
        data: [
          {
            definition_id: 8300,
            definition_type: 'ContextExternalTool',
            placements: {
              global_navigation: {
                message_type: 'basic_lti_request',
                url: 'https://example.com',
                title: 'Local Studio',
                icon_svg_path_64: '',
                icon_url: 'https://example.com/icon.png',
                html_url: '/accounts/1/external_tools/8300?launch_type=global_navigation',
              },
            },
          },
          {
            definition_id: 8066,
            definition_type: 'ContextExternalTool',
            placements: {
              global_navigation: {
                message_type: 'basic_lti_request',
                url: 'https://example2.com',
                title: 'Lucid Integration',
                icon_svg_path_64: 'path/to/svg',
                icon_url: '',
                html_url: '/accounts/1/external_tools/8066?launch_type=global_navigation',
              },
            },
          },
        ],
      })

      const result = await getExternalApps()
      expect(result).toEqual([
        {
          href: '/accounts/1/external_tools/8300?launch_type=global_navigation',
          label: 'Local Studio',
          svgPath: null,
          imgSrc: 'https://example.com/icon.png',
        },
        {
          href: '/accounts/1/external_tools/8066?launch_type=global_navigation',
          label: 'Lucid Integration',
          svgPath: 'path/to/svg',
          imgSrc: null,
        },
      ])
    })

    it('ignores tools without required global_navigation data', async () => {
      mockedAxios.get.mockResolvedValueOnce({
        data: [{definition_id: '8300', definition_type: 'ContextExternalTool', placements: {}}],
      })
      const simulate_missing_global_navigation_data = {}
      mockedAxios.get.mockResolvedValueOnce({data: simulate_missing_global_navigation_data})
      const result = await getExternalApps()
      expect(result).toEqual([])
    })

    it('returns an empty array if API does not return an array', async () => {
      const not_an_array = {}
      mockedAxios.get.mockResolvedValue({data: not_an_array})
      const result = await getExternalApps()
      expect(result).toEqual([])
    })
  })

  describe('filterAndProcessTools', () => {
    it('should handle an empty input array', () => {
      const result = filterAndProcessTools([])
      expect(result).toEqual([])
    })

    it('should handle null or undefined inputs gracefully by returning an empty array', () => {
      expect(filterAndProcessTools(null)).toEqual([])
      expect(filterAndProcessTools(undefined)).toEqual([])
    })

    it('should correctly handle arrays with empty or incomplete tool objects', () => {
      const tools: ExternalTool[] = [
        {} as ExternalTool, // ignored
        {href: 'http://example.com', label: 'LocalStudio', svgPath: ''},
        {} as ExternalTool, // ignored
        {href: 'https://example.com', label: 'Studio', svgPath: ''},
        {href: 'https://example-dev.com', label: 'Dev', svgPath: ''},
        {href: 'https://example-studio.com', label: 'Studio', svgPath: ''},
        {href: 'https://example-iad.com', label: 'Studio IAD', svgPath: ''},
        {href: 'https://example-pdx.com', label: 'Studio PDX', svgPath: ''},
        {href: 'https://example-studio.com', label: 'Studio', svgPath: ''},
        {href: 'https://example-testing.com', label: 'Studio Testing', svgPath: ''},
        {} as ExternalTool, // ignored
      ]
      const expected: ProcessedTool[] = [
        {
          href: 'http://example.com',
          label: 'LocalStudio',
          svgPath: null,
          toolId: 'localstudio',
          toolImg: null,
        },
        {
          href: 'https://example.com',
          label: 'Studio',
          svgPath: null,
          toolId: 'studio',
          toolImg: null,
        },
        {
          href: 'https://example-dev.com',
          label: 'Dev',
          svgPath: null,
          toolId: 'dev',
          toolImg: null,
        },
        {
          href: 'https://example-studio.com',
          label: 'Studio',
          svgPath: null,
          toolId: 'studio',
          toolImg: null,
        },
        {
          href: 'https://example-iad.com',
          label: 'Studio IAD',
          svgPath: null,
          toolId: 'studio-iad',
          toolImg: null,
        },
        {
          href: 'https://example-pdx.com',
          label: 'Studio PDX',
          svgPath: null,
          toolId: 'studio-pdx',
          toolImg: null,
        },
        {
          href: 'https://example-studio.com',
          label: 'Studio',
          svgPath: null,
          toolId: 'studio',
          toolImg: null,
        },
        {
          href: 'https://example-testing.com',
          label: 'Studio Testing',
          svgPath: null,
          toolId: 'studio-testing',
          toolImg: null,
        },
      ]
      const result = filterAndProcessTools(tools)
      expect(result).toEqual(expected)
    })

    it('should filter out tools with invalid toolId (derived from label)', () => {
      const valid_tool_id_derived_from_label = 'Valid Tool'
      const invalid_tool_id_derived_from_label = ''
      const tools: ExternalTool[] = [
        {
          label: valid_tool_id_derived_from_label,
          imgSrc: 'img1.png',
          href: 'http://tool1.com',
          svgPath: 'path1',
        },
        {
          label: invalid_tool_id_derived_from_label,
          imgSrc: 'img2.png',
          href: 'http://tool2.com',
          svgPath: 'path2',
        },
      ]
      const expected: ProcessedTool[] = [
        {
          label: valid_tool_id_derived_from_label,
          toolId: 'valid-tool',
          toolImg: 'img1.png',
          href: 'http://tool1.com',
          svgPath: 'path1',
        },
      ]
      const result = filterAndProcessTools(tools)
      expect(result).toEqual(expected)
    })
  })
})
