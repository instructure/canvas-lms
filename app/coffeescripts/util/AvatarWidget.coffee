#
# Copyright (C) 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# On click of the given element, display the profile picture picker dialog.

define ['jquery', 'compiled/views/profiles/AvatarDialogView'], ($, AvatarDialogView) ->

  class AvatarWidget

    constructor: (el) ->
      @$el = $(el)
      @_attachEvents()

    # Internal: Add click event to @$el to open widget.
    #
    # Returns nothing.
    _attachEvents: ->
      @$el.on('click', @_openAvatarDialog)

    # Internal: Attempt to open the avatar widget.
    #
    # e - Event object.
    #
    # Returns nothing.
    _openAvatarDialog: (e) =>
      e?.preventDefault()
      if(!@avatarDialog)
        @avatarDialog = new AvatarDialogView
      @avatarDialog.show()
