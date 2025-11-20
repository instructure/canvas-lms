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

import {bool, shape} from 'prop-types'
import {Editor, EditorEvent, Events} from 'tinymce'
import {findMediaPlayerIframe} from './iframeUtils'

/**
 * Interface for content item's 'custom' field, specifically for what is expected to come from Studio
 *
 * Used to determine whether or not Studio embedded media should be resizable, and whether or not we
 * present controls for the user to modify the embedded media.
 */
export interface StudioContentItemCustomJson {
  source: 'studio'
  resizable?: boolean
  enableMediaOptions?: boolean
}

export interface StudioMediaOptionsAttributes {
  'data-studio-resizable': boolean
  'data-studio-tray-enabled': boolean
  'data-studio-convertible-to-link': boolean
}

export const parsedStudioOptionsPropType = shape({
  resizable: bool.isRequired,
  convertibleToLink: bool.isRequired,
})

export type ParsedStudioOptions = {
  resizable: boolean
  convertibleToLink: boolean
  embedOptions: StudioEmbedOptions
}

type ValidStudioEmbedType = 'thumbnail_embed' | 'learn_embed' | 'collaboration_embed'

export type StudioEmbedTypeChangedResponse = {
  subject: 'studio.embedTypeChanged.response'
  width: number
  height: number
  embedType: ValidStudioEmbedType
  resizable?: boolean
}

export function isStudioContentItemCustomJson(input: any): input is StudioContentItemCustomJson {
  return typeof input === 'object' && input.source === 'studio'
}

export const isValidEmbedType = (embedType: any): embedType is ValidStudioEmbedType => {
  return (
    typeof embedType === 'string' &&
    ['thumbnail_embed', 'learn_embed', 'collaboration_embed'].includes(embedType)
  )
}

export const isValidDimension = (value: any): value is number => {
  return typeof value === 'number' && !isNaN(value) && isFinite(value) && value > 0
}

export const isValidResizable = (value: any): value is boolean => {
  return typeof value === 'boolean'
}

export function studioAttributesFrom(
  customJson: StudioContentItemCustomJson,
): StudioMediaOptionsAttributes {
  return {
    'data-studio-resizable': customJson.resizable ?? false,
    'data-studio-tray-enabled': customJson.enableMediaOptions ?? false,
    'data-studio-convertible-to-link': true,
  }
}

export function displayStyleFrom(
  studioAttributes: StudioMediaOptionsAttributes | null,
): 'inline-block' | '' {
  if (!studioAttributes) return ''

  return studioAttributes['data-studio-resizable'] || studioAttributes['data-studio-tray-enabled']
    ? 'inline-block'
    : ''
}

export function isStudioEmbeddedMedia(element: Element): boolean {
  // Borrowing this structure from isMediaElement in ContentSelection.js
  const tinymceIframeShim = element?.tagName === 'IFRAME' ? element?.parentElement : element

  if (tinymceIframeShim?.firstElementChild?.tagName !== 'IFRAME') {
    return false
  }

  return tinymceIframeShim.getAttribute('data-mce-p-data-studio-tray-enabled') === 'true'
}

export function parseStudioOptions(element: Element | null): ParsedStudioOptions {
  const tinymceIframeShim = element?.tagName === 'IFRAME' ? element?.parentElement : element

  const embedOptions = {} as StudioEmbedOptions;
  const href = tinymceIframeShim?.getAttribute('data-mce-p-src')

  if (href) {
    // parse out embed options from url params
    const urlMatch = href.match(/url=([^&]*)$/)
    const url = new URL(decodeURIComponent(urlMatch ? urlMatch[1] : ''))
    const params = url.searchParams

    embedOptions['enableMediaDownload'] = params.get('custom_arc_display_download') === 'true'
    embedOptions['enableTranscriptDownload'] = params.get('custom_arc_transcript_downloadable') === 'true'
    embedOptions['lockSpeed']= params.get('custom_arc_lock_speed') === 'true'
    embedOptions['isExternal']= params.get('custom_arc_is_external') === 'true'
  }

  return {
    resizable: tinymceIframeShim?.getAttribute('data-mce-p-data-studio-resizable') === 'true',
    convertibleToLink:
      tinymceIframeShim?.getAttribute('data-mce-p-data-studio-convertible-to-link') === 'true',
    embedOptions,
  }
}

