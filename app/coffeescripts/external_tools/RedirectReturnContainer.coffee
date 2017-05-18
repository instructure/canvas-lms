#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'jquery'
], ($) ->

  class RedirectReturnContainer
    successUrl: ENV.redirect_return_success_url
    cancelUrl: ENV.redirect_return_cancel_url

    attachLtiEvents: ->
      $(window).on 'externalContentReady', @_contentReady
      $(window).on 'externalContentCancel', @_contentCancel

    _contentReady: (event, data) =>
      if data && data.return_type == "file"
        @createMigration(data.url)
      else
        @redirectToSuccessUrl()

    _contentCancel: (event, data) =>
      location.href = @cancelUrl

    redirectToSuccessUrl: =>
      location.href = @successUrl

    createMigration: (file_url) =>
      data =
        migration_type: 'canvas_cartridge_importer'
        settings:
          file_url: file_url

      migrationUrl = "/api/v1/courses/#{ENV.course_id}/content_migrations"
      $.ajaxJSON migrationUrl, "POST", data, @redirectToSuccessUrl, @handleError

    handleError: (data) ->
      $.flashError data.message