//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

// On click of the given element, display the profile picture picker dialog.

import $ from 'jquery'
import AvatarDialogView from '../views/profiles/AvatarDialogView'

export default class AvatarWidget {
  constructor (el) {
    this._openAvatarDialog = this._openAvatarDialog.bind(this)
    this.$el = $(el)
    this._attachEvents()
  }

  // Internal: Add click event to @$el to open widget.
  //
  // Returns nothing.
  _attachEvents () {
    return this.$el.on('click', this._openAvatarDialog)
  }

  // Internal: Attempt to open the avatar widget.
  //
  // e - Event object.
  //
  // Returns nothing.
  _openAvatarDialog (e) {
    if (e != null) {
      e.preventDefault()
    }
    if (!this.avatarDialog) {
      this.avatarDialog = new AvatarDialogView()
    }
    return this.avatarDialog.show()
  }
}
