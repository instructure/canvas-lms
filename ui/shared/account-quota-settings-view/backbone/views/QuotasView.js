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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import ValidatedFormView from '@canvas/forms/backbone/views/ValidatedFormView'
import htmlEscape from '@instructure/html-escape'
import template from '../../jst/Quotas.handlebars'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('accounts')

extend(QuotasView, ValidatedFormView)

function QuotasView() {
  return QuotasView.__super__.constructor.apply(this, arguments)
}

QuotasView.prototype.template = template

QuotasView.INTEGER_REGEX = /^[+-]?\d+$/

QuotasView.prototype.tag = 'form'

QuotasView.prototype.id = 'default-quotas'

QuotasView.prototype.className = 'form-horizontal account_settings'

QuotasView.prototype.integerFields = [
  'default_storage_quota_mb',
  'default_user_storage_quota_mb',
  'default_group_storage_quota_mb',
]

QuotasView.prototype.events = {
  submit: 'submit',
}

QuotasView.prototype.initialize = function () {
  this.events || (this.events = [])
  this.els || (this.els = [])
  const ref = this.integerFields
  for (let i = 0, len = ref.length; i < len; i++) {
    const integerField = ref[i]
    this.events['input [name="' + integerField + '"]'] = 'validate'
    this.els['[name="' + integerField + '"]'] = '$' + integerField
  }
  this.on('success', this.submitSuccess)
  this.on('fail', this.submitFail)
  return QuotasView.__super__.initialize.apply(this, arguments)
}

QuotasView.prototype.toJSON = function () {
  const data = QuotasView.__super__.toJSON.apply(this, arguments)
  data.root_account = this.model.get('root_account')
  return data
}

QuotasView.prototype.submitSuccess = function () {
  return $.flashMessage(I18n.t('default_account_quotas_updated', 'Default account quotas updated'))
}

QuotasView.prototype.submitFail = function (errors) {
  let unknownFailure = true
  const ref = this.integerFields
  for (let i = 0, len = ref.length; i < len; i++) {
    const integerField = ref[i]
    if (integerField in errors) {
      unknownFailure = false
    }
  }
  if (unknownFailure) {
    return $.flashError(
      I18n.t('default_account_quotas_not_updated', 'Default account quotas were not updated')
    )
  }
}

QuotasView.prototype.validateFormData = function (data) {
  const errors = {}
  const ref = this.integerFields
  for (let i = 0, len = ref.length; i < len; i++) {
    const integerField = ref[i]
    if (typeof data[integerField] !== 'undefined') {
      if (!data[integerField].match(this.constructor.INTEGER_REGEX)) {
        errors[integerField] = [
          {
            type: 'integer_required',
            message: I18n.t('integer_required', 'An integer value is required'),
          },
        ]
      }
    }
  }
  return errors
}

QuotasView.prototype.validateBeforeSave = function () {
  return {}
}

QuotasView.prototype.hideErrors = function () {
  const control_groups = this.$('div.control-group.error')
  control_groups.removeClass('error')
  return control_groups.find('.help-inline').remove()
}

QuotasView.prototype.showErrors = function (errors) {
  const ref = this.integerFields
  const results = []
  for (let i = 0, len = ref.length; i < len; i++) {
    const integerField = ref[i]
    const control_group = this['$' + integerField].closest('div.control-group')
    const messages = errors[integerField]
    control_group.toggleClass('error', messages != null)
    let html
    if (messages) {
      const $helpInline = $('<span class="help-inline"></span>')
      html = (function () {
        const results1 = []
        for (let j = 0, len1 = messages.length; j < len1; j++) {
          const message = messages[j].message
          results1.push(htmlEscape(message))
        }
        return results1
      })().join('<br/>')
      $helpInline.html(html)
      results.push(control_group.find('.controls').append($helpInline))
    } else {
      results.push(void 0)
    }
  }
  return results
}

export default QuotasView
