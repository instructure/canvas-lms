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
  'jst/profiles/avatarDialog'
  'jst/profiles/avatar'
  'compiled/util/BackoffPoller'
], (I18n, $, _, DialogBaseView, template, avatarTemplate, BackoffPoller) ->

  # NOTE: This class was pulled (almost) wholesale from profile.js, bugs
  # and all. Notable changes include:
  #
  #   * Pulling HTML generation into handlebars templates;
  #   * Replacing inline event assignment w/ Backbone events;
  #   * Replacing inline I18n calls with a global hash;
  #   * Caching (some) DOM lookups;
  #   * Removing manual $.dialog calls in favor of DialogBaseView.
  class AvatarDialogView extends DialogBaseView

    template: template

    url: '/api/v1/users/self/avatars'

    pollThumbnails: false

    events:
      'click .img': 'selectAvatar'
      'click .add_pic_link': 'toggleAddForm'

    els:
      '#add_pic_form': '$form'

    messages:
      cancel:         I18n.t('#buttons.cancel', 'Cancel')
      selectImage:    I18n.t('buttons.select_image', 'Select Image')
      selectProfile:  I18n.t('titles.select_profile_pic', 'Select Profile Pic')
      selectingImage: I18n.t('buttons.selecting_image', 'Selecting Image...')
      selectImage:    I18n.t('buttons.select_image', 'Select Image')
      addingFile:     I18n.t('buttons.adding_file', 'Adding File...')
      addFile:        I18n.t('buttons.add_file', 'Add File')
      addFailed:      I18n.t('errors.adding_file_failed', 'Adding File Failed')

    dialogOptions: ->
      buttons: [
        text: @messages.cancel
        click: @cancel
      ,
        text: @messages.selectImage
        class: 'btn-primary select_button'
        click: @updateAvatar
      ]
      height: 300
      title: @messages.selectProfile
      width: 500

    initialize: ->
      @thumbnailPoller = new BackoffPoller(@url, @onPoll)
      super

    show: ->
      @initContent() unless @rendered
      @selectButton().prop('disabled', true)
      super

    initContent: ->
      @loadAvatars()
      @render()
      @initializeForm()
      @rendered = true

    loadAvatars: ->
      $.ajaxJSON(@url, 'GET', {}, @onAvatarLoad)

    onPoll: (data) =>
      loadedImages = {}
      $images = @$el.find('img.pending')
      count = 0
      (loadedImages[avatar.token] = avatar.url unless avatar.pending) for avatar in data
      $images.each ->
        $image = $(this)
        associatedUrl = loadedImages[$image.data('token')]
        if associatedUrl isnt null
          $image.removeClass('pending').attr('src', associatedUrl)
          count++
      return 'stop' if count is $images.length
      return 'reset' if count > 0
      return 'continue'

    onAvatarLoad: (avatars) =>
      return unless avatars?.length
      @$el.addClass('loaded').find('h3').remove()
      @drawAvatar(avatar) for avatar in avatars
      @thumbnailPoller.start() if @pollThumbnails

    drawAvatar: (avatar) ->
      binding = _.extend({classNames: ''}, avatar)
      if avatar.pending
        binding.classNames = 'pending'
        binding.url        = '/images/ajax-loader.gif'
      binding.alt = binding.title = avatar.display_name or avatar.type
      $result = $(avatarTemplate(binding))
      $result.find('img')[0].onerror = $result.remove.bind($result, null)
      @$el.find('.profile_pic_list .clear').before($result)

    selectAvatar: (e) ->
      return if /pending/.test(e.target.className)
      @$el.find('.img.selected').removeClass('selected')
      $(e.currentTarget).addClass('selected')
      @selectButton().prop('disabled', false)

    updateAvatar: (e) =>
      url    = '/api/v1/users/self'
      $image = @$el.find('.selected img')
      data   = { 'user[avatar][token]': $image.data('token') }
      @selectButton().prop('disabled', true).text(@messages.selectingImage)
      return unless $image.length
      $.ajaxJSON(url, 'PUT', data, @onUpdate)

    onUpdate: (user) =>
      profilePicLink = $('.profile_pic_link img, .profile-link img')
      newSrc         = @$el.find('.selected img').attr('src')
      @selectButton().prop('disabled', false).text(@messages.selectImage)
      user.avatar_url = '/images/dotted_pic.png' if user.avatar_url is '/images/no_pic.gif'
      profilePicLink.attr('src', newSrc)
      @close()

    selectButton: ->
      @$selectButton or= @$el.parent().find('.select_button')

    addFileButton: ->
      @$addFileButton or= @$form.find('button')

    initializeForm: ->
      @$form.formSubmit
        fileUpload: true
        fileUploadOptions:
          preparedFileUpload: true
          upload_only: true
          singleFile: true
          context_code: ENV.context_asset_string
          folder_id: ENV.folder_id
          formDataTarget: 'uploadDataUrl'
        object_name: 'attachment'
        required: ['uploaded_data']
        beforeSubmit: =>
          @addFileButton().prop('disabled', true).text(@messages.addingFile)
          $span  = $('<span class="img"><img alt="" /></span>')
          $image = $span.find('img').attr('src', '/images/ajax-loader.gif')
          $image.addClass('pending')
          @$el.find('.profile_pic_list .clear').before($span)
          $span
        success: (data, $span) =>
          {attachment, avatar} = data
          @addFileButton().prop('disabled', false).text(@messages.addFile)
          if $span
            $image = $span.find('img')
            $image.data(type: 'attachment', token: avatar.token).attr('alt', attachment.display_name)
            $image[0].onerror = -> $image.attr('src', '/images/dotted_pic.png')
            @thumbnailPoller.start().then(-> $image.click())
        error: (data, $span) =>
          @addFileButton().prop('disabled', false).text(@messages.addFailed)
          $span.remove() if $span

    toggleAddForm: (e) ->
      @$form.slideToggle()
