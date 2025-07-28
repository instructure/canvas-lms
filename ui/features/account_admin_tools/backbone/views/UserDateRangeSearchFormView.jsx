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

import React from 'react'
import {createRoot} from 'react-dom/client'
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import {useScope as createI18nScope} from '@canvas/i18n'
import template from '../../jst/userDateRangeSearchForm.handlebars'
import ValidatedMixin from '@canvas/forms/backbone/views/ValidatedMixin'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/rails-flash-notifications'
import UserDateRangeSearch from '../../react/UserDateRangeSearch'

const I18n = createI18nScope('user_date_range_search')

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
          I18n.t('%{length} results found', {length: this.usersView.collection.length}),
        ),
      500,
    )
  }

  notificationsFound() {
    return $.screenReaderFlashMessage(
      I18n.t('%{length} notifications found', {length: this.collection.length}),
    )
  }

  fetchUsers() {
    this.selectUser(null)
    if (this.lastRequest != null) {
      this.lastRequest.abort()
    }
    return (this.lastRequest = this.inputFilterView.collection.fetch())
  }

  selectUser(user) {
    this.usersView.$el.find('tr').each(function () {
      $(this).removeClass('selected')
    })

    if (user) {
      this.model.set(user.attributes)
      const id = user.get('id')
      this.$userIdField.val(id)
      const self = this
      const userName = user.get('name')
      const mountPoint = document.getElementById('generate_activity_for_user_mount_point')
      const root = createRoot(mountPoint)

      const closeModal = () => {
        root.unmount()

        self.$el.find(`.roster_user_name[data-user-id=${id}]`).focus()
      }

      root.render(
        <UserDateRangeSearch
          isOpen
          userName={userName}
          onSubmit={({from, to}) => {
            self.$hiddenDateStart.val(from)
            self.$hiddenDateEnd.val(to)
            self.$el.submit()

            closeModal()
          }}
          onClose={() => closeModal()}
        />,
      )
    } else {
      return this.$userIdField.val('')
    }
  }

  submit(event) {
    event.preventDefault()
    return this.updateCollection()
  }

  updateCollection() {
    const json = this.$el.toJSON()
    delete json.search_term

    if (!json.start_time) {
      json.start_time = ''
    }

    if (!json.end_time) {
      json.end_time = ''
    }

    return this.collection.setParams(json)
  }
}
UserDateRangeSearchFormView.initClass()
