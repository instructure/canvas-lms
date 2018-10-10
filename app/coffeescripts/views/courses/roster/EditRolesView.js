//
// Copyright (C) 2015 - present Instructure, Inc.
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

import I18n from 'i18n!course_settings'
import $ from 'jquery'
import _ from 'underscore'
import DialogBaseView from '../../DialogBaseView'
import RosterDialogMixin from './RosterDialogMixin'
import template from 'jst/courses/roster/editRolesView'
import '../../../jquery.rails_flash_notifications'
import 'jquery.disableWhileLoading'

export default class EditRolesView extends DialogBaseView {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.update = this.update.bind(this)
    super(...args)
  }

  static initClass() {
    this.mixin(RosterDialogMixin)

    this.prototype.template = template

    this.prototype.dialogOptions = {
      width: '300px',
      id: 'edit_roles',
      title: I18n.t('Edit Course Role')
    }
  }

  toJSON() {
    const json = {}

    const role_ids = _.uniq(_.map(this.model.enrollments(), en => en.role_id))
    if (role_ids.length > 1) {
      json.has_multiple_roles = true
    } else {
      this.role_id = role_ids[0]
      json.role_id = this.role_id
    }

    json.roles = ENV.ALL_ROLES
    return json
  }

  update(e) {
    e.preventDefault()

    const new_role_id = this.$el.find('#role_id').val()
    if (new_role_id === this.role_id) {
      this.close() // nothing changed
      return
    }

    const enrollments = this.model.enrollments()

    // section ids that already have the new role
    const existing_section_ids = _.map(
      _.filter(enrollments, en => en.role_id === new_role_id),
      en => en.course_section_id
    )

    const new_enrollments = []
    const deleted_enrollments = []

    const deferreds = []

    // limit to sections if all enrollments are limited
    const section_limited = _.all(enrollments, en => en.limit_privileges_to_course_section)

    for (const en of Array.from(enrollments)) {
      if (en.role_id !== new_role_id) {
        // leave alone if it already has the new role

        deleted_enrollments.push(en)
        deferreds.push($.ajaxJSON(`${ENV.COURSE_ROOT_URL}/unenroll/${en.id}`, 'DELETE')) // delete the enrollment

        if (!_.include(existing_section_ids, en.course_section_id)) {
          // create a new enrollment unless there's alrady one with the new role and the same course section
          existing_section_ids.push(en.course_section_id)
          const data = {
            enrollment: {
              user_id: this.model.get('id'),
              role_id: new_role_id,
              limit_privileges_to_course_section: section_limited,
              enrollment_state: en.enrollment_state
            }
          }
          deferreds.push(
            $.ajaxJSON(
              `/api/v1/sections/${en.course_section_id}/enrollments`,
              'POST',
              data,
              new_enrollment => {
                _.extend(new_enrollment, {can_be_removed: true})
                return new_enrollments.push(new_enrollment)
              }
            )
          )
        }
      }
    }

    return this.disable(
      $.when(...Array.from(deferreds || []))
        .done(() => {
          this.updateEnrollments(new_enrollments, deleted_enrollments)
          return $.flashMessage(I18n.t('Role successfully updated'))
        })
        .fail(() =>
          $.flashError(
            I18n.t("Something went wrong updating the user's role. Please try again later.")
          )
        )
        .always(() => this.close())
    )
  }
}
EditRolesView.initClass()
