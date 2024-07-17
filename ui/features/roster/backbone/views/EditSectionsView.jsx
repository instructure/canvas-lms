//
// Copyright (C) 2012 - present Instructure, Inc.
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

import React from 'react'
import ReactDOM from 'react-dom'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import SectionSelector from '../../react/SectionSelector'

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {map, reject, difference, filter, includes, extend as lodashExtend} from 'lodash'
import DialogBaseView from '@canvas/dialog-base-view'
import RosterDialogMixin from './RosterDialogMixin'
import editSectionsViewTemplate from '../../jst/EditSectionsView.handlebars'
import '@canvas/rails-flash-notifications'
import '@canvas/jquery/jquery.disableWhileLoading'

const I18n = useI18nScope('course_settings')

export default class EditSectionsView extends DialogBaseView {
  static initClass() {
    this.mixin(RosterDialogMixin)

    this.prototype.dialogOptions = {
      id: 'edit_sections',
      title: I18n.t('titles.section_enrollments', 'Section Enrollments'),
      modal: true,
      zIndex: 1000,
    }
  }

  render() {
    this.$el.html(
      editSectionsViewTemplate({
        sectionsUrl: ENV.SEARCH_URL,
      })
    )
    super.render()
    return this
  }

  afterRender() {
    const enrollments = this.model.sectionEditableEnrollments()

    const excludeSections = enrollments.map(enrollment => {
      const section = ENV.CONTEXTS.sections[enrollment.course_section_id]

      return {
        id: section.id,
        name: section.name,
        role: enrollment.role,
        can_be_removed: enrollment.can_be_removed,
      }
    })

    ReactDOM.render(
      <QueryClientProvider client={new QueryClient()}>
        <SectionSelector courseId={ENV.current_context.id} initialSections={excludeSections} />
      </QueryClientProvider>,
      document.getElementById('react_section_input')
    )
  }


  update(e) {
    let url
    e.preventDefault()

    const enrollment = this.model.findEnrollmentByRole(this.model.currentRole)
    const currentIds = map(this.model.sectionEditableEnrollments(), en => en.course_section_id)
    const sectionIds = map($('#user_sections').find('input'), i => $(i).val().split('_')[1])
    const newSections = reject(sectionIds, i => includes(currentIds, i))
    const newEnrollments = []
    const deferreds = []
    // create new enrollments
    for (const id of Array.from(newSections)) {
      url = `/api/v1/sections/${id}/enrollments`
      const data = {
        enrollment: {
          user_id: this.model.get('id'),
          type: enrollment.type,
          limit_privileges_to_course_section: enrollment.limit_privileges_to_course_section,
        },
      }
      if (!this.model.pending(this.model.currentRole)) {
        data.enrollment.enrollment_state = 'active'
      }
      if (enrollment.role !== enrollment.type) {
        data.enrollment.role_id = enrollment.role_id
      }
      deferreds.push(
        $.ajaxJSON(url, 'POST', data, newEnrollment => {
          lodashExtend(newEnrollment, {can_be_removed: true})
          return newEnrollments.push(newEnrollment)
        })
      )
    }

    // delete old section enrollments
    const sectionsToRemove = difference(currentIds, sectionIds)
    const enrollmentsToRemove = filter(this.model.sectionEditableEnrollments(), en =>
      includes(sectionsToRemove, en.course_section_id)
    )
    for (const en of Array.from(enrollmentsToRemove)) {
      url = `${ENV.COURSE_ROOT_URL}/unenroll/${en.id}`
      deferreds.push($.ajaxJSON(url, 'DELETE'))
    }

    return this.disable(
      $.when(...Array.from(deferreds || []))
        .done(() => {
          this.updateEnrollments(newEnrollments, enrollmentsToRemove)
          return $.flashMessage(
            I18n.t('flash.sections', 'Section enrollments successfully updated')
          )
        })
        .fail(() =>
          $.flashError(
            I18n.t(
              'flash.sectionError',
              "Something went wrong updating the user's sections. Please try again later."
            )
          )
        )
        .always(() => this.close())
    )
  }
}
EditSectionsView.initClass()
