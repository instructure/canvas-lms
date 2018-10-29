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

import CreateUserList from '../../../models/CreateUserList'
import _ from 'underscore'
import I18n from 'i18n!create_users_view'
import DialogFormView from '../../DialogFormView'
import template from 'jst/courses/roster/createUsers'
import wrapper from 'jst/EmptyDialogFormWrapper'

export default class CreateUsersView extends DialogFormView {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.toJSON = this.toJSON.bind(this)
    super(...args)
  }

  static initClass() {
    this.optionProperty('rolesCollection')
    this.optionProperty('courseModel')

    this.prototype.defaults = {
      width: 700,
      height: 500
    }

    this.prototype.els = {
      '#privileges': '$privileges',
      '#user_list_textarea': '$textarea'
    }

    this.prototype.events = _.extend({}, this.prototype.events, {
      'click .createUsersStartOver': 'startOver',
      'click .createUsersStartOverFrd': 'startOverFrd',
      'change #role_id': 'changeEnrollment',
      'click #role_id': 'changeEnrollment',
      'click .dialog_closer': 'close'
    })

    this.prototype.template = template

    this.prototype.wrapperTemplate = wrapper
  }

  initialize() {
    if (this.model == null) this.model = new CreateUserList()
    return super.initialize(...arguments)
  }

  attach() {
    this.model.on('change:step', this.render, this)
    return this.model.on('change:step', this.focusX, this)
  }

  changeEnrollment(event) {
    return this.model.set('role_id', event.target.value)
  }

  openAgain() {
    this.startOverFrd()
    super.openAgain(...arguments)
    return this.focusX()
  }

  hasUsers() {
    return __guard__(this.model.get('users'), x => x.length)
  }

  onSaveSuccess() {
    this.model.incrementStep()
    if (this.model.get('step') === 3) {
      const role = this.rolesCollection.where({id: this.model.get('role_id')})[0]
      if (role != null) {
        role.increment('count', this.model.get('users').length)
      }
      const newUsers = this.model.get('users').length
      return this.courseModel && this.courseModel.increment('pendingInvitationsCount', newUsers)
    }
  }

  validateBeforeSave(data) {
    if (this.model.get('step') === 1 && !data.user_list) {
      return {
        user_list: [
          {
            type: 'required',
            message: I18n.t('required', 'Please enter some email addresses')
          }
        ]
      }
    } else {
      return {}
    }
  }

  startOver() {
    return this.model.startOver()
  }

  startOverFrd() {
    this.model.startOver()
    return this.$textarea && this.$textarea.val('')
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    json.course_section_id = `${json.course_section_id}`
    json.limit_privileges_to_course_section =
      json.limit_privileges_to_course_section === true ||
      json.limit_privileges_to_course_section === '1'
    return json
  }

  focusX() {
    $('.ui-dialog-titlebar-close', this.el.parentElement).focus()
  }
}
CreateUsersView.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
