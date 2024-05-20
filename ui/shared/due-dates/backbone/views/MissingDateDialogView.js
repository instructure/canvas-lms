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
import {View} from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'
import template from '../../jst/missingDueDateDialog.handlebars'
import htmlEscape from '@instructure/html-escape'
import 'jqueryui/dialog'
import '@canvas/util/jquery/fixDialogButtons'

const I18n = useI18nScope('calendar.edit')

extend(MissingDateDialogView, View)

function MissingDateDialogView() {
  this.cancel = this.cancel.bind(this)
  this.onAction = this.onAction.bind(this)
  return MissingDateDialogView.__super__.constructor.apply(this, arguments)
}

MissingDateDialogView.prototype.dialogTitle =
  '<span>\n  <i class="icon-warning"></i>\n  ' +
  htmlEscape(I18n.t('titles.warning', 'Warning')) +
  '\n</span>'

MissingDateDialogView.prototype.initialize = function (options) {
  MissingDateDialogView.__super__.initialize.apply(this, arguments)
  this.validationFn = options.validationFn
  this.labelFn = options.labelFn || this.defaultLabelFn
  return (this.success = options.success)
}

MissingDateDialogView.prototype.defaultLabelFn = function (input) {
  return $('label[for=' + $(input).attr('id') + ']').text()
}

MissingDateDialogView.prototype.render = function () {
  this.invalidFields = this.validationFn()
  if (this.invalidFields === true) {
    return false
  } else {
    this.invalidSectionNames = this.invalidFields.map(this.labelFn)
    this.showDialog()
    return this
  }
}

MissingDateDialogView.prototype.getInvalidFields = function () {
  const invalidDates = this.$dateFields.filter(date => $(date).val() === '')
  const sectionNames = invalidDates.map(this.labelFn)
  if (sectionNames.length > 0) {
    return [invalidDates, sectionNames]
  } else {
    return false
  }
}

MissingDateDialogView.prototype.showDialog = function () {
  const description = I18n.t(
    'missingDueDate',
    {
      one: '%{sections} does not have a due date assigned.',
      other: '%{sections} do not have a due date assigned.',
    },
    {
      sections: '',
      count: this.invalidSectionNames.length,
    }
  )
  const tpl = template({
    description,
    sections: this.invalidSectionNames,
  })
  this.$dialog = $(tpl)
    .dialog({
      dialogClass: 'dialog-warning',
      draggable: false,
      modal: true,
      resizable: false,
      title: $(this.dialogTitle),
      zIndex: 1000,
    })
    .fixDialogButtons()
    .on('click', '.btn', this.onAction)
  return this.$dialog.parents('.ui-dialog:first').focus()
}

MissingDateDialogView.prototype.onAction = function (e) {
  if ($(e.currentTarget).hasClass('btn-primary')) {
    return this.success(this.$dialog)
  } else {
    return this.cancel(this.invalidFields, this.sectionNames)
  }
}

MissingDateDialogView.prototype.cancel = function (_e) {
  if (this.$dialog != null && this.$dialog.data('ui-dialog')) {
    this.$dialog.dialog('close').remove()
  }
  if (this.invalidFields[0] != null) {
    return this.invalidFields[0].focus()
  }
}

export default MissingDateDialogView
