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

import I18n from 'i18n!course_settings'
import $ from 'jquery'
import _ from 'underscore'
import DialogBaseView from '../../DialogBaseView'
import RosterDialogMixin from './RosterDialogMixin'
import linkToStudentsViewTemplate from 'jst/courses/roster/LinkToStudentsView'
import 'jquery.disableWhileLoading'

export default class LinkToStudentsView extends DialogBaseView {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.onNewToken = this.onNewToken.bind(this)
    this.update = this.update.bind(this)
    super(...args)
  }

  static initClass() {
    this.mixin(RosterDialogMixin)

    this.prototype.dialogOptions = {
      id: 'link_students',
      title: I18n.t('titles.link_to_students', 'Link to Students')
    }
  }

  render() {
    const data = this.model.toJSON()
    data.studentsUrl = ENV.SEARCH_URL
    this.$el.html(linkToStudentsViewTemplate(data))

    this.students = []
    this.$('#student_input').contextSearch({
      contexts: ENV.CONTEXTS,
      placeholder: I18n.t('link_students_placeholder', 'Enter a student name'),
      change: tokens => (this.students = tokens),
      onNewToken: this.onNewToken,
      selector: {
        baseData: {
          type: 'user',
          context: `course_${ENV.course.id}_students`,
          exclude: [this.model.get('id')],
          skip_visibility_checks: true
        },
        noExpand: true,
        browser: {
          data: {
            per_page: 100,
            types: ['user']
          }
        }
      }
    })
    const input = this.$('#student_input').data('token_input')
    input.$fakeInput.css('width', '100%')

    for (const e of this.model.allEnrollmentsByType('ObserverEnrollment')) {
      if (e.observed_user && _.any(e.observed_user.enrollments)) {
        input.addToken({
          value: e.observed_user.id,
          text: e.observed_user.name,
          data: e.observed_user
        })
      }
    }

    return this
  }

  onNewToken($token) {
    const $link = $token.find('a')
    $link.attr('href', '#')
    $link.attr(
      'title',
      I18n.t('Remove linked student %{name}', {name: $token.find('div').attr('title')})
    )
    const $screenreader_span = $('<span class="screenreader-only"></span>').text(
      I18n.t('Remove linked student %{name}', {name: $token.find('div').attr('title')})
    )
    return $link.append($screenreader_span)
  }

  getUserData(id) {
    return $.getJSON(`/api/v1/courses/${ENV.course.id}/users/${id}`, {include: ['enrollments']})
  }

  update(e) {
    let dfdsDone, newDfd
    e.preventDefault()

    const dfds = []
    const enrollments = this.model.allEnrollmentsByType('ObserverEnrollment')
    const enrollment = enrollments[0]
    const unlinkedEnrolls = _.filter(enrollments, en => !en.associated_user_id) // keep the original observer enrollment around
    const currentLinks = _.compact(_.pluck(enrollments, 'associated_user_id'))
    const newLinks = _.difference(this.students, currentLinks)
    const removeLinks = _.difference(currentLinks, this.students)
    const newEnrollments = []

    if (newLinks.length) {
      newDfd = $.Deferred()
      dfds.push(newDfd.promise())
      dfdsDone = 0
    }

    // create new links
    for (const id of newLinks) {
      this.getUserData(id).done(user => {
        const udfds = []
        const sections = _.map(user.enrollments, en => en.course_section_id)
        for (const sId of sections) {
          const url = `/api/v1/sections/${sId}/enrollments`
          const data = {
            enrollment: {
              user_id: this.model.get('id'),
              associated_user_id: user.id,
              type: enrollment.type,
              limit_privileges_to_course_section: enrollment.limit_priveleges_to_course_section
            }
          }
          if (enrollment.role !== enrollment.type) {
            data.enrollment.role_id = enrollment.role_id
          }
          udfds.push(
            $.ajaxJSON(url, 'POST', data, newEnrollment => {
              newEnrollment.observed_user = user
              return newEnrollments.push(newEnrollment)
            })
          )
        }
        return $.when(...Array.from(udfds || [])).done(() => {
          dfdsDone += 1
          if (dfdsDone === newLinks.length) {
            return newDfd.resolve()
          }
        })
      })
    }

    // delete old links
    const enrollmentsToRemove = _.filter(enrollments, en =>
      _.include(removeLinks, en.associated_user_id)
    )
    for (const en of enrollmentsToRemove) {
      const url = `${ENV.COURSE_ROOT_URL}/unenroll/${en.id}`
      dfds.push($.ajaxJSON(url, 'DELETE'))
    }

    return this.disable(
      $.when(...Array.from(dfds || []))
        .done(() => {
          this.updateEnrollments(newEnrollments, enrollmentsToRemove)
          return $.flashMessage(I18n.t('flash.links', 'Student links successfully updated'))
        })
        .fail(() =>
          $.flashError(
            I18n.t(
              'flash.linkError',
              "Something went wrong updating the user's student links. Please try again later."
            )
          )
        )
        .always(() => this.close())
    )
  }
}
LinkToStudentsView.initClass()
