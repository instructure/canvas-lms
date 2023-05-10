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
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import template from '../../jst/_sisButton.handlebars'
import SisValidationHelper from '../../SisValidationHelper'

const I18n = useI18nScope('SisButtonView')

extend(SisButtonView, Backbone.View)

function SisButtonView() {
  this.sisAttributes = this.sisAttributes.bind(this)
  this.errorsExist = this.errorsExist.bind(this)
  this.setAriaPressed = this.setAriaPressed.bind(this)
  this.togglePostToSIS = this.togglePostToSIS.bind(this)
  return SisButtonView.__super__.constructor.apply(this, arguments)
}

SisButtonView.prototype.template = template

SisButtonView.prototype.tagName = 'span'

SisButtonView.prototype.className = 'sis-button'

SisButtonView.prototype.events = {
  click: 'togglePostToSIS',
}

// {string}
// text used to describe the SIS NAME
SisButtonView.optionProperty('sisName')

// {boolean}
// boolean used to determine if due date
// is required
SisButtonView.optionProperty('dueDateRequired')

// {boolean}
// boolean used to determine if name length
// is required
SisButtonView.optionProperty('maxNameLengthRequired')

SisButtonView.prototype.setAttributes = function () {
  const newSisAttributes = this.sisAttributes()
  this.$input.attr({
    src: newSisAttributes.src,
    alt: newSisAttributes.description,
    title: newSisAttributes.description,
  })
  return this.$label.text(newSisAttributes.label)
}

SisButtonView.prototype.togglePostToSIS = function (e) {
  e.preventDefault()
  const post_to_sis = !this.model.postToSIS()
  const validationHelper = new SisValidationHelper({
    postToSIS: post_to_sis,
    dueDateRequired: this.dueDateRequired,
    dueDate: this.model.dueAt(),
    name: this.model.name(),
    maxNameLength: this.model.maxNameLength(),
    maxNameLengthRequired: this.maxNameLengthRequired,
    allDates: this.model.allDates(),
  })
  const errors = this.errorsExist(validationHelper)
  if (errors.has_error === true && this.model.sisIntegrationSettingsEnabled()) {
    return $.flashWarning(errors.message)
  } else {
    this.model.postToSIS(post_to_sis)
    const assignment_id = this.model.get('assignment_id') || this.model.get('id')
    return $.ajaxJSON(
      '/api/v1/courses/' + ENV.COURSE_ID + '/assignments/' + assignment_id,
      'PUT',
      {
        assignment: {
          override_dates: false,
          post_to_sis,
        },
      },
      (function (_this) {
        return function (data) {
          _this.model.postToSIS(data.post_to_sis)
          _this.setAttributes()
          return _this.setAriaPressed()
        }
      })(this)
    )
  }
}

SisButtonView.prototype.setAriaPressed = function () {
  const label = this.$el.find('label')
  return label.attr('aria-pressed', this.model.get('post_to_sis'))
}

SisButtonView.prototype.errorsExist = function (validationHelper) {
  const errors = {}
  const base_message = 'Unable to sync with ' + this.sisName + '.'
  if (validationHelper.dueDateMissing() && validationHelper.nameTooLong()) {
    errors.has_error = true
    errors.message = I18n.t(
      '%{base_message} Please make sure %{name} has a due date and name is not too long.',
      {
        name: this.model.name(),
        base_message,
      }
    )
  } else if (validationHelper.dueDateMissing()) {
    errors.has_error = true
    errors.message = I18n.t('%{base_message} Please make sure %{name} has a due date.', {
      name: this.model.name(),
      base_message,
    })
  } else if (validationHelper.nameTooLong()) {
    errors.has_error = true
    errors.message = I18n.t('%{base_message} Please make sure %{name} name is not too long.', {
      name: this.model.name(),
      base_message,
    })
  }
  return errors
}

SisButtonView.prototype.sisAttributes = function () {
  if (this.model.postToSIS()) {
    return {
      src: '/images/svg-icons/svg_icon_sis_synced.svg',
      description: I18n.t('Sync to %{name} enabled. Click to toggle.', {
        name: this.sisName,
      }),
      label: I18n.t('The grade for this assignment will sync to the student information system.'),
    }
  } else {
    return {
      src: '/images/svg-icons/svg_icon_sis_not_synced.svg',
      description: I18n.t('Sync to %{name} disabled. Click to toggle.', {
        name: this.sisName,
      }),
      label: I18n.t(
        'The grade for this assignment will not sync to the student information system.'
      ),
    }
  }
}

SisButtonView.prototype.render = function () {
  SisButtonView.__super__.render.apply(this, arguments)
  const labelId = 'sis-status-label-' + this.model.id
  this.$label = this.$el.find('label')
  this.$input = this.$el.find('input')
  this.$input.attr({
    'aria-describedby': labelId,
  })
  this.$label.attr('id', labelId)
  return this.setAttributes()
}

SisButtonView.prototype.toJSON = function () {
  return {
    postToSIS: this.model.postToSIS(),
  }
}

export default SisButtonView
