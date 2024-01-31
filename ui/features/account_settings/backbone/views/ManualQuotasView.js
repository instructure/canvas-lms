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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import Course from '@canvas/courses/backbone/models/Course'
import Group from '@canvas/groups/backbone/models/Group'
import ValidatedFormView from '@canvas/forms/backbone/views/ValidatedFormView'
import htmlEscape from '@instructure/html-escape'
import template from '../../jst/ManualQuotas.handlebars'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('accounts')

class ManualQuotasView extends ValidatedFormView {
  constructor(...args) {
    super(...args)
    this.findError = this.findError.bind(this)
    this.findSuccess = this.findSuccess.bind(this)
    this.INTEGER_REGEX = /^[+-]?\d+$/
  }

  initialize() {
    if (!this.events) this.events = []
    this.events['input #manual_quotas_id'] = 'validate'
    this.events['input #manual_quotas_quota'] = 'validate'
    this.events['click #manual_quotas_find_button'] = 'findItem'

    this.on('success', this.submitSuccess)
    this.on('fail', this.submitFail)
    return super.initialize(...arguments)
  }

  afterRender() {
    this.$id.keypress(e => {
      if (e.keyCode === $.ui.keyCode.ENTER) {
        return this.findItem()
      }
    })
    return this.$result.hide()
  }

  submitSuccess() {
    return $.flashMessage(I18n.t('quota_updated', 'Quota updated'))
  }

  submitFail(_errors) {
    return $.flashError(I18n.t('quota_not_updated', 'Quota was not updated'))
  }

  getFormData() {
    const data = {}
    for (const field of this.fields) {
      data[field] = this[`$${field}`].val()
    }
    return data
  }

  saveFormData() {
    return this.model.save({storage_quota_mb: this.$quota.val()}, this.saveOpts)
  }

  validateFormData(data) {
    const errors = {}

    for (const integerField of this.integerFields) {
      if (data[integerField] !== '' && !data[integerField].match(this.INTEGER_REGEX)) {
        errors[integerField] = [
          {
            type: 'integer_required',
            message: I18n.t('integer_required', 'An integer value is required'),
          },
        ]
      }
    }

    return errors
  }

  // allow invalid forms to submit (e.g. IE9 when it fails to fire the input event, which would clear the error)
  validateBeforeSave() {
    return {}
  }

  hideErrors() {
    const control_groups = this.$('div.control-group.error')
    control_groups.removeClass('error')
    return control_groups.find('.help-inline').remove()
  }

  showErrors(errors) {
    const result = []
    for (const integerField of this.integerFields) {
      const control_group = this[`$${integerField}`].closest('div.control-group')
      const messages = errors[integerField]
      control_group.toggleClass('error', messages != null)
      if (messages) {
        const $helpInline = $('<span class="help-inline"></span>')
        const html = messages.map(m => htmlEscape(m.message)).join('<br />')
        $helpInline.html(html)
        result.push(control_group.find('.controls').append($helpInline))
      } else {
        result.push(undefined)
      }
    }
    return result
  }

  findItem() {
    let path, type
    this.hideErrors()
    const data = this.getFormData()
    this.model = null

    if (data.type === 'course') {
      this.model = new Course({id: data.id})
      path = '/courses'
      type = I18n.t('course_type', 'course')
    } else if (data.type === 'group') {
      this.model = new Group({id: data.id})
      path = '/groups'
      type = I18n.t('group_type', 'group')
    }

    if (this.model) {
      this.model.urlRoot = '/api/v1' + path
      this.model.path = path
      this.model.type = type

      this.disablingDfd = new $.Deferred()
      this.$result.hide()
      this.$el.disableWhileLoading(this.disablingDfd)

      return this.model.fetch({error: this.findError, success: this.findSuccess})
    }
  }

  findError(model, error) {
    let errors
    this.disablingDfd.reject()
    this.hideErrors()

    if (error.status === 401) {
      errors = {
        id: [
          {
            type: 'not_authorized',
            message: I18n.t(
              'find_not_authorized',
              'You are not authorized to access that %{type}',
              {type: model.type}
            ),
          },
        ],
      }
    } else {
      errors = {
        id: [
          {
            type: 'not_found',
            message: I18n.t('find_not_found', 'Could not find a %{type} with that ID', {
              type: model.type,
            }),
          },
        ],
      }
    }

    return this.showErrors(errors)
  }

  findSuccess() {
    this.$link.text(this.model.get('name'))
    this.$link.attr('href', this.model.path + '/' + this.model.get('id'))

    this.$quota.val(this.model.get('storage_quota_mb'))
    this.$result.show()

    return this.disablingDfd.resolve()
  }
}

ManualQuotasView.prototype.template = template

ManualQuotasView.prototype.tag = 'form'
ManualQuotasView.prototype.id = 'manual-quotas'
ManualQuotasView.prototype.className = 'form-horizontal'

ManualQuotasView.prototype.els = {
  '#manual_quotas_type': '$type',
  '#manual_quotas_id': '$id',
  '#manual_quotas_quota': '$quota',
  '#manual_quotas_result': '$result',
  '#manual_quotas_link': '$link',
}

ManualQuotasView.prototype.fields = ['type', 'id', 'quota']
ManualQuotasView.prototype.integerFields = ['id', 'quota']

export default ManualQuotasView
