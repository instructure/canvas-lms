#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'jquery',
  'i18n!profile'
  'compiled/fn/preventDefault',
  'jquery.ajaxJSON'
  'compiled/jquery.rails_flash_notifications'
], ($, I18n, preventDefault) ->
  $ ->
    resending = false

    $('.re_send_confirmation_link').click preventDefault ->
      $this = $(this)
      text = $this.text()

      return if resending
      resending = true
      $this.text I18n.t('resending', 'resending...')

      $.ajaxJSON $this.attr('href'), 'POST', {}, (data) ->
        resending = false
        $this.text text
        $.flashMessage I18n.t("done_resending", "Done! Message delivery may take a few minutes.")
      , (data) ->
        resending = false
        $this.text text
        $.flashError I18n.t("failed_resending", "Request failed. Try again.")
        
