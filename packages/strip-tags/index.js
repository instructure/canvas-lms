/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import 'jquery'

/* Make an html snippet plain text.
 *
 * Removes tags, and converts entities to their character equivalents.
 * Because it uses a detached element, it's safe to use on untrusted
 * input.
 *
 * That said, the result is NOT an html-safe string, because it only
 * does a single pass. e.g.
 *
 * "<b>hi</b> &lt;script&gt;..." -> "hi <script>..."
 */
const $stripDiv = $('<div />')

export default function(html) {
  return $stripDiv.html(html).text()
}
