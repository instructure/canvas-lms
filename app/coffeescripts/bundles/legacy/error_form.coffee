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
  "i18n!shared.error_form",
  "jquery",
  "str/htmlEscape",
  "jquery.instructure_forms",
  "jquery.loadingImg",
  "../../jquery.rails_flash_notifications"
], (I18n, $, htmlEscape) ->
  $(document).ready ->
    $("#error_username").hide()
    requiredFields = []
    if window.ENV.current_user.display_name == undefined
      requiredFields = ['error[email]']
    $(".submit_error_link").click (event) ->
      event.preventDefault()
      $("#submit_error_form").slideToggle ->
        $("#submit_error_form :input:visible:first").focus().select()

    $("#submit_error_form").formSubmit
      formErrors: false,
      required: requiredFields,
      beforeSubmit: (data) ->
        $(this).loadingImage()

      success: (data) ->
        $(this).loadingImage "remove"
        $.flashMessage(I18n.t("message_sent", "Thank you for your help!  We'll get right on this."))
        $("#submit_error_form").slideToggle()

      error: (data) ->
        $(this).loadingImage "remove"
        $(this).errorBox I18n.t("message_failed", "Report didn't send.  Please try again.")
