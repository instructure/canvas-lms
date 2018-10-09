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

import I18n from 'i18n!profile'
import $ from 'jquery'
import _ from 'underscore'
import DialogBaseView from '../DialogBaseView'
import UploadFileView from './UploadFileView'
import TakePictureView from './TakePictureView'
import GravatarView from './GravatarView'
import {completeUpload} from 'jsx/shared/upload_file'
import template from 'jst/profiles/avatarDialog'

export default class AvatarDialogView extends DialogBaseView {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.updateAvatar = this.updateAvatar.bind(this)
    this.preflightRequest = this.preflightRequest.bind(this)
    this.onPreflight = this.onPreflight.bind(this)
    this.onUploadSuccess = this.onUploadSuccess.bind(this)
    this.waitAndSaveUserAvatar = this.waitAndSaveUserAvatar.bind(this)
    this.saveUserAvatar = this.saveUserAvatar.bind(this)
    this.updateDomAvatar = this.updateDomAvatar.bind(this)
    this.checkFocusDeferred = this.checkFocusDeferred.bind(this)
    super(...args)
  }

  static initClass() {
    this.prototype.template = template

    this.prototype.AVATAR_SIZE = {
      h: 128,
      w: 128
    }

    this.child('uploadFileView', '#upload-picture')
    this.child('takePictureView', '#take-picture')
    this.child('gravatarView', '#from-gravatar')

    this.prototype.messages = {
      selectAvatar: I18n.t('buttons.select_profile_picture', 'Select Profile Picture'),
      cancel: I18n.t('#buttons.cancel', 'Cancel'),
      selectImage: I18n.t('buttons.save', 'Save'),
      selectingImage: I18n.t('buttons.selecting_image', 'Selecting Image...')
    }

    this.prototype.events = {
      'click .nav-pills a': 'onNav',
      'click .select-photo-link': 'onUploadClick',
      'change #selected-photo': 'onSelectAvatar'
    }
  }

  dialogOptions() {
    return {
      title: this.messages.selectAvatar,
      buttons: [
        {
          text: this.messages.cancel,
          click: this.cancel
        },
        {
          text: this.messages.selectImage,
          class: 'btn-primary select_button',
          click: this.updateAvatar
        }
      ],
      height: 500,
      width: 600
    }
  }

  initialize() {
    this.uploadFileView = new UploadFileView({avatarSize: this.AVATAR_SIZE})
    this.takePictureView = new TakePictureView({avatarSize: this.AVATAR_SIZE})
    this.gravatarView = new GravatarView({avatarSize: this.AVATAR_SIZE})
    return super.initialize(...arguments)
  }

  show() {
    this.render()
    _.each(this.children, child => this.listenTo(child, 'ready', this.onReady))
    this.togglePane(this.$('.nav-pills a')[0])
    return super.show(...arguments)
  }

  cancel() {
    this.teardown()
    return super.cancel(...arguments)
  }

  close() {
    this.teardown()
    this.enableSelectButton()
    return super.close(...arguments)
  }

  getImage() {
    return (this.currentView || this.$('.avatar-content > div:first-child').data('view')).getImage()
  }

  updateAvatar() {
    this.disableSelectButton()
    if (this.currentView != null ? this.currentView.updateAvatar : undefined) {
      return this.viewUpdateAvatar()
    } else {
      return this.imageUpdateAvatar()
    }
  }

  enableSelectButton() {
    $('.select_button')
      .prop('disabled', false)
      .removeClass('ui-state-hover')
      .text(this.messages.selectImage)
  }

  disableSelectButton() {
    $('.select_button')
      .prop('disabled', true)
      .text(this.messages.selectingImage)
  }

  viewUpdateAvatar() {
    return this.currentView.updateAvatar().then(response => {
      return this.updateDomAvatar(response.avatar_url)
    })
  }

  imageUpdateAvatar() {
    return $.when(this.getImage(), this.preflightRequest()).then(this.onPreflight)
  }

  handleErrorUpdating(response) {
    if (response) {
      // try to get an error message out of JSON string
      const errors = (() => {
        try {
          return JSON.parse(response).errors
        } catch (error) {
          return undefined
        }
      })()

      if (errors) {
        const errorReducer = (errorString, currentError) => (errorString += currentError.message)

        const message = _.isString(errors.base)
          ? errors.base
          : _.isArray(errors.base)
            ? errors.base.reduce(errorReducer, '')
            : I18n.t(
                'Your profile photo could not be uploaded. You may have exceeded your upload limit.'
              )

        $.flashError(message)
        return this.enableSelectButton()
      }
    }
  }

  preflightRequest() {
    // not using uploader.uploadFile because need to have completeUpload also
    // wait on @getImage in imageUpdateAvatar
    return $.post('/files/pending', {
      name: 'profile.jpg',
      format: 'text',
      no_redirect: true,
      'attachment[on_duplicate]': 'overwrite',
      'attachment[folder_id]': ENV.folder_id,
      'attachment[filename]': 'profile.jpg',
      'attachment[context_code]': `user_${ENV.current_user_id}`
    }).fail(xhr => this.handleErrorUpdating(xhr.responseText))
  }

  onPreflight(image, response) {
    const preflight = response[0]
    return completeUpload(preflight, image, {filename: 'profile.jpg', includeAvatar: true})
      .then(this.onUploadSuccess)
      .catch(xhr => this.handleErrorUpdating(xhr.responseText))
  }

  onUploadSuccess(response) {
    return this.waitAndSaveUserAvatar(response.avatar.token, response.avatar.url, 0)
  }

  // need to wait for the avatar to get processed by background jobs before
  // it will save properly.
  // wait 5 seconds and then error out
  waitAndSaveUserAvatar(token, url, count) {
    return $.getJSON('/api/v1/users/self/avatars').then(avatarList => {
      const processedAvatar = _.find(avatarList, avatar => avatar.token === token)
      if (processedAvatar) {
        return this.saveUserAvatar(token, url)
      } else if (count < 50) {
        return window.setTimeout(() => this.waitAndSaveUserAvatar(token, url, count + 1), 100)
      } else {
        return this.handleErrorUpdating(
          JSON.stringify({
            errors: {
              base: I18n.t('Profile photo save failed too many times')
            }
          })
        )
      }
    })
  }

  saveUserAvatar(token, url) {
    return $.ajax('/api/v1/users/self', {
      data: {'user[avatar][token]': token},
      dataType: 'json',
      type: 'PUT'
    }).then(_.partial(this.updateDomAvatar, url))
  }

  updateDomAvatar(url) {
    $('.profile_pic_link, .profile-link').css('background-image', `url('${url}')`)
    return this.close()
  }

  onNav(e) {
    e.preventDefault()
    return this.togglePane(e.target)
  }

  togglePane(link) {
    const $target = this.$(link).parent()
    const $content = this.$(link.getAttribute('href'))
    $target.siblings().removeClass('active')
    $target.addClass('active')
    this.teardown()
    $('.select_button').prop('disabled', true)
    this.$('.avatar-content div').removeClass('active')
    __guard__($content.addClass('active').data('view'), x => x.setup())
    return (this.currentView = $content.data('view'))
  }

  onReady(ready = true) {
    $('.select_button').prop('disabled', !ready)
    return this.checkFocus()
  }

  checkFocus() {
    // deferring this makes it work more reliably because in some cases (like
    // visibility updates) the focus isn't lost immediately.
    return _.defer(this.checkFocusDeferred)
  }

  checkFocusDeferred() {
    if (
      !$.contains(this.$el[0], document.activeElement) ||
      !$(document.activeElement).is(':visible')
    ) {
      $('.ui-dialog-titlebar-close').focus()
    }
  }

  teardown() {
    return _.each(this.children, child => child.teardown())
  }

  toJSON() {
    const hasFileReader = !!window.FileReader
    const hasUserMedia = !!(
      navigator.getUserMedia ||
      navigator.mozGetUserMedia ||
      navigator.msGetUserMedia ||
      navigator.webkitGetUserMedia
    )
    return {hasFileReader, hasGetUserMedia: hasUserMedia, enableGravatar: ENV.enable_gravatar}
  }
}
AvatarDialogView.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