/**
 * Tinymce adds an overlay when you click on an iframe inside the editor. It will by default
 * add resize handles to the corners of the overlay. The code that adds these handles won't
 * if the overlay has `data-mce-resize='false'` on it. Here, we force that behavior when the
 * underlying iframe has a `data-studio-resizable='false'`
 */
export function handleBeforeObjectSelected(e: EditorEvent<Events.ObjectSelectedEvent>): void {
  const targetElement = e.target as Element

  if (targetElement.getAttribute('data-mce-p-data-studio-resizable') === 'false') {
    targetElement.setAttribute('data-mce-resize', 'false')
  }
}

export function findStudioLtiIframeFromSelection(selectedNode: Node): HTMLIFrameElement | null {
  let outerIframe: HTMLIFrameElement | null = null

  // First, find the outer iframe
  if (selectedNode.nodeName === 'IFRAME') {
    outerIframe = selectedNode as HTMLIFrameElement
  } else if (selectedNode.nodeType === Node.ELEMENT_NODE) {
    // Look for iframe inside the selected element (the span)
    outerIframe = (selectedNode as Element).querySelector('iframe') as HTMLIFrameElement
  }

  if (!outerIframe) {
    // eslint-disable-next-line no-console
    console.error('No outer iframe found')
    return null
  }

  // Now try to access the content document of the outer iframe
  try {
    const outerIframeDoc = outerIframe.contentDocument || outerIframe.contentWindow?.document

    if (!outerIframeDoc) {
      return outerIframe // Return outer iframe as fallback
    }

    // Search for nested iframe with data-lti-launch attribute
    const nestedIframe = outerIframeDoc.querySelector(
      'iframe[data-lti-launch="true"]',
    ) as HTMLIFrameElement

    if (nestedIframe) {
      return nestedIframe
    } else {
      // Try to find any iframe inside
      const anyNestedIframe = outerIframeDoc.querySelector('iframe') as HTMLIFrameElement
      if (anyNestedIframe) {
        return anyNestedIframe
      }
    }
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('>> Cannot access outer iframe content (cross-origin):', error)
    // Return the outer iframe as fallback since we can't access its contents
    return outerIframe
  }

  return outerIframe
}

export type EmbedType = 'thumbnail_embed' | 'learn_embed' | 'collaboration_embed'

export const notifyStudioEmbedTypeChange = (
  editor: Editor,
  embedType: EmbedType,
) => {
  const studioIframe = findStudioLtiIframeFromSelection(editor.selection.getNode())

  if (studioIframe && studioIframe.contentWindow) {
    studioIframe.contentWindow.postMessage(
      {
        subject: 'studio.embedTypeChanged',
        embedType: embedType,
        timestamp: Date.now(),
      },
      '*',
    )
  }
}

export const validateStudioEmbedTypeChangeResponse = (
  data: any,
): data is StudioEmbedTypeChangedResponse => {
  return (
    isValidDimension(data.width) &&
    isValidDimension(data.height) &&
    isValidEmbedType(data.embedType)
  )
}

