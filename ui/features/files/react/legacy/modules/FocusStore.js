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

export default {
  _itemToFocus: null,

  setItemToFocus(DOMNode) {
    return (this._itemToFocus = DOMNode)
  },

  getItemToFocus() {
    return this._itemToFocus
  },

  setFocusToItem() {
    if (this._itemToFocus) {
      return this._itemToFocus.focus()
    } else {
      throw new Error('FocusStore has not been set.')
    }
  },
}
