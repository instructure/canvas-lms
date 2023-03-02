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

import {RceLti13ContentItem, RceLti13ContentItemContext} from '../RceLti13ContentItem'
import {HtmlFragmentContentItemJson} from '../Lti13ContentItemJson'

export default class HtmlFragmentContentItem extends RceLti13ContentItem<HtmlFragmentContentItemJson> {
  static readonly type = 'html'

  constructor(json: HtmlFragmentContentItemJson, context: RceLti13ContentItemContext) {
    super(HtmlFragmentContentItem.type, json, context)
  }

  get html() {
    return this.json.html
  }

  override buildTitle() {
    return this.json.title
  }

  override buildText() {
    return this.json.text
  }

  override buildUrl() {
    return undefined
  }

  override toHtmlString() {
    // TinyMCE takes care of sanitizing this HTML string.
    // If using a target other than TinyMCE be sure to sanitize.
    return this.html
  }
}