export const updateStudioIframeDimensions = (
  editor: Editor,
  data: StudioEmbedTypeChangedResponse,
) => {
  const {width, height, embedType, resizable} = data

  const selectedNode = editor.selection.getNode()
  const videoContainer = findMediaPlayerIframe(selectedNode)

  if (videoContainer?.tagName !== 'IFRAME') {
    return
  }

  const tinymceIframeShim = videoContainer.parentElement

  if (!tinymceIframeShim || !videoContainer) {
    return
  }

  editor.dom.setStyles(tinymceIframeShim, {
    width: `${width}px`,
    height: `${height}px`,
  })

  editor.dom.setStyles(videoContainer, {
    width: `${width}px`,
    height: `${height}px`,
  })

  if (resizable !== undefined && isValidResizable(resizable)) {
    // Update both the actual attribute and the TinyMCE prefixed version
    // This ensures they stay in sync when content is saved and reloaded
    editor.dom.setAttrib(tinymceIframeShim, 'data-studio-resizable', String(resizable))
    editor.dom.setAttrib(tinymceIframeShim, 'data-mce-p-data-studio-resizable', String(resizable))

    // Force TinyMCE to update the overlay by setting/removing data-mce-resize
    if (!resizable) {
      tinymceIframeShim.setAttribute('data-mce-resize', 'false')
    } else {
      tinymceIframeShim.removeAttribute('data-mce-resize')
    }
  }

  const href = editor.dom.getAttrib(tinymceIframeShim, 'data-mce-p-src')

  if (href && embedType) {
    if (embedType) {
      // Replace thumbnail_embed, learn_embed, or collaboration_embed with the new embed type
      const updatedHref = href.replace(
        /(thumbnail_embed|learn_embed|collaboration_embed)/g,
        embedType,
      )

      // updating only mce-p-src as in we only want to update the real src whenever we step out of the editor or save it
      editor.dom.setAttrib(tinymceIframeShim, 'data-mce-p-src', updatedHref)
      editor.nodeChanged()
    }
  }

  editor.fire('ObjectResized', {
    // @ts-expect-error - needed for aligning tooltip with new iframe size
    target: videoContainer,
    width,
    height,
  })
}

export type StudioEmbedOptions = {
  enableMediaDownload: boolean
  enableTranscriptDownload: boolean
  lockSpeed: boolean
  isExternal: boolean
}

const embedOptionsKeyMap: {[key in keyof StudioEmbedOptions]: string} = {
  enableMediaDownload: 'custom_arc_display_download',
  enableTranscriptDownload: 'custom_arc_transcript_downloadable',
  lockSpeed: 'custom_arc_lock_speed',
  isExternal: 'custom_arc_is_external',
}

export function validateStudioEmbedOptions(input: any): input is StudioEmbedOptions {
  return (
    typeof input === 'object' && (
      Object.keys(input).length === 0 ||
      typeof input.enableMediaDownload === 'boolean' ||
      typeof input.enableTranscriptDownload === 'boolean' ||
      typeof input.lockSpeed === 'boolean'
    )
  )
}

export function updateStudioEmbedOptions (editor: Editor, embedOptions: StudioEmbedOptions) {
  const container = editor.getContainer()
  const iframe = container.querySelector('iframe');
  const mcseShim = iframe?.contentDocument?.querySelector('.mce-shim');
  const tinymceIframeShim = mcseShim?.parentElement;

  if (!tinymceIframeShim) {
    return
  }

  const href = editor.dom.getAttrib(tinymceIframeShim, 'data-mce-p-src')

  if (!href) {
    return
  }

  const urlMatch = href.match(/url=([^&]*)$/)
  const url = new URL(decodeURIComponent(urlMatch ? urlMatch[1] : ''))
  const params = url.searchParams

  for (const [option, param] of Object.entries(embedOptionsKeyMap)) {
    const optionValue = embedOptions[option as keyof StudioEmbedOptions]
    if (optionValue) {
      params.set(param, 'true')
    } else if (params.has(param)) {
      params.delete(param)
    }
  }

  const newHref = href.replace(/(url=)(.*)$/, `$1${encodeURIComponent(url.toString())}`)
  editor.dom.setAttrib(tinymceIframeShim, 'data-mce-p-src', newHref)
}
