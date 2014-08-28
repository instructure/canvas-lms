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
  'i18n!profile'
  'jquery'
  'underscore'
  'compiled/views/DialogBaseView'
  'compiled/views/profiles/UploadFileView'
  'compiled/views/profiles/TakePictureView'
  'compiled/views/profiles/GravatarView'
  'jst/profiles/avatarDialog'
  'jst/profiles/avatar'
], (I18n, $, _, DialogBaseView, UploadFileView, TakePictureView, GravatarView, template, avatarTemplate) ->

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
      $('.select_button')
        .prop('disabled', false)
        .removeClass('ui-state-hover')
        .text(@messages.selectImage)
      super

    getImage: ->
      (@currentView || @$('.avatar-content > div:first-child').data('view')).getImage()

    updateAvatar: =>
      @disableSelectButton()
      if @currentView?.updateAvatar
        @viewUpdateAvatar()
      else
        @imageUpdateAvatar()

    disableSelectButton: ->
      $('.select_button').prop('disabled', true).text(@messages.selectingImage)

    viewUpdateAvatar: ->
      @currentView.updateAvatar().then((response) =>
        @updateDomAvatar(response.avatar_url))

    imageUpdateAvatar: ->
      $.when(@getImage(), @preflightRequest()).then(@onPreflight)

    preflightRequest: ->
      $.post('/files/pending', {
        name: 'profile.jpg'
        format: 'text'
        no_redirect: true
        'attachment[duplicate_handling]': 'overwrite'
        'attachment[folder_id]': ENV.folder_id
        'attachment[filename]': 'profile.jpg'
        'attachment[context_code]': 'user_'+ENV.current_user_id
      })

    onPreflight: (image, response) =>
      @image = image
      preflightResponse = response[0]
      @postAvatar(preflightResponse).then(_.partial(@onPostAvatar, preflightResponse))

    postAvatar: (preflightResponse) =>
      image = @image
      req   = new FormData

      delete @image

      req.append(k, v) for k, v of preflightResponse.upload_params
      req.append(preflightResponse.file_param, image, 'profile.jpg')
      dataType = if preflightResponse.success_url then 'xml' else 'json'
      $.ajax(preflightResponse.upload_url, {
        contentType: false
        data: req
        dataType: dataType
        processData: false
        type: 'POST'
      })

    onPostAvatar: (preflightResponse, postAvatarResponse) =>
      if preflightResponse.success_url
        @s3Success(preflightResponse, postAvatarResponse).then(@onS3Success)
      else
        @waitAndSaveUserAvatar(postAvatarResponse.avatar.token, postAvatarResponse.avatar.url)

    s3Success: (preflightResponse, s3Response) =>
      $s3 = $(s3Response)
      $.getJSON(preflightResponse.success_url, {
        bucket: $s3.find('Bucket').text()
        key:    $s3.find('Key').text()
        etag:   $s3.find('ETag').text()
      })

    onS3Success: (response) =>
      @waitAndSaveUserAvatar(response.avatar.token, response.avatar.url)

    # need to wait for the avatar to get processed by background jobs before
    # it will save properly.
    waitAndSaveUserAvatar: (token, url) =>
      $.getJSON('/api/v1/users/self/avatars').then((avatarList) =>
        processedAvatar = _.find(avatarList, (avatar) -> avatar.token == token)
        if processedAvatar
          @saveUserAvatar(token, url)
        else
          # throttle this a little bit
          window.setTimeout((=> @waitAndSaveUserAvatar(token, url)), 100)
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

    teardown: ->
      _.each(@children, (child) -> child.teardown())

    toJSON: ->
      hasFileReader = !!window.FileReader
      hasUserMedia = !!(navigator.getUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia || navigator.webkitGetUserMedia)
      { hasFileReader: hasFileReader, hasGetUserMedia: hasUserMedia }
