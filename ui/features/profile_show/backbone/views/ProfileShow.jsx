//
// Copyright (C) 2012 - present Instructure, Inc.
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
import addLinkRow from '../../jst/addLinkRow.handlebars'
import AvatarWidget from '@canvas/avatar-dialog-view'
import Backbone from '@canvas/backbone'
import '@canvas/jquery/jquery.instructure_forms'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'
import React from 'react'
import ReactDOM from 'react-dom'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('user_profile')

export default class ProfileShow extends Backbone.View {
  static initClass() {
    this.prototype.el = document.body

    this.prototype.events = {
      'click [data-event]': 'handleDeclarativeClick',
      'submit #edit_profile_form': 'validateForm',
      'click #report_avatar_link': 'reportAvatarLink',
      'click #remove_avatar_link': 'removeAvatarLink',
    }

    this.prototype.attemptedDependencyLoads = 0
  }

  initialize() {
    super.initialize(...arguments)
    this.displayAlertOnSave()
    return new AvatarWidget('.profile-link')
  }

  renderAlert(message, container, variant) {
    ReactDOM.render(
      <Alert
        variant={variant}
        liveRegionPoliteness="assertive"
        liveRegion={() => document.getElementById('flash_screenreader_holder')}
        margin="small"
        timeout={5000}
      >
        {message}
      </Alert>,
      this.$el.find(container)[0]
    )
  }

  displayAlertOnSave() {
    const saveSuccessContainer = '#profile_alert_holder_success'
    const saveFailedContainer = '#profile_alert_holder_failed'
    const saveSuccessDiv = this.$el.find(saveSuccessContainer)
    const saveFailedDiv = this.$el.find(saveFailedContainer)

    if (saveSuccessDiv.length > 0) {
      this.renderAlert(
        I18n.t('Profile has been saved successfully'),
        saveSuccessContainer,
        'success'
      )
    } else if (saveFailedDiv.length > 0) {
      this.renderAlert(I18n.t('Profile save was unsuccessful'), saveFailedContainer, 'error')
    }
  }

  async removeAvatarLink(e) {
    e.preventDefault()
    const link = $(e.currentTarget)
    const result = await showConfirmationDialog({
      label: I18n.t('Confirm Removal'),
      body: I18n.t("Are you sure you want to remove this user's profile picture?"),
    })
    if (!result) {
      return
    }
    $.ajaxJSON(
      link.attr('href'),
      'PUT',
      {'avatar[state]': 'none'},
      _data => {
        $.flashMessage(I18n.t('The profile picture has been removed.'))
        $('.avatar').css('background-image', 'url()')
        link.remove()
      },
      _data => $.flashError(I18n.t('Failed to remove the image, please try again.'))
    )
  }

  async reportAvatarLink(e) {
    e.preventDefault()
    const link = $(e.currentTarget)
    const result = await showConfirmationDialog({
      label: I18n.t('Report Profile Picture'),
      body: I18n.t(
        'Reported profile pictures will be sent to administrators for review. You will not be able to undo this action.'
      ),
    })
    if (!result) {
      return
    }
    $.ajaxJSON(
      link.attr('href'),
      'POST',
      {},
      _data => {
        $.flashMessage(I18n.t('The profile picture has been reported.'))
        link.remove()
      },
      _data => $.flashError(I18n.t('Failed to report the image, please try again.'))
    )
  }

  handleDeclarativeClick(event) {
    event.preventDefault()
    const $target = $(event.currentTarget)
    const method = $target.data('event')
    if (typeof this[method] === 'function') return this[method](event, $target)
  }

  // #
  // first run initializes some stuff, then is reassigned
  // to a showEditForm
  editProfile() {
    this.initEdit()
    return (this.editProfile = this.showEditForm)
  }

  showEditForm() {
    this.$el.addClass('editing').removeClass('not-editing')
    const elementToFocus =
      document.querySelector('#name_input') || document.querySelector('#profile_bio')
    return elementToFocus.focus()
  }

  initEdit() {
    if (this.options.links && this.options.links.length) {
      for (const {title, url} of this.options.links) {
        this.addLinkField(null, null, title, url)
      }
    } else {
      this.addLinkField()
      this.addLinkField()
    }

    return this.showEditForm()
  }

  cancelEditProfile() {
    return this.$el.addClass('not-editing').removeClass('editing')
  }

  // #
  // Event handler that can also be called manually.
  // When called manually, it will focus the first input in the new row
  addLinkField(event, $el, title = '', url = '') {
    if (this.$linkFields == null) {
      this.$linkFields = this.$('#profile_link_fields')
    }
    const $row = $(addLinkRow({title, url}))
    this.$linkFields.append($row)

    // focus if called from the "add row" button
    if (event != null) {
      event.preventDefault()
      return $row.find('input:first').focus()
    }
  }

  removeLinkRow(event, $el) {
    const $parentRow = $el.parents('tr')
    let $toFocus = $parentRow.prev().find('.remove_link_row')
    if ($toFocus.length === 0) {
      $toFocus = $('#profile_bio')
    }

    $parentRow.remove()
    return $toFocus.focus()
  }

  validateForm(event) {
    const validations = {
      property_validations: {
        'user_profile[title]': function (value) {
          if (value && value.length > 255) {
            return I18n.t('profile_title_too_long', 'Title is too long')
          }
        },
        'user_profile[bio]': function (value) {
          if (value && value.length > 65536) {
            return I18n.t('profile_bio_too_long', 'Bio is too long')
          }
        },
        'link_urls[]': function (value) {
          if (value && /\s/.test(value)) {
            return I18n.t('invalid_url', 'Invalid URL')
          }
        },
      },
    }
    if (!$(event.target).validateForm(validations)) {
      return event.preventDefault()
    }
  }
}
ProfileShow.initClass()
