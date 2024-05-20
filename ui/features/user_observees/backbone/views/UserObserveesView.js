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
import $ from 'jquery'
import {extend as lodashExtend} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import pairingCodeTemplate from '../../jst/PairingCodeUserObservees.handlebars'
import itemView from './UserObserveeView'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import '@canvas/jquery/jquery.disableWhileLoading'
import {clearObservedId, savedObservedId} from '@canvas/observer-picker/ObserverGetObservee'

const I18n = useI18nScope('observees')

extend(UserObserveesView, PaginatedCollectionView)

function UserObserveesView() {
  this.checkEmpty = this.checkEmpty.bind(this)
  return UserObserveesView.__super__.constructor.apply(this, arguments)
}

UserObserveesView.prototype.autoFetch = true

UserObserveesView.prototype.itemView = itemView

UserObserveesView.prototype.className = 'user-observees'

UserObserveesView.prototype.template = pairingCodeTemplate

UserObserveesView.prototype.events = {
  'submit .add-observee-form': 'addObservee',
  'click .remove-observee': 'removeObservee',
}

UserObserveesView.prototype.els = lodashExtend({}, PaginatedCollectionView.prototype.els, {
  '.add-observee-form': '$form',
})

UserObserveesView.prototype.initialize = function () {
  UserObserveesView.__super__.initialize.apply(this, arguments)
  this.collection.on(
    'beforeFetch',
    (function (_this) {
      return function () {
        return _this.setLoading(true)
      }
    })(this)
  )
  this.collection.on(
    'fetch',
    (function (_this) {
      return function () {
        return _this.setLoading(false)
      }
    })(this)
  )
  this.collection.on(
    'fetched:last',
    (function (_this) {
      return function () {
        return _this.checkEmpty()
      }
    })(this)
  )
  return this.collection.on(
    'remove',
    (function (_this) {
      return function () {
        return _this.checkEmpty()
      }
    })(this)
  )
}

UserObserveesView.prototype.checkEmpty = function () {
  if (this.collection.size() === 0) {
    return $('<em>')
      .text(I18n.t('No students being observed'))
      .appendTo(this.$('.observees-list-container'))
  }
}

UserObserveesView.prototype.addObservee = function (ev) {
  ev.preventDefault()
  const data = this.$form.getFormData()
  const d = $.post(this.collection.url(), data)
  d.done(
    (function (_this) {
      return function (model) {
        if (model.redirect) {
          if (
            // eslint-disable-next-line no-alert
            window.confirm(
              I18n.t(
                "In order to complete the process you will be redirected to a login page where you will need to log in with your child's credentials."
              )
            )
          ) {
            return (window.location = model.redirect)
          }
        } else {
          _this.collection.add([model], {
            merge: true,
          })
          $.flashMessage(
            I18n.t('observee_added', 'Now observing %{user}', {
              user: model.name,
            })
          )
          _this.$form.get(0).reset()
          return _this.focusForm()
        }
      }
    })(this)
  )
  return d.error(
    (function (_this) {
      return function (response) {
        _this.$form.formErrors(JSON.parse(response.responseText))
        return _this.focusForm()
      }
    })(this)
  )
}

UserObserveesView.prototype.removeObservee = function (ev) {
  ev.preventDefault()
  const id = '' + $(ev.target).data('user-id')
  const user_name = $(ev.target).data('user-name')
  if (
    // eslint-disable-next-line no-alert
    window.confirm(
      I18n.t('Are you sure you want to stop observing %{name}?', {
        name: user_name,
      })
    )
  ) {
    const current_observed_id = savedObservedId(ENV.current_user_id)
    if (current_observed_id === id) {
      clearObservedId(ENV.current_user_id)
    }
    return this.$form.disableWhileLoading(
      $.ajaxJSON(
        '/api/v1/users/self/observees/' + id,
        'DELETE',
        {},
        (function (_this) {
          return function () {
            return _this.removedObservee(id, user_name)
          }
        })(this)
      )
    )
  }
}

UserObserveesView.prototype.removedObservee = function (id, name) {
  this.collection.remove(id)
  return $.flashMessage(
    I18n.t('No longer observing %{user}', {
      user: name,
    })
  )
}

UserObserveesView.prototype.focusForm = function () {
  let field = this.$form.find(":input[value='']:not(button)").first()
  if (!field.length) {
    field = this.$form.find(':input:not(button)')
  }
  return field.focus()
}

UserObserveesView.prototype.setLoading = function (loading) {
  if (loading) {
    this.$('.observees-list-container').attr('aria-busy', 'true')
    return this.$('.loading-indicator').show()
  } else {
    this.$('.observees-list-container').attr('aria-busy', 'false')
    return this.$('.loading-indicator').hide()
  }
}

export default UserObserveesView
