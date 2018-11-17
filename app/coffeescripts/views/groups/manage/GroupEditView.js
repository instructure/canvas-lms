//
// Copyright (C) 2013 - present Instructure, Inc.
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

import I18n from 'i18n!groups'
import DialogFormView from '../../DialogFormView'
import template from 'jst/groups/manage/groupEdit'
import wrapper from 'jst/EmptyDialogFormWrapper'

export default class GroupEditView extends DialogFormView {
  static initClass() {
    this.optionProperty('groupCategory')
    this.optionProperty('student')

    this.prototype.defaults = {
      width: 550,
      title: I18n.t('edit_group', 'Edit Group')
    }

    this.prototype.els = {'[name=max_membership]': '$maxMembership'}

    this.prototype.template = template

    this.prototype.wrapperTemplate = wrapper

    this.prototype.className = 'dialogFormView group-edit-dialog form-horizontal form-dialog'

    this.prototype.events = {
      ...DialogFormView.prototype.events,
      'click .dialog_closer': 'close'
    }

    this.prototype.translations = {too_long: I18n.t('name_too_long', 'Name is too long')}
  }

  attach() {
    if (this.model) {
      return this.model.on('change', this.refreshIfNameOnlyMode, this)
    }
  }

  refreshIfNameOnlyMode() {
    if (this.options.nameOnly) {
      return window.location.reload()
    }
  }

  validateFormData(data, errors) {
    if (this.$maxMembership.length > 0 && !this.$maxMembership[0].validity.valid) {
      return {
        max_membership: [
          {message: I18n.t('max_membership_number', 'Max membership must be a number')}
        ]
      }
    }
  }

  openAgain() {
    super.openAgain(...arguments)
    // reset the form contents
    return this.render()
  }

  toJSON() {
    const json = Object.assign({}, super.toJSON(...arguments), {
      role: this.groupCategory.get('role'),
      nameOnly: this.options.nameOnly
    })
    return json
  }
}
GroupEditView.initClass()
