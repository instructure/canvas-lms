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

define ['jquery', 'compiled/util/ProximityLoader'], ($, ProximityLoader) ->

  class AvatarWidget

    # Internal: Number of attempts to display widget before script has loaded.
    _attemptedLoads: 0

    constructor: (el) ->
      @$el = $(el)
      @_initializeLoader()
      @_attachEvents()

    # Internal: Add click event to @$el to open widget.
    #
    # Returns nothing.
    _attachEvents: ->
      @$el.on('click', @_openAvatarDialog)

    # Internal: Create a new ProximityLoader to handle script loading.
    #
    # Returns nothing.
    _initializeLoader: ->
      @loader = new ProximityLoader @$el,
        callback: @_initializeDialog
        dependencies: ['compiled/views/profiles/AvatarDialogView']

    # Internal: Create/cache an instance of AvatarDialogView.
    #
    # AvatarDialogView - The AvatarDialogView class.
    #
    # Returns an AvatarDialogView.
    _initializeDialog: (AvatarDialogView) =>
      @avatarDialog = new AvatarDialogView

    # Internal: Attempt to open the avatar widget.
    #
    # e - Event object.
    #
    # Returns nothing.
    _openAvatarDialog: (e) =>
      e?.preventDefault()

      if typeof @avatarDialog isnt 'undefined'
        @avatarDialog.show()
      else
        @_pollScriptLoad()

    # Internal: Determine how long we've waited for the Avatar scripts to load.
    #
    # Returns nothing (or throws exception at 2s mark).
    _pollScriptLoad: ->
      @loader.deferred.resolve()

      if @_attemptedLoads < 20
        @_attemptedLoads++
        setTimeout(@_openAvatarDialog, 100)
      else
        throw new Error('Failed to load AvatarDialogView')
