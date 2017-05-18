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
  'i18n!gradezilla'
  'jquery'
  'jst/GradeDisplayWarningDialog'
  'jqueryui/dialog'
], (I18n, $, gradeDisplayWarningDialogTemplate) ->

  class GradeDisplayWarningDialog
    constructor: (options) ->
      @options = options
      points_warning = I18n.t("grade_display_warning.points_text", "Students will also see their final grade as points. Are you sure you want to continue?")
      percent_warning = I18n.t("grade_display_warning.percent_text", "Students will also see their final grade as a percentage. Are you sure you want to continue?")
      locals =
        warning_text: if @options.showing_points then percent_warning else points_warning
      @$dialog = $ gradeDisplayWarningDialogTemplate(locals)
      @$dialog.dialog
        resizable: false
        width: 350
        buttons: [{
          text: I18n.t("grade_display_warning.cancel", "Cancel"), click: @cancel},
          {text: I18n.t("grade_display_warning.continue", "Continue"), click: @save}]

    save: () =>
      if @$dialog.find('#hide_warning').prop('checked')
        @options.save({ dontWarnAgain: true })
      else
        @options.save({ dontWarnAgain: false })
      @$dialog.remove()

    cancel: () =>
      @$dialog.remove()
