/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {DeepPartialNullable} from '../../../../util/DeepPartialNullable'
import {ExternalToolsEnv, externalToolsEnvFor} from '../ExternalToolsEnv'
import {emptyAsNull} from '../../../../util/string-util'
import {addParentFrameContextToUrl} from '../util/addParentFrameContextToUrl'
import tinymce from 'tinymce'
import {
  StudioContentItemCustomJson,
  isStudioContentItemCustomJson,
  studioAttributesFrom,
  displayStyleFrom,
  StudioMediaOptionsAttributes,
} from '../../shared/StudioLtiSupportUtils'

function maybeAddPx(value: string | number | undefined): string | undefined {
  if (value == null) return undefined
  const strVal = String(value).trim()
  if (/^\d+$/.test(strVal)) {
    return strVal + 'px'
  }
  return strVal
}

export class RceLti11ContentItem {
  readonly contentItem: RceLti11ContentItemJson

  readonly env: ExternalToolsEnv

  static fromJSON(
    contentItem: RceLti11ContentItemJson,
    env: ExternalToolsEnv = externalToolsEnvFor(tinymce.activeEditor),
  ): RceLti11ContentItem {
    return new RceLti11ContentItem(contentItem, env)
  }

  constructor(
    contentItem: RceLti11ContentItemJson,
    env: ExternalToolsEnv = externalToolsEnvFor(tinymce.activeEditor),
  ) {
    this.contentItem = contentItem
    this.env = env
  }

  get text() {
    return this.contentItem.text
  }

  get isLTI(): boolean {
    return LTI_MIME_TYPES.includes(this.contentItem.mediaType ?? '')
  }

  get isOverriddenForThumbnail() {
    return (
      this.isLTI &&
      this.contentItem.thumbnail &&
      this.contentItem.placementAdvice?.presentationDocumentTarget === 'iframe'
    )
  }

  get isImage(): boolean {
    return this.contentItem.mediaType?.startsWith?.('image') === true
  }

  get linkClassName(): string {
    return this.isOverriddenForThumbnail ? 'lti-thumbnail-launch' : ''
  }

  get url() {
    return (this.isLTI ? this.contentItem.canvasURL : this.contentItem.url)?.replace(
      /^(data:text\/html|javascript:)/,
      '#$1',
    )
  }

  get linkTarget(): string | null {
    if (this.isOverriddenForThumbnail) {
      return JSON.stringify(this.contentItem.placementAdvice)
    }
    return this.contentItem?.placementAdvice?.presentationDocumentTarget?.toLowerCase() === 'window'
      ? '_blank'
      : null
  }

  get docTarget(): string | undefined {
    if (
      this.contentItem?.placementAdvice?.presentationDocumentTarget === 'embed' &&
      !this.isImage
    ) {
      return 'text'
    } else if (this.isOverriddenForThumbnail) {
      return 'link'
    }
    return this.contentItem?.placementAdvice?.presentationDocumentTarget?.toLowerCase()
  }

  get codePayload(): string {
    switch (this.docTarget) {
      case 'iframe':
        return this.generateCodePayloadIframe()
      case 'embed':
        return this.generateCodePayloadEmbed()
      case 'text':
        return this.generateCodePayloadText()
      default:
        return this.generateCodePayloadLink()
    }
  }

  private get containingCanvasLtiToolId(): string | null {
    return this.env.containingCanvasLtiToolId
  }

  private get currentTinyMceSelection(): string | null {
    return this.env.editorSelection
  }

  private generateCodePayloadIframe(): string {
    const iframe = document.createElement('iframe')
    iframe.src = addParentFrameContextToUrl(this.url, this.containingCanvasLtiToolId) ?? ''
    iframe.title = this.contentItem.title ?? ''
    iframe.setAttribute('allowfullscreen', 'true')
    iframe.setAttribute('webkitallowfullscreen', 'true')
    iframe.setAttribute('mozallowfullscreen', 'true')
    if (this.env?.ltiIframeAllowPolicy !== undefined) {
      iframe.setAttribute('allow', this.env.ltiIframeAllowPolicy)
    } else if (this.isLTI) {
      iframe.setAttribute('allow', 'microphone; camera; midi')
    }
    if (this.contentItem.class) {
      iframe.className = this.contentItem.class
    }
    const w = maybeAddPx(this.contentItem.placementAdvice?.displayWidth ?? undefined)
    const h = maybeAddPx(this.contentItem.placementAdvice?.displayHeight ?? undefined)
    if (w) {
      iframe.style.width = w
      iframe.setAttribute('width', w.replace('px', ''))
    }
    if (h) {
      iframe.style.height = h
      iframe.setAttribute('height', h.replace('px', ''))
    }

    if (isStudioContentItemCustomJson(this.contentItem.custom)) {
      const studioAttributes: StudioMediaOptionsAttributes = studioAttributesFrom(
        this.contentItem.custom,
      )
      const ds = displayStyleFrom(studioAttributes)
      if (ds) iframe.style.display = ds
      for (const key in studioAttributes) {
        const val = studioAttributes[key as keyof typeof studioAttributes]
        if (val !== undefined && val !== null) {
          iframe.setAttribute(key, String(val))
        }
      }
    }

    const div = document.createElement('div')
    div.appendChild(iframe)
    return div.innerHTML
  }

