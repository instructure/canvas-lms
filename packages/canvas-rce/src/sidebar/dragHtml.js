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

import * as browser from '../common/browser'

export default function (ev, html) {
  // default data to store
  let format = 'text/html'
  let data = html

  // special handling for IE and Edge
  if (browser.edge()) {
    // MS Edge can do text/html, but may have stuff in ev.dataTransfer.files
    // (e.g. when dragging an image) that confuses tinymce's onDrop handler
    // into suppressing the drop event. fortunately, calling clear() on the
    // items will also clear the ev.dataTransfer.files.
    ev.dataTransfer.items.clear()
  } else if (browser.ie()) {
    // pre-Edge Internet Explorer doesn't like setData with a type other than
    // 'Text' or 'URL'. fortunately tinymce already provides a workaround
    // (though an internal one we're technically abusing) that lets it
    // recognize an encoded 'Text' data string.
    //
    //  * the first part (data:text/mce-internal) prefix tells it to decode
    //  * the second part (rcs-sidebar) is expected to be an editor id. but
    //    it's only used to distinguish "came from something else" vs. "came
    //    from somewhere else in the same editor", so using a unique value
    //    there suffices.
    //  * the third part is the encoded html
    //
    format = 'Text'
    data = `data:text/mce-internal,rcs-sidebar,${escape(html)}`
  }

  // place the data into the dataTransfer so it's available for the drop event
  ev.dataTransfer.setData(format, data)
}
