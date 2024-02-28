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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import gradeDisplayWarningDialogTemplate from '../jst/GradeDisplayWarningDialog.handlebars'
import 'jqueryui/dialog'

const I18n = useI18nScope('gradebookGradeDisplayWarningDialog')

function GradeDisplayWarningDialog(options) {
  this.cancel = this.cancel.bind(this)
  this.save = this.save.bind(this)
  this.options = options
  const points_warning = I18n.t(
    'grade_display_warning.points_text',
    'Students will also see their final grade as points. Are you sure you want to continue?'
  )
  const percent_warning = I18n.t(
    'grade_display_warning.percent_text',
    'Students will also see their final grade as a percentage. Are you sure you want to continue?'
  )
  const locals = {
    warning_text: this.options.showing_points ? percent_warning : points_warning,
  }
  this.$dialog = $(gradeDisplayWarningDialogTemplate(locals))
  this.$dialog.dialog({
    resizable: false,
    width: 350,
    buttons: [
      {
        text: I18n.t('grade_display_warning.cancel', 'Cancel'),
        click: this.cancel,
      },
      {
        text: I18n.t('grade_display_warning.continue', 'Continue'),
        click: this.save,
      },
    ],
    close: (function (_this) {
      return function () {
        _this.$dialog.remove()
        if (typeof options.onClose === 'function') {
          return options.onClose()
        }
      }
    })(this),
    modal: true,
    zIndex: 1000,
  })
}

GradeDisplayWarningDialog.prototype.save = function () {
  if (this.$dialog.find('#hide_warning').prop('checked')) {
    this.options.save({
      dontWarnAgain: true,
    })
  } else {
    this.options.save({
      dontWarnAgain: false,
    })
  }
  return this.$dialog.dialog('close')
}

GradeDisplayWarningDialog.prototype.cancel = function () {
  return this.$dialog.dialog('close')
}

export default GradeDisplayWarningDialog
