/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@canvas/backbone'
import CollaboratorPickerView from './CollaboratorPickerView'

const I18n = useI18nScope('collaborations')

extend(CollaborationFormView, View)

function CollaborationFormView() {
  return CollaborationFormView.__super__.constructor.apply(this, arguments)
}

CollaborationFormView.prototype.translations = {
  errors: {
    noName: I18n.t('errors.no_name', 'Please enter a name for this collaboration.'),
    titleTooLong: I18n.t(
      'errors.title_too_long',
      'Please use %{maxLength} characters or less for the name. Use the description for additional content.',
      {
        maxLength: ENV.TITLE_MAX_LEN,
      }
    ),
  },
}

CollaborationFormView.prototype.events = {
  submit: 'onSubmit',
  'click .cancel_button': 'onCancel',
  keydown: 'onKeydown',
}

CollaborationFormView.prototype.initialize = function () {
  CollaborationFormView.__super__.initialize.apply(this, arguments)
  this.cacheElements()
  this.picker = new CollaboratorPickerView({
    el: this.$collaborators,
  })
  return (this.titleMaxLength = ENV.TITLE_MAX_LEN)
}

CollaborationFormView.prototype.cacheElements = function () {
  this.$titleInput = this.$el.find('#collaboration_title')
  return (this.$collaborators = this.$el.find('.collaborator_list'))
}

CollaborationFormView.prototype.render = function (focus) {
  if (focus == null) {
    focus = true
  }
  this.$el.show()
  if (focus) {
    this.$el.find('[name="collaboration[collaboration_type]"]').focus()
  }
  if (this.$collaborators.is(':empty')) {
    this.picker.render()
  }
  return this
}

CollaborationFormView.prototype.onSubmit = function (e) {
  const data = this.$el.getFormData()
  if (!data['collaboration[title]']) {
    e.preventDefault()
    e.stopPropagation()
    return this.raiseTitleError()
  }
  if (this.titleMaxLength && data['collaboration[title]'].length > this.titleMaxLength) {
    e.preventDefault()
    e.stopPropagation()
    return this.raiseTitleLengthError()
  }
  return setTimeout(function () {
    return (window.location = window.location.pathname)
  }, 2500)
}

CollaborationFormView.prototype.onCancel = function (e) {
  e.preventDefault()
  this.$el.hide()
  return this.trigger('hide')
}

CollaborationFormView.prototype.onKeydown = function (e) {
  if (e.which === 27) {
    return this.onCancel(e)
  }
}

CollaborationFormView.prototype.raiseTitleError = function () {
  this.trigger('error', this.$titleInput, this.translations.errors.noName)
  return false
}

CollaborationFormView.prototype.raiseTitleLengthError = function () {
  this.trigger('error', this.$titleInput, this.translations.errors.titleTooLong)
  return false
}

export default CollaborationFormView
