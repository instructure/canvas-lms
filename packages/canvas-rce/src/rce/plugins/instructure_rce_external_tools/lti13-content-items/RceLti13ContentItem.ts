// @ts-nocheck
/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
  isContentItemIframeJson,
  isContentItemThumbnailJson,
  Lti13ContentItemJson,
} from './Lti13ContentItemJson'
import {addParentFrameContextToUrl} from '../util/addParentFrameContextToUrl'

/**
 * Represents an LTI 1.3 Deep Linking Content Item for purposes related to the Rich Content Editor.
 *
 * Use rceLti13ContentItemFromJson to create instances of this class.
 */
export abstract class RceLti13ContentItem<TJson extends object> {
  constructor(
    public readonly type: Lti13ContentItemJson['type'],
    public readonly json: TJson,
    public readonly context: RceLti13ContentItemContext
  ) {}

  abstract buildTitle(): string | null | undefined

  abstract buildText(): string | null | undefined

  abstract buildUrl(): string | null | undefined

  abstract toHtmlString()

  private get untypedJson() {
    return this.json as Record<string, unknown>
  }

  linkThumbnail() {
    if (isContentItemThumbnailJson(this.untypedJson.thumbnail)) {
      const {url, width, height} = this.untypedJson.thumbnail

      return this.imageTag(url, width, height)
    } else if (typeof this.untypedJson.thumbnail === 'string') {
      return this.imageTag(this.untypedJson.thumbnail)
    }
  }

  iframeTag() {
    const iframeInfo = this.untypedJson.iframe

    if (isContentItemIframeJson(iframeInfo)) {
      const iframeTag = document.createElement('iframe')

      iframeTag.setAttribute(
        'src',
        addParentFrameContextToUrl(iframeInfo.src, this.context.containingCanvasLtiToolId) ?? ''
      )
      iframeTag.setAttribute('title', this.buildTitle() || '')
      iframeTag.setAttribute('allowfullscreen', 'true')
      iframeTag.setAttribute('allow', this.context.ltiIframeAllowPolicy ?? '')

      if (iframeInfo.width) {
        iframeTag.style.width = `${iframeInfo.width}px`
      }

      if (iframeInfo.height) {
        iframeTag.style.height = `${iframeInfo.height}px`
      }

      return iframeTag.outerHTML
    }
  }

  imageTag(src: string, width?: string | number | null, height?: string | number | null) {
    const imgTag = document.createElement('img')
    imgTag.setAttribute('src', src)

    const text = this.buildText()
    if (text != null) {
      imgTag.setAttribute('alt', text)
    }

    if (width) {
      imgTag.setAttribute('width', width.toString())
    }

    if (height) {
      imgTag.setAttribute('height', height.toString())
    }

    return imgTag.outerHTML
  }

  anchorTag(innerHTML: string | null | undefined) {
    const anchorTag = document.createElement('a')
    anchorTag.setAttribute('href', this.safeUrl)
    anchorTag.setAttribute('title', this.buildTitle() || '')
    anchorTag.setAttribute('target', '_blank')
    anchorTag.innerHTML = innerHTML || ''
    return anchorTag.outerHTML
  }

  get safeUrl(): string {
    return this.buildUrl()?.replace(/^(data:text\/html|javascript:)/, '#$1') || ''
  }
}

export interface RceLti13ContentItemClass<T extends Lti13ContentItemJson> {
  new (json: T, context: RceLti13ContentItemContext): RceLti13ContentItem<T>
}

export interface RceLti13ContentItemContext {
  ltiIframeAllowPolicy: string | null
  containingCanvasLtiToolId: string | null
  ltiEndpoint: string | null
  selection: string | null
}
