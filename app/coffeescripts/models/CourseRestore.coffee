#
# Copyright (C) 2013 - present Instructure, Inc.
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

define [
  'Backbone'
  'jquery'
  'i18n!course_restore'
  'jquery.instructure_forms'
], (Backbone, $, I18n) ->
  class CourseRestore extends Backbone.Model
    baseUrl: -> "/api/v1/accounts/#{@get('account_id')}/courses"
    searchUrl: -> "#{@baseUrl()}/#{@get('id')}?include[]=all_courses"

    # Search will be given an id and do an api request to populate
    # the model with the course we were searching for. The id
    # must be set for the searchUrl to work correctly.
    # @api public
    search: (id) ->
      @trigger 'searching'
      @set 'id', id, silent: yes
      @fetch
        url: @searchUrl()
        success: (model) =>
          model.trigger 'doneSearching'
        error: (model, response) =>
          account_id = @get 'account_id'
          @clear silent: yes
          @set 'account_id', account_id, silent: true
          message = $.parseJSON(response.responseText)
          @set(response)
          model.trigger 'doneSearching'

    # This just cleans up data when comming back from fetch
    # before it gets slammed into the model.
    # @api backbone override private
    parse: (response) ->
      response.account_id = @get 'account_id' # Ensure account id stays the same
      @clear silent: yes
      response

    # Restore has a timeout after 60 seconds that stops the progress pulls
    # It works by creating a blank deferred object, then in this method
    # it creates a loop of ajax requests on the progress api. Once progress
    # is no longer queued (completed), it then resolves the deferred object,
    # makes sure the course is unpublished and returns the resolved deferred
    # object which then stops the loading icon.
    # @api public
    restore: =>
      @trigger 'restoring'
      deferred = $.Deferred()

      takingTooLong = false
      setTakingTooLong = => takingTooLong = true
      setTimeout setTakingTooLong, 60000

      ajaxRequest = (url, method="GET") =>
        $.ajax
          url: url
          type: method
          success: restoreSuccess
          error: restoreError

      restoreError = (response={}) =>
        $.flashError(I18n.t('restore_error', "There was an error attempting to restore the course. Course was not restored."))
        deferred.reject()

      restoreSuccess = (response) =>
        return restoreError() if takingTooLong

        switch response.workflow_state
          when 'queued', 'running'
            setTimeout (-> ajaxRequest response.url), 1000 # keep sending the request if its not completed yet.
          when 'completed'
            @set {workflow_state: 'unpublished', restored: true}
            @trigger 'doneRestoring'
            deferred.resolve()
          when 'failed'
            restoreError()

      ajaxRequest "#{@baseUrl()}/?course_ids[]=#{@get('id')}&event=undelete", "PUT"
      deferred
