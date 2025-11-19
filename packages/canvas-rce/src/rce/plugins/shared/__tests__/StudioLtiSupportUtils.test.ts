/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {
  displayStyleFrom,
  isStudioEmbeddedMedia,
  parseStudioOptions,
  studioAttributesFrom,
  StudioContentItemCustomJson,
  StudioMediaOptionsAttributes,
  handleBeforeObjectSelected,
  findStudioLtiIframeFromSelection,
  updateStudioIframeDimensions,
  isValidEmbedType,
  isValidDimension,
  isValidResizable,
} from '../StudioLtiSupportUtils'
import {EditorEvent, Events} from 'tinymce'
import {createDeepMockProxy} from '../../../../util/__tests__/deepMockProxy'

import * as iframeUtils from '../iframeUtils'

describe('studioAttributesFrom', () => {
  it('uses the default values for missing attributes', () => {
    const customJson: StudioContentItemCustomJson = {source: 'studio'}
    const ret = studioAttributesFrom(customJson)

    expect(ret['data-studio-convertible-to-link']).toBe(true)
    expect(ret['data-studio-resizable']).toBe(false)
    expect(ret['data-studio-tray-enabled']).toBe(false)
  })

  it('parses the correct attribute values when they are passed', () => {
    const ret1 = studioAttributesFrom({
      source: 'studio',
      enableMediaOptions: true,
      resizable: true,
    })
    expect(ret1['data-studio-convertible-to-link']).toBe(true)
    expect(ret1['data-studio-resizable']).toBe(true)
    expect(ret1['data-studio-tray-enabled']).toBe(true)

    const ret2 = studioAttributesFrom({
      source: 'studio',
      enableMediaOptions: false,
      resizable: false,
    })

    expect(ret2['data-studio-convertible-to-link']).toBe(true)
    expect(ret2['data-studio-resizable']).toBe(false)
    expect(ret2['data-studio-tray-enabled']).toBe(false)
  })
})

describe('displayStyleFrom', () => {
  it('returns the empty string if studioAttributes is null', () => {
    expect(displayStyleFrom(null)).toEqual('')
  })

  it('returns inline-block if data-studio-resizable is true', () => {
    const studioAttributes: StudioMediaOptionsAttributes = {
      'data-studio-convertible-to-link': true,
      'data-studio-resizable': true,
      'data-studio-tray-enabled': false,
    }
    expect(displayStyleFrom(studioAttributes)).toEqual('inline-block')
  })

  it('returns inline-block if data-studio-tray-enabled is true', () => {
    const studioAttributes: StudioMediaOptionsAttributes = {
      'data-studio-convertible-to-link': true,
      'data-studio-resizable': false,
      'data-studio-tray-enabled': true,
    }
    expect(displayStyleFrom(studioAttributes)).toEqual('inline-block')
  })
})

describe('isStudioEmbeddedMedia', () => {
  it('returns false if there is no parent element', () => {
    const element = document.createElement('iframe')
    expect(isStudioEmbeddedMedia(element)).toEqual(false)
  })

  it('returns false if the iframe is not the first child', () => {
    const element = document.createElement('span')
    element.innerHTML = '<span/><iframe/>'
    expect(isStudioEmbeddedMedia(element)).toEqual(false)
  })

  it('returns false if data-studio-tray-enabled is false', () => {
    const element = document.createElement('span')
    element.innerHTML = '<iframe/>'
    element.setAttribute('data-mce-p-data-studio-tray-enabled', 'false')
    expect(isStudioEmbeddedMedia(element)).toEqual(false)
  })

  it('returns true if data-studio-tray-enabled is true', () => {
    const element = document.createElement('span')
    element.innerHTML = '<iframe/>'
    element.setAttribute('data-mce-p-data-studio-tray-enabled', 'true')
    expect(isStudioEmbeddedMedia(element)).toEqual(true)
  })
})

