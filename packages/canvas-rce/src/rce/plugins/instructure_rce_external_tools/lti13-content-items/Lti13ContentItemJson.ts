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

import {DeepPartialNullable} from '../../../../util/DeepPartialNullable'

export type Lti13ContentItemJson =
  | HtmlFragmentContentItemJson
  | ImageContentItemJson
  | LinkContentItemJson
  | ResourceLinkContentItemJson
  | UnknownContentItemJson

export type UnknownContentItemJson = DeepPartialNullable<{
  type: string
  [key: string]: any
}>

export type HtmlFragmentContentItemJson = DeepPartialNullable<{
  type: 'html'
  html: string
  title: string
  text: string
}>

export type ImageContentItemJson = DeepPartialNullable<{
  type: 'image'
  url: string
  title: string
  thumbnail: ContentItemThumbnailJson | string
  text: string
  width: number | string
  height: number | string
}>

export type BaseLinkContentItemJson = DeepPartialNullable<{
  type: 'link' | 'ltiResourceLink'
  url: string
  title: string
  text: string
  icon: unknown
  thumbnail: unknown
  iframe: ContentItemIframeJson
  custom: unknown
  lookup_uuid: string
}>

export type LinkContentItemJson = DeepPartialNullable<
  BaseLinkContentItemJson & {
    type: 'link'
  }
>

export type ResourceLinkContentItemJson = DeepPartialNullable<
  BaseLinkContentItemJson & {
    type: 'ltiResourceLink'
    lookup_uuid: string
  }
>

export type ContentItemThumbnailJson = DeepPartialNullable<{
  url: string
  width: number | string
  height: number | string
}>

export function isContentItemThumbnailJson(
  input: any
): input is ContentItemThumbnailJson & {url: string} {
  return typeof input === 'object' && typeof input.url === 'string'
}

export type ContentItemIframeJson = DeepPartialNullable<{
  src: string
  width: number | string
  height: number | string
}>

export function isContentItemIframeJson(
  input: any
): input is ContentItemIframeJson & {src: string} {
  return typeof input === 'object' && typeof input.src === 'string'
}
