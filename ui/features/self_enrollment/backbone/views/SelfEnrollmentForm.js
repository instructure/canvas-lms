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
import Backbone from '@canvas/backbone'
import registrationErrors from '@canvas/normalize-registration-errors'
import '@canvas/jquery/jquery.instructure_forms'
import '@canvas/jquery/jquery.ajaxJSON'

export default class SelfEnrollmentForm extends Backbone.View {
  static initClass() {
    this.prototype.events = {
      'change input[name=initial_action]': 'changeAction',
      'click #logout_link': 'logOutAndRefresh',
    }
  }

  initialize(options = {}) {
    this.options = options
    super.initialize(...arguments)
    this.enrollUrl = this.$el.attr('action')
    this.action = this.initialAction = this.$el
      .find('input[type=hidden][name=initial_action]')
      .val()

    if (ENV.ACCOUNT.recaptcha_key) {
      const that = this
      $(window).on('load', function () {
        if (typeof grecaptcha !== 'undefined') {
          // eslint-disable-next-line no-undef
          that.dataCaptchaId = grecaptcha.render(that.$el.find('.g-recaptcha')[0], {
            sitekey: ENV.ACCOUNT.recaptcha_key,
            callback: () => {
              that.recaptchaPassed = true
              that.$el.find('#submit_button').prop('disabled', false)
            },
            'expired-callback': () => {
              that.recaptchaPassed = false
              that.$el.find('#submit_button').prop('disabled', true)
            },
          })
        }
      })
      if (this.action === 'create') {
        this.$el.find('#submit_button').prop('disabled', true)
      }
    }
    return this.$el.formSubmit({
      beforeSubmit: data => this.beforeSubmit(data),
      success: data => this.success(data),
      errorFormatter: errors => this.errorFormatter(errors),
      error: () => this.clearCaptcha(),
      disableWhileLoading: 'spin_on_success',
    })
  }

  changeAction(e) {
    this.action = $(e.target).val()
    if (ENV.ACCOUNT.recaptcha_key) {
      this.$el
        .find('#submit_button')
        .prop('disabled', this.action === 'create' && !this.recaptchaPassed)
    }
    this.$el.find('.user_info').hide()
    this.$el.find(`#${this.action}_user_info`).show()
    return this.$el.find('#submit_button').css({visibility: 'visible'})
  }

  beforeSubmit(data) {
    if (!this.action) return false
    if (this.options.confirmEnrollmentUrl && this.action === 'enroll') {
      window.location = this.options.confirmEnrollmentUrl
      return false
    }

    this.normalizeData(data)

    return this.$el.attr(
      'action',
      (() => {
        switch (this.action) {
          case 'create':
            return '/users'
          case 'log_in':
            return '/login/canvas'
          case 'enroll':
            return this.enrollUrl
        }
      })()
    )
  }

  success(_data) {
    if (this.action === 'enroll') {
      // they should now be authenticated (either registered or pre_registered)
      let q = window.location.search
      q = q ? `${q}&` : '?'
      q += 'enrolled=1'
      if (this.initialAction === 'create') {
        q += '&just_created=1'
      }
      return (window.location.search = q)
    } else {
      // i.e. we just registered or logged in
      return this.enroll()
    }
  }

  normalizeData(data) {
    if (this.action === 'log_in') {
      data['pseudonym_session[unique_id]'] =
        data['pseudonym[unique_id]'] != null ? data['pseudonym[unique_id]'] : ''
      data['pseudonym_session[password]'] =
        data['pseudonym[password]'] != null ? data['pseudonym[password]'] : ''
    }
    return data
  }

  clearCaptcha() {
    if (ENV.ACCOUNT.recaptcha_key) {
      if (typeof grecaptcha !== 'undefined') {
        // eslint-disable-next-line no-undef
        grecaptcha.reset(this.dataCaptchaId)
      }
      this.$el.find('#submit_button').prop('disabled', true)
    }
  }

  errorFormatter(errors) {
    const ret = (() => {
      switch (this.action) {
        case 'create':
          return registrationErrors(errors)
        case 'log_in':
          return this.loginErrors(errors)
        case 'enroll':
          return this.enrollErrors(errors)
      }
    })()
    return ret
  }

  loginErrors(errors) {
    const error = errors[errors.length - 1]
    return $.flashError({html: error}, 30000)
  }

  enrollErrors(errors) {
    if (
      __guard__(
        errors.user != null ? errors.user.errors.self_enrollment_code : undefined,
        x => x[0].type
      ) === 'already_enrolled'
    ) {
      // just reload if already enrolled
      window.location.reload(true)
      return []
    }

    this.action = this.initialAction
    this.logOut()
    return errors
  }

  enroll() {
    this.action = 'enroll'
    return this.$el.submit()
  }

  logOut(refresh = false) {
    return $.ajaxJSON('/logout', 'DELETE', {}, () => {
      if (refresh) window.location.reload(true)
    })
  }

  logOutAndRefresh(e) {
    e.preventDefault()
    return this.logOut(true)
  }
}
SelfEnrollmentForm.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
