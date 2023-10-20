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

import $ from 'jquery'
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
} from '../../shared/StudioLtiSupportUtils'

export class RceLti11ContentItem {
  static fromJSON(
    contentItem: RceLti11ContentItemJson,
    env: ExternalToolsEnv = externalToolsEnvFor(tinymce.activeEditor)
  ): RceLti11ContentItem {
    return new RceLti11ContentItem(contentItem, env)
  }

  constructor(
    public readonly contentItem: RceLti11ContentItemJson,
    public readonly env: ExternalToolsEnv = externalToolsEnvFor(tinymce.activeEditor)
  ) {}

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
      '#$1'
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

  private generateCodePayloadIframe(): string {
    const studioAttributes = isStudioContentItemCustomJson(this.contentItem.custom)
      ? studioAttributesFrom(this.contentItem.custom)
      : null

    return $('<div/>')
      .append(
        $('<iframe/>', {
          src: addParentFrameContextToUrl(this.url, this.containingCanvasLtiToolId),
          title: this.contentItem.title,
          allowfullscreen: 'true',
          webkitallowfullscreen: 'true',
          mozallowfullscreen: 'true',
          allow: this.env?.ltiIframeAllowPolicy,
          ...studioAttributes,
        })
          .addClass(this.contentItem.class ?? '')
          .css({
            width: this.contentItem.placementAdvice?.displayWidth ?? '',
            height: this.contentItem.placementAdvice?.displayHeight ?? '',
            display: displayStyleFrom(studioAttributes),
          })
          .attr({
            width: this.contentItem.placementAdvice?.displayWidth ?? '',
            height: this.contentItem.placementAdvice?.displayHeight ?? '',
          })
      )
      .html()
  }

  private generateCodePayloadEmbed(): string {
    return $('<div/>')
      .append(
        $('<img/>', {
          src: this.url,
          alt: this.text,
        }).css({
          width: this.contentItem.placementAdvice?.displayWidth ?? '',
          height: this.contentItem.placementAdvice?.displayHeight ?? '',
        })
      )
      .html()
  }

  private generateCodePayloadText(): string {
    return this.text ?? ''
  }

  private get containingCanvasLtiToolId(): string | null {
    return this.env.containingCanvasLtiToolId
  }

  private get currentTinyMceSelection(): string | null {
    return this.env.editorSelection
  }

  private generateCodePayloadLink(): string {
    const $linkContainer = $('<div/>'),
      $link = $('<a/>', {
        href: this.url,
        title: this.contentItem.title,
        target: this.linkTarget,
      })

    if (this.linkClassName) {
      $link.addClass(this.linkClassName)
    }

    $linkContainer.append($link)
    if (this.contentItem.thumbnail) {
      $link.append(
        $('<img />', {
          src: this.contentItem.thumbnail['@id'],
          height: this.contentItem.thumbnail.height ?? 48,
          width: this.contentItem.thumbnail.width ?? 48,
          alt: this.text,
        })
      )
    } else if (emptyAsNull(this.currentTinyMceSelection) != null && $link[0] != null) {
      $link[0].innerHTML = this.currentTinyMceSelection ?? ''
    } else {
      // don't inject tool provided content into the page HTML
      $link.text(this.generateLinkHtml() ?? '')
    }

    return $linkContainer.html()
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
