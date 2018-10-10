#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'i18n!profile'
  'jquery'
  'underscore'
  '../DialogBaseView'
  './UploadFileView'
  './TakePictureView'
  './GravatarView'
  'jsx/shared/upload_file'
  'jst/profiles/avatarDialog'
  'jst/profiles/avatar'
], (I18n, $, _, DialogBaseView, UploadFileView, TakePictureView, GravatarView, uploader, template, avatarTemplate) ->

  class AvatarDialogView extends DialogBaseView

    template: template

    AVATAR_SIZE:
      h: 128
      w: 128

    @child 'uploadFileView',  '#upload-picture'
    @child 'takePictureView', '#take-picture'
    @child 'gravatarView', '#from-gravatar'

    dialogOptions: ->
      title: @messages.selectAvatar
      buttons: [
        text: @messages.cancel
        click: @cancel
      ,
        text: @messages.selectImage
        class: 'btn-primary select_button'
        click: @updateAvatar
      ]
      height: 500
      width: 600

    messages:
      selectAvatar:    I18n.t('buttons.select_profile_picture', 'Select Profile Picture')
      cancel:         I18n.t('#buttons.cancel', 'Cancel')
      selectImage:    I18n.t('buttons.save', 'Save')
      selectingImage: I18n.t('buttons.selecting_image', 'Selecting Image...')

    events:
      'click .nav-pills a'       : 'onNav'
      'click .select-photo-link' : 'onUploadClick'
      'change #selected-photo'   : 'onSelectAvatar'

    initialize: () ->
      @uploadFileView = new UploadFileView(avatarSize: @AVATAR_SIZE)
      @takePictureView = new TakePictureView(avatarSize: @AVATAR_SIZE)
      @gravatarView   = new GravatarView(avatarSize: @AVATAR_SIZE)
      super

    show: ->
      @render()
      _.each(@children, (child) => @listenTo(child, 'ready', @onReady))
      @togglePane(@$('.nav-pills a')[0])
      super

    cancel: ->
      @teardown()
      super

    close: ->
      @teardown()
      @enableSelectButton()
      super

    getImage: ->
      (@currentView || @$('.avatar-content > div:first-child').data('view')).getImage()

    updateAvatar: =>
      @disableSelectButton()
      if @currentView?.updateAvatar
        @viewUpdateAvatar()
      else
        @imageUpdateAvatar()

    enableSelectButton: ->
      $('.select_button')
        .prop('disabled', false)
        .removeClass('ui-state-hover')
        .text(@messages.selectImage)

    disableSelectButton: ->
      $('.select_button').prop('disabled', true).text(@messages.selectingImage)

    viewUpdateAvatar: ->
      @currentView.updateAvatar().then((response) =>
        @updateDomAvatar(response.avatar_url))

    imageUpdateAvatar: ->
      $.when(@getImage(), @preflightRequest()).then(@onPreflight)

    handleErrorUpdating: (response) ->
      if (response)
        # try to get an error message out of JSON string
        errors = try
          JSON.parse(response).errors
        catch error
          undefined

        if errors
          errorReducer = (errorString, currentError) ->
            errorString += currentError.message

          message = if _.isString(errors.base)
            errors.base
          else if _.isArray(errors.base)
            errors.base.reduce(errorReducer, '')
          else
            I18n.t('Your profile photo could not be uploaded. You may have exceeded your upload limit.')

          $.flashError(message)
          @enableSelectButton()

    preflightRequest: =>
      # not using uploader.uploadFile because need to have completeUpload also
      # wait on @getImage in imageUpdateAvatar
      $.post('/files/pending', {
        name: 'profile.jpg'
        format: 'text'
        no_redirect: true
        'attachment[on_duplicate]': 'overwrite'
        'attachment[folder_id]': ENV.folder_id
        'attachment[filename]': 'profile.jpg'
        'attachment[context_code]': 'user_'+ENV.current_user_id
      }).fail((xhr) => @handleErrorUpdating(xhr.responseText))

    onPreflight: (image, response) =>
      preflight = response[0]
      uploader.completeUpload(preflight, image, filename: 'profile.jpg', includeAvatar: true)
        .then(@onUploadSuccess)
        .catch((xhr) => @handleErrorUpdating(xhr.responseText))

    onUploadSuccess: (response) =>
      @waitAndSaveUserAvatar(response.avatar.token, response.avatar.url, 0)

    # need to wait for the avatar to get processed by background jobs before
    # it will save properly.
    # wait 5 seconds and then error out
    waitAndSaveUserAvatar: (token, url, count) =>
      $.getJSON('/api/v1/users/self/avatars').then((avatarList) =>
        processedAvatar = _.find(avatarList, (avatar) -> avatar.token == token)
        if processedAvatar
          @saveUserAvatar(token, url)
        else if count < 50
          window.setTimeout((=> @waitAndSaveUserAvatar(token, url, count + 1)), 100)
        else
          @handleErrorUpdating(JSON.stringify({
            errors: { 
              base: I18n.t("Profile photo save failed too many times")
            }
          }))
      )

    saveUserAvatar: (token, url) =>
      $.ajax('/api/v1/users/self', {
        data: { 'user[avatar][token]': token }
        dataType: 'json'
        type: 'PUT'
      }).then(_.partial(@updateDomAvatar, url))

    updateDomAvatar: (url) =>
      $('.profile_pic_link, .profile-link')
        .css('background-image', "url('#{url}')")
      @close()

    onNav: (e) ->
      e.preventDefault()
      @togglePane(e.target)

    togglePane: (link) ->
      $target  = @$(link).parent()
      $content = @$(link.getAttribute('href'))
      $target.siblings().removeClass('active')
      $target.addClass('active')
      @teardown()
      $('.select_button').prop('disabled', true)
      @$('.avatar-content div').removeClass('active')
      $content.addClass('active').data('view')?.setup()
      @currentView = $content.data('view')

    onReady: (ready = true) ->
      $('.select_button').prop('disabled', !ready)
      @checkFocus()

    checkFocus: () ->
      # deferring this makes it work more reliably because in some cases (like
      # visibility updates) the focus isn't lost immediately.
      _.defer(@checkFocusDeferred)

    checkFocusDeferred: () =>
      unless $.contains(@$el[0], document.activeElement) && $(document.activeElement).is(':visible')
        $('.ui-dialog-titlebar-close').focus()

    teardown: ->
      _.each(@children, (child) -> child.teardown())

    toJSON: ->
      hasFileReader = !!window.FileReader
      hasUserMedia = !!(navigator.getUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia || navigator.webkitGetUserMedia)
      { hasFileReader: hasFileReader, hasGetUserMedia: hasUserMedia, enableGravatar: ENV.enable_gravatar }
