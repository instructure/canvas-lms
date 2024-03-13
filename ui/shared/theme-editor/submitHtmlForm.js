/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import htmlEscape from '@instructure/html-escape'
import 'jquery.cookie'

export function submitHtmlForm(action, method, md5) {
  $(`<form hidden action="${htmlEscape(action)}" method="POST">
    <input name="_method" type="hidden" value="${htmlEscape(method)}" />
    <input name="authenticity_token" type="hidden" value="${htmlEscape($.cookie('_csrf_token'))}" />
    <input name="${htmlEscape(
      md5 === undefined ? 'ignorethis' : 'brand_config_md5'
    )}" value="${htmlEscape(md5 || '')}" />
  </form>`)
    .appendTo('body')
    .trigger('submit')
}
