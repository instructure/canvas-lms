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

define [
  'jquery'
  'compiled/views/profiles/AvatarUploadBaseView'
  'jst/profiles/gravatarView'
  'jquery.ajaxJSON'
  'vendor/md5'
], ($, AvatarUploadBaseView, template) ->

  class GravatarView extends AvatarUploadBaseView

    @optionProperty 'avatarSize'

    template: template

    events:
      'click .gravatar-preview-btn'     : 'onPreview'
      'keydown .gravatar-preview-input' : 'onInputKeyDown'

    els:
      '.gravatar-preview-image' : '$gravatarPreviewImage'
      '.gravatar-preview-input' : '$gravatarPreviewInput'

    onPreview: (e) ->
      e.preventDefault()
      @_updatePreviewFromInput()

    onInputKeyDown: (e) ->
      if e.keyCode == 13
        e.preventDefault()
        @_updatePreviewFromInput()

    setup: ->
      primaryEmail = ENV.PROFILE?.primary_email
      if primaryEmail
        @$gravatarPreviewInput.val(primaryEmail)
        @_updatePreviewFromInput()

    updateAvatar: ->
      url = '/api/v1/users/self'
      updateParams = { 'user[avatar][url]': @_gravatarUrl(@_gravatarHashFromInput(), @avatarSize.w) }
      $.ajaxJSON(url, 'PUT', updateParams)

    getImage: ->
      throw "GravatarView does not support getImage()"

    _updatePreviewFromInput: () ->
      hash = @_gravatarHashFromInput()
      @_setGravatarPreview(@_gravatarUrl(hash))

    _gravatarHashFromInput: () ->
      email = @_prepareEmail(@$gravatarPreviewInput.val())
      CryptoJS.MD5(email)

    _gravatarUrl: (hash, size=200, fallback="identicon") ->
      "https://secure.gravatar.com/avatar/#{hash}?s=#{size}&d=#{fallback}"

    _setGravatarPreview: (url) ->
      @$gravatarPreviewImage.attr("src", url)
      @trigger('ready')

    _prepareEmail: (email) ->
      email.trim().toLowerCase()
