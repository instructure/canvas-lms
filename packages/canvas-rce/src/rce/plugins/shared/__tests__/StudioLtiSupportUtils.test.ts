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
} from '../StudioLtiSupportUtils'
import {EditorEvent, Events} from 'tinymce'
import {createDeepMockProxy} from '../../../../util/__tests__/deepMockProxy'

describe('studioAttributesFrom', () => {
  it('uses the default values for missing attributes', () => {
    const customJson: StudioContentItemCustomJson = {source: 'studio'}
    expect(studioAttributesFrom(customJson)).toMatchInlineSnapshot(`
      Object {
        "data-studio-convertible-to-link": true,
        "data-studio-resizable": false,
        "data-studio-tray-enabled": false,
      }
    `)
  })

  it('parses the correct attribute values when they are passed', () => {
    let customJson: StudioContentItemCustomJson = {
      source: 'studio',
      enableMediaOptions: true,
      resizable: true,
    }
    expect(studioAttributesFrom(customJson)).toMatchInlineSnapshot(`
      Object {
        "data-studio-convertible-to-link": true,
        "data-studio-resizable": true,
        "data-studio-tray-enabled": true,
      }
    `)

    customJson = {
      source: 'studio',
      enableMediaOptions: false,
      resizable: false,
    }
    expect(studioAttributesFrom(customJson)).toMatchInlineSnapshot(`
      Object {
        "data-studio-convertible-to-link": true,
        "data-studio-resizable": false,
        "data-studio-tray-enabled": false,
      }
    `)
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
