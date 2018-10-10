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

import I18n from 'i18n!user_profile'
import Backbone from 'Backbone'
import $ from 'jquery'
import addLinkRow from 'jst/profiles/addLinkRow'
import AvatarWidget from '../../util/AvatarWidget'
import 'jquery.instructure_forms'

export default class ProfileShow extends Backbone.View {
  static initClass() {
    this.prototype.el = document.body

    this.prototype.events = {
      'click [data-event]': 'handleDeclarativeClick',
      'submit #edit_profile_form': 'validateForm',
      'click .report_avatar_link': 'reportAvatarLink'
    }

    this.prototype.attemptedDependencyLoads = 0
  }

  initialize() {
    super.initialize(...arguments)
    return new AvatarWidget('.profile-link')
  }

  reportAvatarLink(e) {
    e.preventDefault()
    if (!confirm(I18n.t('Are you sure you want to report this profile picture?'))) return
    const link = $(e.currentTarget)
    $('.avatar').hide()
    return $.ajaxJSON(link.attr('href'), 'POST', {}, data => $.flashMessage(I18n.t('The profile picture has been reported')))
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
        'user_profile[title]': function(value) {
          if (value && value.length > 255) {
            return I18n.t('profile_title_too_long', 'Title is too long')
          }
        }
      }
    }
    if (!$(event.target).validateForm(validations)) {
      return event.preventDefault()
    }
  }
}
ProfileShow.initClass()