describe('parseStudioOptions', () => {
  it('returns falses for null', () => {
    expect(parseStudioOptions(null)).toEqual({
      resizable: false,
      convertibleToLink: false,
    })
  })

  it('returns falses for missing studio attributes', () => {
    const element = document.createElement('span')
    expect(parseStudioOptions(element)).toEqual({
      resizable: false,
      convertibleToLink: false,
    })
  })

  it('parses correct values for attributes 1', () => {
    const element = document.createElement('span')
    element.setAttribute('data-mce-p-data-studio-resizable', 'false')
    element.setAttribute('data-mce-p-data-studio-convertible-to-link', 'false')
    expect(parseStudioOptions(element)).toEqual({
      resizable: false,
      convertibleToLink: false,
    })
  })

  it('parses correct values for attributes 2', () => {
    const element = document.createElement('span')
    element.setAttribute('data-mce-p-data-studio-resizable', 'true')
    element.setAttribute('data-mce-p-data-studio-convertible-to-link', 'false')
    expect(parseStudioOptions(element)).toEqual({
      resizable: true,
      convertibleToLink: false,
    })
  })

  it('parses correct values for attributes 3', () => {
    const element = document.createElement('span')
    element.setAttribute('data-mce-p-data-studio-resizable', 'false')
    element.setAttribute('data-mce-p-data-studio-convertible-to-link', 'true')
    expect(parseStudioOptions(element)).toEqual({
      resizable: false,
      convertibleToLink: true,
    })
  })

  it('parses correct values for attributes 4', () => {
    const element = document.createElement('span')
    element.setAttribute('data-mce-p-data-studio-resizable', 'true')
    element.setAttribute('data-mce-p-data-studio-convertible-to-link', 'true')
    expect(parseStudioOptions(element)).toEqual({
      resizable: true,
      convertibleToLink: true,
    })
  })
})

describe('handleBeforeObjectSelected', () => {
  it('does not set data-mce-resize if resize attribute is true', () => {
    const node = document.createElement('span')
    node.setAttribute('data-mce-p-data-studio-resizable', 'true')
    const event = createDeepMockProxy<EditorEvent<Events.ObjectSelectedEvent>>({}, {target: node})
    handleBeforeObjectSelected(event)
    expect(node).not.toHaveAttribute('data-mce-resize')
  })

  it('does not set data-mce-resize if resize attribute is missing', () => {
    const node = document.createElement('span')
    const event = createDeepMockProxy<EditorEvent<Events.ObjectSelectedEvent>>({}, {target: node})
    handleBeforeObjectSelected(event)
    expect(node).not.toHaveAttribute('data-mce-resize')
  })

  it('sets data-mce-resize if resize attribute is false', () => {
    const node = document.createElement('span')
    node.setAttribute('data-mce-p-data-studio-resizable', 'false')
    const event = createDeepMockProxy<EditorEvent<Events.ObjectSelectedEvent>>({}, {target: node})
    handleBeforeObjectSelected(event)
    expect(node.getAttribute('data-mce-resize')).toEqual('false')
  })
})

