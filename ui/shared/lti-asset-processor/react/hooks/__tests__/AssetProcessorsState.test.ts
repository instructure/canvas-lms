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

import {renderHook, act} from '@testing-library/react-hooks'
import {useAssetProcessorsState, ContentItemType} from '../AssetProcessorsState'
import {
  mockExistingAttachedAssetProcessor,
  mockToolsForAssignment,
} from '../../__tests__/assetProcessorsTestHelpers'
import {AssetProcessorContentItem} from '@canvas/deep-linking/models/AssetProcessorContentItem'
import {ContentItem} from '@canvas/deep-linking/models/ContentItem'

// Mock the flash alert functions
vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
  showFlashError: vi.fn(() => () => {}),
}))

// Mock the confirm dialog
vi.mock('@canvas/instui-bindings/react/Confirm', () => ({
  confirmDanger: vi.fn(() => Promise.resolve(true)),
}))

describe('useAssetProcessorsState', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    useAssetProcessorsState.setState({
      attachedProcessors: [],
    })
  })

  const validContentItem: AssetProcessorContentItem = {
    type: 'ltiAssetProcessor',
    title: 'Test Processor',
    text: 'Test description',
    url: 'https://example.com/processor',
    icon: {
      url: 'https://example.com/icon.png',
      width: 32,
      height: 32,
    },
    custom: {
      key1: 'value1',
      key2: 'value2',
    },
  }

  describe('addAttachedProcessors', () => {
    it('should add valid asset processors from deep link response', () => {
      const {result} = renderHook(() => useAssetProcessorsState())

      act(() => {
        result.current.addAttachedProcessors({
          tool: mockToolsForAssignment[0],
          data: {content_items: [validContentItem]},
          type: 'ActivityAssetProcessor',
        })
      })

      expect(result.current.attachedProcessors).toHaveLength(1)
      const processor = result.current.attachedProcessors[0]

      expect(processor.title).toBe('Test Processor')
      expect(processor.text).toBe('Test description')
      expect(processor.toolName).toBe(mockToolsForAssignment[0].name)
      expect(processor.toolId).toBe(mockToolsForAssignment[0].definition_id)
      expect(processor.iconOrToolIconUrl).toBe('https://example.com/icon.png')
      expect(processor.dto).toEqual({
        new_content_item: expect.objectContaining({
          context_external_tool_id: mockToolsForAssignment[0].definition_id,
          title: 'Test Processor',
          text: 'Test description',
          url: 'https://example.com/processor',
          icon: {
            url: 'https://example.com/icon.png',
            width: 32,
            height: 32,
          },
          custom: {
            key1: 'value1',
            key2: 'value2',
          },
        }),
      })
    })

    it('should strip unrecognized fields from content items', () => {
      const {result} = renderHook(() => useAssetProcessorsState())

      // Content item with both valid and invalid fields
      const contentItemWithExtraFields = {
        ...validContentItem,
        // Invalid/unrecognized fields that should be stripped
        invalidField1: 'should be removed',
        someRandomProperty: {nested: 'object'},
        anotherBadField: 12345,
        maliciousScript: '<script>alert("xss")</script>',
        extraData: ['array', 'of', 'stuff'],
      }

      const deepLinkResponse = {content_items: [contentItemWithExtraFields]}

      act(() => {
        result.current.addAttachedProcessors({
          tool: mockToolsForAssignment[0],
          data: deepLinkResponse,
          type: 'ActivityAssetProcessor',
        })
      })

      expect(result.current.attachedProcessors).toHaveLength(1)
      const processor = result.current.attachedProcessors[0]

      // Check that valid fields are preserved
      expect(processor.title).toBe('Test Processor')
      expect(processor.text).toBe('Test description')

      // Check the DTO doesn't contain unrecognized fields
      const dto = processor.dto as {new_content_item: any}
      expect(dto.new_content_item).not.toHaveProperty('invalidField1')
      expect(dto.new_content_item).not.toHaveProperty('someRandomProperty')
      expect(dto.new_content_item).not.toHaveProperty('anotherBadField')
      expect(dto.new_content_item).not.toHaveProperty('maliciousScript')
      expect(dto.new_content_item).not.toHaveProperty('extraData')

      // Verify only expected fields are present
      const expectedFields = [
        'context_external_tool_id',
        'type',
        'title',
        'text',
        'url',
        'icon',
        'custom',
      ]
      const actualFields = Object.keys(dto.new_content_item)

      // All actual fields should be in expected fields
      actualFields.forEach(field => {
        expect(expectedFields).toContain(field)
      })
    })

    it('should handle content items with nested object fields having extra properties', () => {
      const {result} = renderHook(() => useAssetProcessorsState())

      const contentItemWithNestedExtras = {
        type: 'ltiAssetProcessor',
        title: 'Test Processor',
        icon: {
          url: 'https://example.com/icon.png',
          width: 32,
          height: 32,
          // These should be stripped from icon object
          extraIconField: 'remove me',
          badIconProperty: 999,
        },
        custom: {
          validKey: 'validValue',
          // These should be allowed in custom (it's a record of strings)
          anotherKey: 'anotherValue',
        },
        window: {
          width: 800,
          height: 600,
          targetName: '_blank',
          // These should be stripped from window object
          invalidWindowField: 'remove',
          badProperty: true,
        },
      } as const

      act(() => {
        result.current.addAttachedProcessors({
          tool: mockToolsForAssignment[0],
          data: {content_items: [contentItemWithNestedExtras]},
          type: 'ActivityAssetProcessor',
        })
      })

      expect(result.current.attachedProcessors).toHaveLength(1)
      const processor = result.current.attachedProcessors[0]
      const dto = processor.dto as {new_content_item: any}

      // Icon should only have valid fields
      expect(dto.new_content_item.icon).toEqual({
        url: 'https://example.com/icon.png',
        width: 32,
        height: 32,
      })
      expect(dto.new_content_item.icon).not.toHaveProperty('extraIconField')
      expect(dto.new_content_item.icon).not.toHaveProperty('badIconProperty')

      // Custom should preserve all string key-value pairs
      expect(dto.new_content_item.custom).toEqual({
        validKey: 'validValue',
        anotherKey: 'anotherValue',
      })

      // Window should only have valid fields
      expect(dto.new_content_item.window).toEqual({
        width: 800,
        height: 600,
        targetName: '_blank',
      })
      expect(dto.new_content_item.window).not.toHaveProperty('invalidWindowField')
      expect(dto.new_content_item.window).not.toHaveProperty('badProperty')
    })

    it('should handle multiple content items and filter only ltiAssetProcessor types', () => {
      const {result} = renderHook(() => useAssetProcessorsState())

      const mixedContentItems: ContentItem[] = [
        {
          type: 'ltiResourceLink', // Should be filtered out
          title: 'Resource Link',
          url: 'https://example.com/resource',
        },
        {
          type: 'ltiAssetProcessor',
          title: 'First Processor',
        },
        {
          type: 'ltiAssetProcessor',
          title: 'Second Processor',
          text: 'Description',
        },
      ]

      act(() => {
        result.current.addAttachedProcessors({
          tool: mockToolsForAssignment[0],
          data: {content_items: mixedContentItems},
          type: 'ActivityAssetProcessor',
        })
      })

      // Should only have the 2 ltiAssetProcessor items
      expect(result.current.attachedProcessors).toHaveLength(2)

      expect(result.current.attachedProcessors[0].title).toBe('First Processor')
      expect(result.current.attachedProcessors[1].title).toBe('Second Processor')
      expect(result.current.attachedProcessors[1].text).toBe('Description')

      // Verify unrecognized fields were stripped
      const firstDto = result.current.attachedProcessors[0].dto as {new_content_item: any}
      const secondDto = result.current.attachedProcessors[1].dto as {new_content_item: any}

      expect(firstDto.new_content_item).not.toHaveProperty('extraField')
      expect(secondDto.new_content_item).not.toHaveProperty('invalidData')
    })

    it('should throw an error on completely invalid items', () => {
      const {result} = renderHook(() => useAssetProcessorsState())

      const invalidContentItems = [
        {
          type: 'ltiAssetProcessor',
          title: 'Valid Processor',
          iframe: 123, // Invalid type, should be an object
        },
      ]

      let error: unknown = null
      try {
        result.current.addAttachedProcessors({
          tool: mockToolsForAssignment[0],
          data: {content_items: invalidContentItems as any},
          type: 'ActivityAssetProcessor',
        })
      } catch (e) {
        error = e
      }
      expect(error).toBeInstanceOf(Error)
      expect(error?.toString()).toContain('iframe')
    })

    it('should preserve all existing processors when adding new ones', () => {
      const {result} = renderHook(() => useAssetProcessorsState())

      // Add first processor
      const firstContentItem = {
        type: 'ltiAssetProcessor',
        title: 'First Processor',
      } as const
      act(() => {
        result.current.addAttachedProcessors({
          tool: mockToolsForAssignment[0],
          data: {content_items: [firstContentItem]},
          type: 'ActivityAssetProcessor',
        })
      })

      expect(result.current.attachedProcessors).toHaveLength(1)

      // Add second processor
      const secondContentItem = {
        type: 'ltiAssetProcessor',
        title: 'Second Processor',
        extraField: 'should be stripped',
      } as const

      act(() => {
        result.current.addAttachedProcessors({
          tool: mockToolsForAssignment[0],
          data: {content_items: [secondContentItem]},
          type: 'ActivityAssetProcessor',
        })
      })

      // Should now have both processors
      expect(result.current.attachedProcessors).toHaveLength(2)
      expect(result.current.attachedProcessors[0].title).toBe('First Processor')
      expect(result.current.attachedProcessors[1].title).toBe('Second Processor')

      // Verify field stripping still works
      const secondDto = result.current.attachedProcessors[1].dto as {new_content_item: any}
      expect(secondDto.new_content_item).not.toHaveProperty('extraField')
    })
  })

  describe('removeAttachedProcessor', () => {
    it.skip('should delete processor at specified index after confirmation', async () => {
      const {result} = renderHook(() => useAssetProcessorsState())

      // Add some processors first
      const contentItems: AssetProcessorContentItem[] = [
        {type: 'ltiAssetProcessor', title: 'Processor 1'},
        {type: 'ltiAssetProcessor', title: 'Processor 2'},
        {type: 'ltiAssetProcessor', title: 'Processor 3'},
      ]

      act(() => {
        result.current.addAttachedProcessors({
          tool: mockToolsForAssignment[0],
          data: {content_items: contentItems},
          type: 'ActivityAssetProcessor',
        })
      })

      expect(result.current.attachedProcessors).toHaveLength(3)

      // Delete the middle processor
      await act(async () => {
        await result.current.removeAttachedProcessor(1)
      })

      expect(result.current.attachedProcessors).toHaveLength(2)
      expect(result.current.attachedProcessors[0].title).toBe('Processor 1')
      expect(result.current.attachedProcessors[1].title).toBe('Processor 3')
    })
  })

  describe('setFromExistingAttachedProcessors', () => {
    it('should set processors from existing processor data', () => {
      const {result} = renderHook(() => useAssetProcessorsState())

      const existingProcessors = [mockExistingAttachedAssetProcessor]

      act(() => {
        result.current.setFromExistingAttachedProcessors(existingProcessors)
      })

      expect(result.current.attachedProcessors).toHaveLength(1)

      const first = result.current.attachedProcessors[0]
      expect(first.id).toBe(1)
      expect(first.title).toBe('ap title')
      expect(first.text).toBe('ap text')
      expect(first.toolName).toBe('tool name')
      expect(first.toolId).toBe('2')
      expect(first.toolPlacementLabel).toBe('tool label')
      expect(first.iconOrToolIconUrl).toBe('http://instructure.com/icon.png')
      expect(first.iframe).toEqual({width: 600, height: 500})
      expect(first.dto).toEqual({existing_id: 1})
    })

    describe('content item type filtering', () => {
      it('filters content items for LtiAssetProcessorContribution type', () => {
        const {result} = renderHook(() => useAssetProcessorsState())

        const assetProcessorItem: AssetProcessorContentItem = {
          type: 'ltiAssetProcessor',
          title: 'Asset Processor 1',
          url: 'https://example.com/processor1',
        }

        const assetProcessorContributionItem: AssetProcessorContentItem = {
          type: 'ltiAssetProcessorContribution',
          title: 'Asset Processor Contribution 1',
          url: 'https://example.com/processor-contribution1',
        }

        const contentItems = [assetProcessorItem, assetProcessorContributionItem]

        act(() => {
          result.current.addAttachedProcessors({
            tool: mockToolsForAssignment[0],
            data: {content_items: contentItems},
            type: 'ActivityAssetProcessorContribution',
          })
        })

        expect(result.current.attachedProcessors).toHaveLength(1)
        expect(result.current.attachedProcessors[0].title).toBe('Asset Processor Contribution 1')
      })

      it('filters content items for LtiAssetProcessor type', () => {
        const {result} = renderHook(() => useAssetProcessorsState())

        const assetProcessorItem: AssetProcessorContentItem = {
          type: 'ltiAssetProcessor',
          title: 'Asset Processor 1',
          url: 'https://example.com/processor1',
        }

        const assetProcessorContributionItem: AssetProcessorContentItem = {
          type: 'ltiAssetProcessorContribution',
          title: 'Asset Processor Contribution 1',
          url: 'https://example.com/processor-contribution1',
        }

        const contentItems = [assetProcessorItem, assetProcessorContributionItem]

        act(() => {
          result.current.addAttachedProcessors({
            tool: mockToolsForAssignment[0],
            data: {content_items: contentItems},
            type: 'ActivityAssetProcessor',
          })
        })

        expect(result.current.attachedProcessors).toHaveLength(1)
        expect(result.current.attachedProcessors[0].title).toBe('Asset Processor 1')
      })
    })
  })
})
