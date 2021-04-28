/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

export default function sanitizeHtml(html) {
  // Note: it is expected that tinymce be loaded and available globally at `window.tinymce` by the
  // time this function runs. To do that you can just make sure to call
  // RichContentEditor.preloadRemoteModule first
  return new tinymce.html.Serializer().serialize(new tinymce.html.DomParser().parse(html))
}