describe('findStudioLtiIframeFromSelection', () => {
  beforeEach(() => {
    // Reset DOM before each test
    document.body.innerHTML = ''
    // Clear any existing console spies
    jest.clearAllMocks()
  })

  afterEach(() => {
    // Clean up DOM after each test
    document.body.innerHTML = ''
  })

  it('should return iframe when selectedNode is an iframe', () => {
    const iframe = document.createElement('iframe')
    iframe.src = 'https://example.com'
    document.body.appendChild(iframe)

    const result = findStudioLtiIframeFromSelection(iframe)

    expect(result).toBe(iframe)
  })

  it('should find iframe inside selected element', () => {
    const span = document.createElement('span')
    const iframe = document.createElement('iframe')
    iframe.src = 'https://example.com'
    span.appendChild(iframe)
    document.body.appendChild(span)

    const result = findStudioLtiIframeFromSelection(span)

    expect(result).toBe(iframe)
  })

  it('should return null when no iframe is found', () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

    const div = document.createElement('div')
    div.textContent = 'No iframe here'
    document.body.appendChild(div)

    const result = findStudioLtiIframeFromSelection(div)

    expect(consoleSpy).toHaveBeenCalledWith('No outer iframe found')
    expect(result).toBeNull()

    consoleSpy.mockRestore()
  })

  it('should handle text nodes', () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

    const textNode = document.createTextNode('Just text')

    const result = findStudioLtiIframeFromSelection(textNode)

    expect(consoleSpy).toHaveBeenCalledWith('No outer iframe found')
    expect(result).toBeNull()

    consoleSpy.mockRestore()
  })

  it('should handle nested iframe with data-lti-launch attribute', () => {
    const outerIframe = document.createElement('iframe')
    document.body.appendChild(outerIframe)

    // Mock contentDocument
    const nestedIframe = document.createElement('iframe')
    nestedIframe.setAttribute('data-lti-launch', 'true')

    const mockContentDoc = {
      querySelector: jest
        .fn()
        .mockReturnValueOnce(nestedIframe) // First call for data-lti-launch iframe
        .mockReturnValueOnce(null), // Second call shouldn't be reached
    }

    Object.defineProperty(outerIframe, 'contentDocument', {
      value: mockContentDoc,
      writable: true,
      configurable: true,
    })

    const result = findStudioLtiIframeFromSelection(outerIframe)

    expect(mockContentDoc.querySelector).toHaveBeenCalledWith('iframe[data-lti-launch="true"]')
    expect(result).toBe(nestedIframe)
  })

  it('should fallback to any nested iframe when data-lti-launch not found', () => {
    const outerIframe = document.createElement('iframe')
    document.body.appendChild(outerIframe)

    // Create a nested iframe with a custom attribute to verify fallback behavior
    const nestedIframe = document.createElement('iframe')
    nestedIframe.setAttribute('data-test-fallback', 'true')
    nestedIframe.src = 'https://nested-example.com'

    // Create a mock content document that contains our nested iframe
    const mockContentDoc = document.implementation.createHTMLDocument()
    mockContentDoc.body.appendChild(nestedIframe)

    Object.defineProperty(outerIframe, 'contentDocument', {
      value: mockContentDoc,
      writable: true,
      configurable: true,
    })

    const result = findStudioLtiIframeFromSelection(outerIframe)

    // Verify we got the nested iframe by checking its custom attribute
    expect(result).toBe(nestedIframe)
    expect(result?.getAttribute('data-test-fallback')).toBe('true')
    expect(result?.src).toBe('https://nested-example.com/')
  })

  it('should handle cross-origin error and return outer iframe', () => {
    const outerIframe = document.createElement('iframe')
    document.body.appendChild(outerIframe)

    // Mock cross-origin error
    Object.defineProperty(outerIframe, 'contentDocument', {
      get: () => {
        throw new Error('Cross-origin access denied')
      },
      configurable: true,
    })

    const consoleSpy = jest.spyOn(console, 'error').mockImplementation()

    const result = findStudioLtiIframeFromSelection(outerIframe)

    expect(consoleSpy).toHaveBeenCalledWith(
      '>> Cannot access outer iframe content (cross-origin):',
      expect.any(Error),
    )
    expect(result).toBe(outerIframe)

    consoleSpy.mockRestore()
  })

  it('should handle contentWindow when contentDocument is null', () => {
    const outerIframe = document.createElement('iframe')
    document.body.appendChild(outerIframe)

    const mockContentDoc = {
      querySelector: jest.fn().mockReturnValue(null),
    }

    Object.defineProperty(outerIframe, 'contentDocument', {
      value: null,
      writable: true,
      configurable: true,
    })

    Object.defineProperty(outerIframe, 'contentWindow', {
      value: {document: mockContentDoc},
      writable: true,
      configurable: true,
    })

    const result = findStudioLtiIframeFromSelection(outerIframe)

    expect(result).toBe(outerIframe)
  })

  it('should handle multiple iframes and return the first one', () => {
    const container = document.createElement('div')
    const firstIframe = document.createElement('iframe')
    firstIframe.src = 'first.html'
    const secondIframe = document.createElement('iframe')
    secondIframe.src = 'second.html'

    container.appendChild(firstIframe)
    container.appendChild(secondIframe)
    document.body.appendChild(container)

    const result = findStudioLtiIframeFromSelection(container)

    expect(result).toBe(firstIframe)
    expect(result?.src).toContain('first.html')
  })

  it('should handle deeply nested structures', () => {
    const deep = document.createElement('div')
    const iframe = document.createElement('iframe')
    iframe.src = 'test.html'

    const nested = document.createElement('div')
    const span = document.createElement('span')
    const innerDiv = document.createElement('div')

    innerDiv.appendChild(iframe)
    span.appendChild(innerDiv)
    nested.appendChild(span)
    deep.appendChild(nested)
    document.body.appendChild(deep)

    const result = findStudioLtiIframeFromSelection(deep)

    expect(result).toBe(iframe)
    expect(result?.src).toContain('test.html')
  })

  it('should return outer iframe when nested document is empty', () => {
    const outerIframe = document.createElement('iframe')
    document.body.appendChild(outerIframe)

    const mockContentDoc = {
      querySelector: jest.fn().mockReturnValue(null),
    }

    Object.defineProperty(outerIframe, 'contentDocument', {
      value: mockContentDoc,
      writable: true,
      configurable: true,
    })

    const result = findStudioLtiIframeFromSelection(outerIframe)

    expect(mockContentDoc.querySelector).toHaveBeenCalledWith('iframe[data-lti-launch="true"]')
    expect(mockContentDoc.querySelector).toHaveBeenCalledWith('iframe')
    expect(result).toBe(outerIframe)
  })

  it('should handle iframe with contentWindow but no contentDocument', () => {
    const outerIframe = document.createElement('iframe')
    document.body.appendChild(outerIframe)

    Object.defineProperty(outerIframe, 'contentDocument', {
      value: null,
      writable: true,
      configurable: true,
    })

    Object.defineProperty(outerIframe, 'contentWindow', {
      value: null,
      writable: true,
      configurable: true,
    })

    const result = findStudioLtiIframeFromSelection(outerIframe)

    expect(result).toBe(outerIframe)
  })
})

