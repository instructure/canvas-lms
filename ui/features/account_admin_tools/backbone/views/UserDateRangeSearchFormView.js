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

import Backbone from '@canvas/backbone'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import template from '../../jst/userDateRangeSearchForm.handlebars'
import ValidatedMixin from '@canvas/forms/backbone/views/ValidatedMixin'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/datetime/jquery'
import 'jqueryui/dialog'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('user_date_range_search')

export default class UserDateRangeSearchFormView extends Backbone.View {
  static initClass() {
    this.mixin(ValidatedMixin)

    this.child('inputFilterView', '[data-view=inputFilter]')
    this.child('usersView', '[data-view=users]')

    this.prototype.tagName = 'form'

    this.prototype.template = template

    this.prototype.events = {submit: 'submit'}

    this.prototype.els = {
      '.userIdField': '$userIdField',
      '.hiddenDateStart': '$hiddenDateStart',
      '.hiddenDateEnd': '$hiddenDateEnd',
      '.dateStartSearchField': '$dateStartSearchField',
      '.dateEndSearchField': '$dateEndSearchField',
      '.search-controls': '$searchControls',
      '.search-people-status': '$searchPeopleStatus',
    }

    this.optionProperty('formName')
  }

  toJSON() {
    return this.options
  }

  initialize(options) {
    this.model = new Backbone.Model()
    return super.initialize(options)
  }

  // Setup the date inputs for javascript use.
  afterRender() {
    this.$dateStartSearchField.datetime_field()
    this.$dateEndSearchField.datetime_field()
    return this.$searchControls.hide()
  }

  attach() {
    this.inputFilterView.collection.on('setParam deleteParam', this.fetchUsers.bind(this))
    this.usersView.collection.on('selectedModelChange', this.selectUser.bind(this))
    this.usersView.collection.on('sync', this.resultsFound.bind(this))
    return this.collection.on('sync', this.notificationsFound.bind(this))
  }

  resultsFound() {
    return setTimeout(
      () =>
        $.screenReaderFlashMessageExclusive(
          I18n.t('%{length} results found', {length: this.usersView.collection.length})
        ),
      500
    )
  }

  notificationsFound() {
    return $.screenReaderFlashMessage(
      I18n.t('%{length} notifications found', {length: this.collection.length})
    )
  }

  fetchUsers() {
    this.selectUser(null)
    if (this.lastRequest != null) {
      this.lastRequest.abort()
    }
    return (this.lastRequest = this.inputFilterView.collection.fetch())
  }

  selectUser(e) {
    this.usersView.$el.find('tr').each(function () {
      $(this).removeClass('selected')
    })
    if (e) {
      this.model.set(e.attributes)
      const id = e.get('id')
      this.$userIdField.val(id)
      const self = this
      return this.$searchControls.show().dialog({
        title: I18n.t('Generate Activity for %{user}', {user: e.get('name')}),
        resizable: false,
        height: 'auto',
        width: 400,
        modal: true,
        zIndex: 1000,
        dialogClass: 'userDateRangeSearchModal',
        close() {
          return self.$el.find(`.roster_user_name[data-user-id=${id}]`).focus()
        },
        buttons: [
          {
            text: I18n.t('Cancel'),
            click() {
              $(this).dialog('close')
            },
          },
          {
            text: I18n.t('Find'),
            class: 'btn btn-primary userDateRangeSearchBtn',
            id: `${self.formName}-find-button`,
            click() {
              const errors = self.datesValidation()
              if (Object.keys(errors).length !== 0) {
                self.showErrors(errors, true)
                return
              }

              self.$hiddenDateStart.val(self.$dateStartSearchField.val())
              self.$hiddenDateEnd.val(self.$dateEndSearchField.val())
              self.$el.submit()
              $(this).dialog('close')
            },
          },
        ],
      })
    } else {
      return this.$userIdField.val('')
    }
  }

  dateIsValid(dateField) {
    if (dateField.val() === '') {
      return true
    }
    const date = dateField.data('unfudged-date')
    return date instanceof Date && !Number.isNaN(Number(date.valueOf()))
  }

  datesValidation() {
    const errors = {}
    const startDateField = this.$dateStartSearchField
    const endDateField = this.$dateEndSearchField
    const startDate = startDateField.data('unfudged-date')
    const endDate = endDateField.data('unfudged-date')

    if (startDate && endDate && startDate > endDate) {
      errors[`${this.formName}_end_time`] = [
        {
          message: I18n.t('To Date cannot come before From Date'),
        },
      ]
    } else {
      if (!this.dateIsValid(startDateField)) {
        errors[`${this.formName}_start_time`] = [
          {
            message: I18n.t('Not a valid date'),
          },
        ]
      }
      if (!this.dateIsValid(endDateField)) {
        errors[`${this.formName}_end_time`] = [
          {
            message: I18n.t('Not a valid date'),
          },
        ]
      }
    }
    return errors
  }

  submit(event) {
    event.preventDefault()
    return this.updateCollection()
  }

  updateCollection() {
    // Update the params (which fetches the collection)
    const json = this.$el.toJSON()
    delete json.search_term

    if (!json.start_time) {
      json.start_time = ''
    } else {
      json.start_time = new Date(this.$dateStartSearchField.data('unfudged-date')).toISOString()
    }
    if (!json.end_time) {
      json.end_time = ''
    } else {
      json.end_time = new Date(this.$dateEndSearchField.data('unfudged-date')).toISOString()
    }

    return this.collection.setParams(json)
  }
}
UserDateRangeSearchFormView.initClass()
