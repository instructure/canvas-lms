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

import {Lti13ContentItemJson} from './Lti13ContentItemJson'
import HtmlFragmentContentItem from './models/HtmlFragmentContentItem'
import ImageContentItem from './models/ImageContentItem'
import LinkContentItem from './models/LinkContentItem'
import ResourceLinkContentItem from './models/ResourceLinkContentItem'
import {
  RceLti13ContentItem,
  RceLti13ContentItemClass,
  RceLti13ContentItemContext,
} from './RceLti13ContentItem'

/**
 * Creates an RceLti13ContentItem from the given JSON, or null if the type isn't supported.
 *
 * Note: this function would ideally be a static member of RceLti13ContentItem, but that creates a circular dependency
 *       with the implementations of the base class, so it needs to be in a separate module.
 *
 * @param itemJson
 * @param context
 */
export function rceLti13ContentItemFromJson<TJson extends Lti13ContentItemJson>(
  itemJson: TJson,
  context: RceLti13ContentItemContext
): RceLti13ContentItem<TJson> | null {
  if (!itemJson.type) return null

  const clazz = typeRegistry[itemJson.type] as RceLti13ContentItemClass<TJson> | undefined
  // eslint-disable-next-line new-cap
  return clazz ? new clazz(itemJson, context) : null
}

/*
 * Type safe registry of implementation of RceLti13ContentItem. Adding additional types to the Lti13ContentItemJson
 * union will cause a compiler error if the implementations aren't added here as well.
 */
const typeRegistry: Record<
  Exclude<Lti13ContentItemJson['type'], null | undefined>,
  RceLti13ContentItemClass<any>
> = {
  html: HtmlFragmentContentItem,
  image: ImageContentItem,
  link: LinkContentItem,
  ltiResourceLink: ResourceLinkContentItem,
}