// Remove the old mock for ContentSelection and replace with iframeUtils mock
jest.mock('../iframeUtils', () => ({
  findMediaPlayerIframe: jest.fn(),
}))

const mockFindMediaPlayerIframe = iframeUtils.findMediaPlayerIframe as jest.MockedFunction<
  typeof iframeUtils.findMediaPlayerIframe
>

describe('updateStudioIframeDimensions', () => {
  let mockEditor: any
  let mockIframe: HTMLIFrameElement
  let mockParentElement: HTMLElement

  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks()

    // Create mock editor
    mockEditor = createDeepMockProxy({
      fire: jest.fn(),
      selection: {
        getNode: jest.fn(),
      },
      dom: {
        setStyles: jest.fn(),
        getAttrib: jest.fn(),
        setAttrib: jest.fn(),
      },
      nodeChanged: jest.fn(),
    })

    // Create mock iframe with parent element (TinyMCE shim)
    mockIframe = document.createElement('iframe')
    mockIframe.src = 'https://studio.example.com/embed?type=thumbnail_embed&id=123'

    // Create parent element that represents the TinyMCE iframe shim
    mockParentElement = document.createElement('span')
    mockParentElement.setAttribute('data-mce-p-src', mockIframe.src)
    mockParentElement.appendChild(mockIframe)
    document.body.appendChild(mockParentElement)

    // Mock findMediaPlayerIframe to return our mock iframe
    mockFindMediaPlayerIframe.mockReturnValue(mockIframe)
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  describe('dimension updates', () => {
    it('should update iframe width and height', () => {
      updateStudioIframeDimensions(mockEditor, 800, 600, 'learn_embed')

      // Should set styles on parent shim
      expect(mockEditor.dom.setStyles).toHaveBeenCalledWith(mockParentElement, {
        width: '800px',
        height: '600px',
      })

      // Should set styles on iframe
      expect(mockEditor.dom.setStyles).toHaveBeenCalledWith(mockIframe, {
        width: '800px',
        height: '600px',
      })
    })
  })

  describe('URL replacement', () => {
    it('should replace thumbnail_embed with learn_embed', () => {
      const originalHref = 'https://studio.example.com/embed/thumbnail_embed/123'
      mockEditor.dom.getAttrib.mockReturnValue(originalHref)

      updateStudioIframeDimensions(mockEditor, 800, 600, 'learn_embed')

      expect(mockEditor.dom.setAttrib).toHaveBeenCalledWith(
        mockParentElement,
        'data-mce-p-src',
        'https://studio.example.com/embed/learn_embed/123',
      )
    })

    it('should replace learn_embed with collaboration_embed', () => {
      const originalHref = 'https://studio.example.com/embed/learn_embed/123'
      mockEditor.dom.getAttrib.mockReturnValue(originalHref)

      updateStudioIframeDimensions(mockEditor, 800, 600, 'collaboration_embed')

      expect(mockEditor.dom.setAttrib).toHaveBeenCalledWith(
        mockParentElement,
        'data-mce-p-src',
        'https://studio.example.com/embed/collaboration_embed/123',
      )
    })

    it('should replace collaboration_embed with thumbnail_embed', () => {
      const originalHref = 'https://studio.example.com/embed/collaboration_embed/123'
      mockEditor.dom.getAttrib.mockReturnValue(originalHref)

      updateStudioIframeDimensions(mockEditor, 800, 600, 'thumbnail_embed')

      expect(mockEditor.dom.setAttrib).toHaveBeenCalledWith(
        mockParentElement,
        'data-mce-p-src',
        'https://studio.example.com/embed/thumbnail_embed/123',
      )
    })

    it('should handle multiple occurrences of embed types', () => {
      const originalHref = 'https://studio.example.com/thumbnail_embed/path/thumbnail_embed'
      mockEditor.dom.getAttrib.mockReturnValue(originalHref)

      updateStudioIframeDimensions(mockEditor, 800, 600, 'learn_embed')

      expect(mockEditor.dom.setAttrib).toHaveBeenCalledWith(
        mockParentElement,
        'data-mce-p-src',
        'https://studio.example.com/learn_embed/path/learn_embed',
      )
    })

    it('should not modify URL without embed types', () => {
      const originalHref = 'https://studio.example.com/embed/123'
      mockEditor.dom.getAttrib.mockReturnValue(originalHref)

      updateStudioIframeDimensions(mockEditor, 800, 600, 'learn_embed')

      expect(mockEditor.dom.setAttrib).toHaveBeenCalledWith(
        mockParentElement,
        'data-mce-p-src',
        originalHref, // Should remain unchanged
      )
    })
  })

  describe('event firing', () => {
    it('should fire ObjectResized event with correct data', () => {
      updateStudioIframeDimensions(mockEditor, 800, 600, 'learn_embed')

      expect(mockEditor.fire).toHaveBeenCalledWith('ObjectResized', {
        target: mockIframe,
        width: 800,
        height: 600,
      })
    })
  })

  describe('resizable attribute updates', () => {
    it('should set resizable to true and remove data-mce-resize', () => {
      const removeAttributeSpy = jest.spyOn(mockParentElement, 'removeAttribute')

      updateStudioIframeDimensions(mockEditor, 800, 600, 'learn_embed', true)

      // Should update both the actual attribute and the TinyMCE prefixed version
      expect(mockEditor.dom.setAttrib).toHaveBeenCalledWith(
        mockParentElement,
        'data-studio-resizable',
        'true',
      )
      expect(mockEditor.dom.setAttrib).toHaveBeenCalledWith(
        mockParentElement,
        'data-mce-p-data-studio-resizable',
        'true',
      )
      expect(removeAttributeSpy).toHaveBeenCalledWith('data-mce-resize')

      removeAttributeSpy.mockRestore()
    })

    it('should set resizable to false and add data-mce-resize="false"', () => {
      const setAttributeSpy = jest.spyOn(mockParentElement, 'setAttribute')

      updateStudioIframeDimensions(mockEditor, 800, 600, 'learn_embed', false)

      // Should update both the actual attribute and the TinyMCE prefixed version
      expect(mockEditor.dom.setAttrib).toHaveBeenCalledWith(
        mockParentElement,
        'data-studio-resizable',
        'false',
      )
      expect(mockEditor.dom.setAttrib).toHaveBeenCalledWith(
        mockParentElement,
        'data-mce-p-data-studio-resizable',
        'false',
      )
      expect(setAttributeSpy).toHaveBeenCalledWith('data-mce-resize', 'false')

      setAttributeSpy.mockRestore()
    })

    it('should handle switching from resizable to non-resizable', () => {
      const setAttributeSpy = jest.spyOn(mockParentElement, 'setAttribute')
      mockParentElement.setAttribute('data-studio-resizable', 'true')

      updateStudioIframeDimensions(mockEditor, 800, 600, 'learn_embed', false)

      expect(mockEditor.dom.setAttrib).toHaveBeenCalledWith(
        mockParentElement,
        'data-studio-resizable',
        'false',
      )
      expect(setAttributeSpy).toHaveBeenCalledWith('data-mce-resize', 'false')

      setAttributeSpy.mockRestore()
    })

    it('should handle switching from non-resizable to resizable', () => {
      const removeAttributeSpy = jest.spyOn(mockParentElement, 'removeAttribute')
      mockParentElement.setAttribute('data-studio-resizable', 'false')
      mockParentElement.setAttribute('data-mce-resize', 'false')

      updateStudioIframeDimensions(mockEditor, 800, 600, 'learn_embed', true)

      expect(mockEditor.dom.setAttrib).toHaveBeenCalledWith(
        mockParentElement,
        'data-studio-resizable',
        'true',
      )
      expect(removeAttributeSpy).toHaveBeenCalledWith('data-mce-resize')

      removeAttributeSpy.mockRestore()
    })
  })
})

