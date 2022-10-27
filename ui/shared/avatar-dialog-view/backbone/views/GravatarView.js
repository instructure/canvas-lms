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

import $ from 'jquery'
import AvatarUploadBaseView from './AvatarUploadBaseView'
import template from '../../jst/gravatarView.handlebars'
import md5 from 'md5'
import '@canvas/jquery/jquery.ajaxJSON'

export default class GravatarView extends AvatarUploadBaseView {
  static initClass() {
    this.optionProperty('avatarSize')

    this.prototype.template = template

    this.prototype.events = {
      'click .gravatar-preview-btn': 'onPreview',
      'keydown .gravatar-preview-input': 'onInputKeyDown',
    }

    this.prototype.els = {
      '.gravatar-preview-image': '$gravatarPreviewImage',
      '.gravatar-preview-input': '$gravatarPreviewInput',
    }
  }

  onPreview(e) {
    e.preventDefault()
    return this._updatePreviewFromInput()
  }

  onInputKeyDown(e) {
    if (e.keyCode === 13) {
      e.preventDefault()
      return this._updatePreviewFromInput()
    }
  }

  setup() {
    const primaryEmail = ENV.PROFILE != null ? ENV.PROFILE.primary_email : undefined
    if (primaryEmail) {
      this.$gravatarPreviewInput.val(primaryEmail)
      return this._updatePreviewFromInput()
    }
  }

  updateAvatar() {
    const url = '/api/v1/users/self'
    const updateParams = {
      'user[avatar][url]': this._gravatarUrl(this._gravatarHashFromInput(), this.avatarSize.w),
    }
    return $.ajaxJSON(url, 'PUT', updateParams)
  }

  getImage() {
    throw new Error('GravatarView does not support getImage()')
  }

  _updatePreviewFromInput() {
    const hash = this._gravatarHashFromInput()
    return this._setGravatarPreview(this._gravatarUrl(hash))
  }

  _gravatarHashFromInput() {
    const email = this._prepareEmail(this.$gravatarPreviewInput.val())
    return md5(email)
  }

  _gravatarUrl(hash, size = 200, fallback = 'identicon') {
    return `https://secure.gravatar.com/avatar/${hash}?s=${size}&d=${fallback}`
  }

  _setGravatarPreview(url) {
    this.$gravatarPreviewImage.attr('src', url)
    return this.trigger('ready')
  }

  _prepareEmail(email) {
    return email.trim().toLowerCase()
  }
}
GravatarView.initClass()