  private generateCodePayloadEmbed(): string {
    const img = document.createElement('img')
    if (this.url) img.src = this.url
    if (this.text) img.alt = this.text
    const w = maybeAddPx(this.contentItem.placementAdvice?.displayWidth ?? undefined)
    const h = maybeAddPx(this.contentItem.placementAdvice?.displayHeight ?? undefined)
    if (w) img.style.width = w
    if (h) img.style.height = h

    const div = document.createElement('div')
    div.appendChild(img)
    return div.innerHTML
  }

  private generateCodePayloadText(): string {
    return this.text ?? ''
  }

  private generateCodePayloadLink(): string {
    const div = document.createElement('div')
    const a = document.createElement('a')

    if (this.url) a.href = this.url
    if (this.contentItem.title) a.title = this.contentItem.title
    if (this.linkTarget) a.target = this.linkTarget
    if (this.linkClassName) a.className = this.linkClassName

    div.appendChild(a)
    if (this.contentItem.thumbnail && this.contentItem.thumbnail['@id']) {
      const img = document.createElement('img')
      img.src = this.contentItem.thumbnail['@id']
      const h = maybeAddPx(this.contentItem.thumbnail.height ?? 48)
      const w = maybeAddPx(this.contentItem.thumbnail.width ?? 48)
      if (h) img.style.height = h
      if (w) img.style.width = w
      if (this.text) img.alt = this.text
      a.appendChild(img)
    } else if (emptyAsNull(this.currentTinyMceSelection) != null && a != null) {
      a.innerHTML = this.currentTinyMceSelection ?? ''
    } else {
      // don't inject tool provided content into the page HTML
      const linkHtml = this.generateLinkHtml()
      if (linkHtml) a.textContent = linkHtml
    }

    return div.innerHTML
  }

  private generateLinkHtml() {
    return (
      emptyAsNull(this.currentTinyMceSelection) ??
      emptyAsNull(this.contentItem.text?.trim()) ??
      this.contentItem?.title?.trim()
    )
  }
}

const LTI_MIME_TYPES = [
  'application/vnd.ims.lti.v1.ltilink',
  'application/vnd.ims.lti.v1.launch+json',
]

/**
 * Declare the global tinyMCE information used to pass editor context around in Canvas.
 *
 * Eventually, this should be moved into packages/canvas-rce.
 */
declare global {
  interface Window {
    tinyMCE?: {
      activeEditor?: {
        selection: {
          getContent(): string
        }
      }
    } | null
  }
}

/**
 * Interface for content items that come from external tool resource selection.
 *
 * Note that this interface may not be exhaustive, but provides types for the portion of ContentItem used by Canvas.
 * Additionally, there are some extra properties present here used by canvas
 *
 * See https://www.imsglobal.org/spec/lti-dl/v2p0#content-item-types
 * and https://www.imsglobal.org/lti/model/mediatype/application/vnd/ims/lti/v1/contentitems%2Bjson/index.html
 * and https://www.imsglobal.org/lti/model/mediatype/application/vnd/ims/lti/v1/contentitems%2Bjson/context.json
 */
export type RceLti11ContentItemJson = DeepPartialNullable<{
  '@type': 'ContentItem' | 'LtiLinkItem' | 'FileItem' | 'LtiLink' | string
  '@id': string

  mediaType: string

  text: string
  title: string
  url: string

  thumbnail: {
    '@id': string

    // Note that the spec calls for these to be numbers, but strings occur in real-world data
    height: number | string
    width: number | string
  }

  placementAdvice: {
    displayHeight: number | string
    displayWidth: number | string
    presentationDocumentTarget: 'window' | 'embed' | 'iframe' | string
  }

  // Extra properties used in canvas
  canvasURL: string
  class: string

  // Custom property which is part of the standard, but is currently only supported for the Studio LTI
  custom: StudioContentItemCustomJson | unknown
}>