describe('Studio Media Options Utils', () => {
  describe('isValidEmbedType', () => {
    it('returns true for valid embed types', () => {
      expect(isValidEmbedType('thumbnail_embed')).toBe(true)
      expect(isValidEmbedType('learn_embed')).toBe(true)
      expect(isValidEmbedType('collaboration_embed')).toBe(true)
    })

    it('returns false for invalid strings', () => {
      expect(isValidEmbedType('invalid_embed')).toBe(false)
      expect(isValidEmbedType('thumbnail')).toBe(false)
      expect(isValidEmbedType('learn')).toBe(false)
      expect(isValidEmbedType('collab')).toBe(false)
      expect(isValidEmbedType('')).toBe(false)
      expect(isValidEmbedType('THUMBNAIL_EMBED')).toBe(false)
    })

    it('returns false for non-string values', () => {
      expect(isValidEmbedType(null)).toBe(false)
      expect(isValidEmbedType(undefined)).toBe(false)
      expect(isValidEmbedType(123)).toBe(false)
      expect(isValidEmbedType(true)).toBe(false)
      expect(isValidEmbedType({})).toBe(false)
      expect(isValidEmbedType([])).toBe(false)
      expect(isValidEmbedType(() => {})).toBe(false)
    })
  })

  describe('isValidDimension', () => {
    it('returns true for valid positive numbers', () => {
      expect(isValidDimension(1)).toBe(true)
      expect(isValidDimension(100)).toBe(true)
      expect(isValidDimension(800)).toBe(true)
      expect(isValidDimension(1920)).toBe(true)
      expect(isValidDimension(0.5)).toBe(true)
      expect(isValidDimension(999.99)).toBe(true)
    })

    it('returns false for zero and negative numbers', () => {
      expect(isValidDimension(0)).toBe(false)
      expect(isValidDimension(-1)).toBe(false)
      expect(isValidDimension(-100)).toBe(false)
      expect(isValidDimension(-0.1)).toBe(false)
    })

    it('returns false for invalid numbers', () => {
      expect(isValidDimension(NaN)).toBe(false)
      expect(isValidDimension(Infinity)).toBe(false)
      expect(isValidDimension(-Infinity)).toBe(false)
    })

    it('returns false for non-number values', () => {
      expect(isValidDimension('100')).toBe(false)
      expect(isValidDimension('800px')).toBe(false)
      expect(isValidDimension(null)).toBe(false)
      expect(isValidDimension(undefined)).toBe(false)
      expect(isValidDimension(true)).toBe(false)
      expect(isValidDimension({})).toBe(false)
      expect(isValidDimension([])).toBe(false)
      expect(isValidDimension(() => {})).toBe(false)
    })

    it('handles edge cases correctly', () => {
      expect(isValidDimension(Number.MAX_SAFE_INTEGER)).toBe(true)
      expect(isValidDimension(Number.MIN_VALUE)).toBe(true)
      expect(isValidDimension(1e-10)).toBe(true)
    })
  })

  describe('isValidResizable', () => {
    it('returns true for boolean values', () => {
      expect(isValidResizable(true)).toBe(true)
      expect(isValidResizable(false)).toBe(true)
    })

    it('returns false for non-boolean values', () => {
      expect(isValidResizable(null)).toBe(false)
      expect(isValidResizable(undefined)).toBe(false)
      expect(isValidResizable(0)).toBe(false)
      expect(isValidResizable(1)).toBe(false)
      expect(isValidResizable('true')).toBe(false)
      expect(isValidResizable('false')).toBe(false)
      expect(isValidResizable({})).toBe(false)
      expect(isValidResizable([])).toBe(false)
      expect(isValidResizable(() => {})).toBe(false)
    })
  })
})
