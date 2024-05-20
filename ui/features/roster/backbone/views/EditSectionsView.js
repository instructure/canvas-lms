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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {map, reject, difference, filter, includes, extend as lodashExtend} from 'lodash'
import DialogBaseView from '@canvas/dialog-base-view'
import RosterDialogMixin from './RosterDialogMixin'
import editSectionsViewTemplate from '../../jst/EditSectionsView.handlebars'
import sectionTemplate from '../../jst/section.handlebars'
import h from '@instructure/html-escape'
import '../../jquery/ContextSearch'
import '@canvas/rails-flash-notifications'
import '@canvas/jquery/jquery.disableWhileLoading'

const I18n = useI18nScope('course_settings')

export default class EditSectionsView extends DialogBaseView {
  static initClass() {
    this.mixin(RosterDialogMixin)

    this.prototype.events = {'click #user_sections li a': 'removeSection'}

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
    this.setupContextSearch()
    return this
  }

  setupContextSearch() {
    this.$('#section_input').contextSearch({
      contexts: ENV.CONTEXTS,
      placeholder: I18n.t('edit_sections_placeholder', 'Enter a section name'),
      title: I18n.t('edit_sections_title', 'Section name'),
      onNewToken: this.onNewToken.bind(this),
      added: (data, $token, _newToken) => {
        return this.$('#user_sections').append($token)
      },
      selector: {
        baseData: {
          type: 'section',
          context: `course_${ENV.course.id}_sections`,
          exclude: map(
            this.model.sectionEditableEnrollments(),
            e => `section_${e.course_section_id}`
          ).concat(ENV.CONCLUDED_SECTIONS),
        },
        noExpand: true,
        browser: {
          data: {
            per_page: 100,
            types: ['section'],
            search_all_contexts: true,
          },
        },
      },
    })
    this.input = this.$('#section_input').data('token_input')
    this.input.$fakeInput.css('width', '100%')
    this.input.tokenValues = () => {
      return Array.from(this.$('#user_sections input')).map(input => input.value)
    }

    const $sections = this.$('#user_sections')
    return (() => {
      const result = []
      for (const e of Array.from(this.model.sectionEditableEnrollments())) {
        let section
        if ((section = ENV.CONTEXTS.sections[e.course_section_id])) {
          result.push(
            $sections.append(
              sectionTemplate({
                id: section.id,
                name: section.name,
                role: e.role,
                can_be_removed: e.can_be_removed,
              })
            )
          )
        } else {
          result.push(undefined)
        }
      }
      return result
    })()
  }

  onNewToken($token) {
    const $link = $token.find('a')
    $link.attr('href', '#')
    $link.attr(
      'title',
      I18n.t('remove_user_from_course_section', 'Remove user from %{course_section}', {
        course_section: $token.find('div').attr('title'),
      })
    )
    const $screenreader_span = $('<span class="screenreader-only"></span>').append(
      h(
        I18n.t('remove_user_from_course_section', 'Remove user from %{course_section}', {
          course_section: h($token.find('div').attr('title')),
        })
      )
    )
    return $link.append($screenreader_span)
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

  removeSection(e) {
    e.preventDefault()
    const $token = $(e.currentTarget).closest('li')
    if ($token.closest('ul').children().length > 1) {
      $token.remove()
    }
    return this.input.$input.focus()
  }
}
EditSectionsView.initClass()
