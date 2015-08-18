#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

define [
  'jquery'
  'underscore'
  'Backbone'
  'i18n!registration'
  'compiled/registration/registrationErrors'
  'jquery.instructure_forms'
  'jquery.ajaxJSON'
], ($, _, Backbone, I18n, registrationErrors) ->

  class SelfEnrollmentForm extends Backbone.View
    events:
      'change input[name=initial_action]': 'changeAction'
      'click #logout_link': 'logOutAndRefresh'

    initialize: (@options = {}) ->
      super
      @enrollUrl = @$el.attr('action')
      @action = @initialAction = @$el.find('input[type=hidden][name=initial_action]').val()
      @$el.formSubmit {@beforeSubmit, @success, @errorFormatter, disableWhileLoading: 'spin_on_success'}

    changeAction: (e) =>
      @action = $(e.target).val()
      @$el.find('.user_info').hide()
      @$el.find("##{@action}_user_info").show()
      @$el.find("#submit_button").css(visibility: 'visible')

    beforeSubmit: (data) =>
      return false unless @action
      if @options.confirmEnrollmentUrl and @action is 'enroll'
        window.location = @options.confirmEnrollmentUrl
        return false

      @normalizeData(data)

      @$el.attr 'action', switch @action
        when 'create' then '/users'
        when 'log_in' then '/login'
        when 'enroll' then @enrollUrl

    success: (data) =>
      if @action is 'enroll'
        # they should now be authenticated (either registered or pre_registered)
        q = window.location.search
        q = (if q then "#{q}&" else "?")
        q += "enrolled=1"
        q += '&just_created=1' if @initialAction is 'create'
        window.location.search = q
      else # i.e. we just registered or logged in
        @enroll()

    normalizeData: (data) =>
      if @action is 'log_in'
        data['pseudonym_session[unique_id]'] = data['pseudonym[unique_id]'] ? ''
        data['pseudonym_session[password]']  = data['pseudonym[password]'] ? ''
      data

    errorFormatter: (errors) =>
      ret = switch @action
        when 'create' then registrationErrors(errors)
        when 'log_in' then @loginErrors(errors)
        when 'enroll' then @enrollErrors(errors)
      ret

    loginErrors: (errors) ->
      errors = errors.base
      error = errors[errors.length - 1]
      {'pseudonym[password]': error}

    enrollErrors: (errors) =>
      if errors.user?.errors.self_enrollment_code?[0].type == "already_enrolled"
        # just reload if already enrolled
        location.reload true
        return []

      @action = @initialAction
      @logOut()
      errors

    enroll: =>
      @action = 'enroll'
      @$el.submit()

    logOut: (refresh = false) =>
      $.ajaxJSON '/logout', 'DELETE', {}, ->
        location.reload true if refresh

    logOutAndRefresh: (e) =>
      e.preventDefault()
      @logOut(true)

