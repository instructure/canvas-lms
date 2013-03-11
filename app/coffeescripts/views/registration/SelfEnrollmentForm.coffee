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
      'change input[name=user_type]': 'changeType'
      'click #logout_link': 'logOutAndRefresh'

    initialize: ->
      @enrollAction = @$el.attr('action')
      @userType = @$el.find('input[type=hidden][name=user_type]').val()
      @$el.formSubmit
        beforeSubmit: @beforeSubmit
        onSubmit: @onSubmit
        success: @enrollSuccess
        error: @enrollError
        formErrors: false

    changeType: (e) =>
      @userType = $(e.target).val()
      @$el.find('.user_info').hide()
      @$el.find("##{@userType}_user_info").show()
      @$el.find("#submit_button").css(visibility: 'visible')

    beforeSubmit: =>
      return false unless @userType
      unless @promise?
        @promise = $.Deferred()
        @$el.disableWhileLoading(@promise)

      switch @userType
        when 'new'
          # create user and self-enroll in course(s)
          @$el.attr('action', '/users')
        when 'existing'
          @logIn =>
            # yay, now enroll the user
            @userType = 'authenticated'
            @enrollErrorOnce = (errors) =>
              if @hasError(errors.user?.self_enrollment_code, 'already_enrolled')
                # we don't reload the form, so we want a subsequent login
                # or signup attempt to work
                @userType = 'existing'
                @logOut()
            @$el.submit()
          return false
        when 'authenticated'
          @$el.attr('action', @enrollAction)

    onSubmit: (deferred) ->
      $.when(deferred).done => @enrollErrorOnce = null

    error: (errors) =>
      @promise.reject()
      # move the "already enrolled" error to the username, since that's visible
      if errors['user[self_enrollment_code]']
        errors['pseudonym[unique_id]'] ?= []
        errors['pseudonym[unique_id]'].push errors['user[self_enrollment_code]'][0]
        delete errors['user[self_enrollment_code]']
      @$el.formErrors errors
      @promise = null

    enrollError: (errors) =>
      @enrollErrorOnce?(errors)
      @error registrationErrors(errors)

    enrollSuccess: (data) =>
      # they should now be authenticated (either registered or pre_registered)
      q = window.location.search
      q = (if q then "#{q}&" else "?")
      q += "enrolled=1"
      q += '&just_created=1' if @userType is 'new'
      window.location.search = q

    logIn: (successCb) ->
      data = pseudonym_session:
        unique_id: @$el.find('#student_email').val()
        password: @$el.find('#student_password').val()

      $.ajaxJSON '/login', 'POST', data, successCb, (errors, xhr) =>
        baseErrors = errors.errors.base
        error = baseErrors[baseErrors.length - 1].message
        @error 'pseudonym[password]': error

    logOut: (refresh = false) =>
      $.ajaxJSON '/logout', 'POST', {}, ->
        location.reload true if refresh
 
    logOutAndRefresh: (e) =>
      e.preventDefault()
      @logOut(true)

    hasError: (errors, type) ->
      return false unless errors
      return true for e in errors when e.type is type
      false
