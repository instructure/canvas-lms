/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import _ from 'underscore'
import React from 'react'
import assignmentUtils from '../../gradezilla/SISGradePassback/assignmentUtils'
import PostGradesDialogCorrectionsPage from '../../gradezilla/SISGradePassback/PostGradesDialogCorrectionsPage'
import PostGradesDialogNeedsGradingPage from '../../gradezilla/SISGradePassback/PostGradesDialogNeedsGradingPage'
import PostGradesDialogSummaryPage from '../../gradezilla/SISGradePassback/PostGradesDialogSummaryPage'

class PostGradesDialog extends React.Component {
  componentDidMount() {
    this.boundForceUpdate = this.forceUpdate.bind(this)
    this.props.store.addChangeListener(this.boundForceUpdate)
  }

  componentWillUnmount() {
    this.props.store.removeChangeListener(this.boundForceUpdate)
  }

  // Page advance callbacks
  advanceToNeedsGradingPage = () => {
    this.props.store.setState({pleaseShowNeedsGradingPage: true})
  }

  leaveNeedsGradingPage = () => {
    this.props.store.setState({pleaseShowNeedsGradingPage: false})
  }

  advanceToSummaryPage = () => {
    this.props.store.setState({pleaseShowSummaryPage: true})
  }

  postGrades = e => {
    this.props.store.postGrades()
    this.props.closeDialog(e)
  }

  validOverrideForSelection = (store, a) => {
    if (
      store.validCheck(a) &&
      a.overrideForThisSection != undefined &&
      a.currentlySelected.id.toString() == a.overrideForThisSection.course_section_id &&
      a.hadOriginalErrors == undefined
    ) {
      return true
    }
    return false
  }

  validMultipleOverride = a => {
    const invalid_overrides = _.filter(a.overrides, o => {
      o == null
    })
    if (
      invalid_overrides.length == 0 &&
      a.due_at == null &&
      a.overrides != undefined &&
      a.overrides.length > 0 &&
      a.overrides.length == a.sectionCount
    ) {
      return true
    } else {
      return false
    }
  }

  invalidAssignments = (assignments, store) => {
    const original_error_assignments = assignmentUtils.withOriginalErrors(
      assignments,
      this.props.store
    )
    const invalid_assignments = []
    _.each(assignments, a => {
      // override for a section is valid but the 'Everyone Else' scenario is still invalid
      if (this.validOverrideForSelection(store, a)) {
        return
      }

      // for handling an assignment with an override for each section and all of them being valid
      if (this.validMultipleOverride(a)) {
      }

      // assignments that have been ignored
      else if (a.please_ignore) {
      }

      // for handling the 'Everyone Else' scenario on the section that doesn't have an override
      else if (
        a.currentlySelected.id.toString() == store.overrideForEveryone(a) &&
        a.currentlySelected.type == 'section' &&
        a.due_at != null &&
        (a.hadOriginalErrors == undefined || a.hadOriginalErrors == false)
      ) {
      }

      // for handling the 'Everyone Else' scenario at the course level with sections that have overrides and other sections that are tied under the course "override"
      else if (
        a.currentlySelected.type == 'course' &&
        a.due_at != null &&
        (a.hadOriginalErrors == undefined || a.hadOriginalErrors == false)
      ) {
      }

      // for handling the 'Everyone Else' scenario on the section that does have an override
      else if (
        (original_error_assignments.length > 0 || original_error_assignments.length == 0) &&
        store.validCheck(a) &&
        a.overrideForThisSection != undefined &&
        a.currentlySelected.id.toString() == a.overrideForThisSection.course_section_id &&
        a.currentlySelected.type == 'section' &&
        (a.hadOriginalErrors == undefined || a.hadOriginalErrors == false)
      ) {
      }

      // for handling the 'Everyone Else' scenario on the course
      else if (
        store.validCheck(a) &&
        a.overrideForThisSection != undefined &&
        (a.currentlySelected.id.toString() == a.overrideForThisSection.course_section_id ||
          a.currentlySelected.id.toString() != a.overrideForThisSection.course_section_id) &&
        a.currentlySelected.type != 'section' &&
        (a.hadOriginalErrors == undefined || a.hadOriginalErrors == false)
      ) {
      }

      // explicitly check for assignment for the entire course and no overrides
      else if (
        (a.overrides == undefined || a.overrides.length === 0) &&
        (original_error_assignments.length > 0 || original_error_assignments.length == 0) &&
        a.due_at != null &&
        store.validCheck(a) &&
        (a.hadOriginalErrors == undefined || a.hadOriginalErrors == false)
      ) {
      }

      // is invalid
      else {
        invalid_assignments.push(a)
      }
    })
    return invalid_assignments
  }

  pageSet = (page, errors) => {
    if (page == 'corrections' && errors.length == 0) {
      page = 'summary'
    } else if (page == 'summary' && errors.length != 0) {
      page = 'corrections'
    }
    return page
  }

  render() {
    const store = this.props.store
    let page = store.getPage()
    const assignments_with_errors = this.invalidAssignments(store.getState().assignments, store)
    page = this.pageSet(page, assignments_with_errors)

    switch (page) {
      case 'corrections':
        return (
          <PostGradesDialogCorrectionsPage
            store={this.props.store}
            advanceToSummaryPage={this.advanceToSummaryPage}
          /> // /
        )
      case 'summary':
        var assignments = store.getState().assignments
        var postCount = assignmentUtils.notIgnored(assignments).length
        var needsGradingCount = assignmentUtils.needsGrading(assignments).length
        return (
          <PostGradesDialogSummaryPage
            postCount={postCount}
            needsGradingCount={needsGradingCount}
            advanceToNeedsGradingPage={this.advanceToNeedsGradingPage}
            postGrades={this.postGrades}
          /> // /
        )
      case 'needsGrading':
        var assignments = store.getState().assignments
        var needsGrading = assignmentUtils.needsGrading(assignments)
        return (
          <PostGradesDialogNeedsGradingPage
            needsGrading={needsGrading}
            leaveNeedsGradingPage={this.leaveNeedsGradingPage}
          /> // /
        )
    }
  }
}

export default PostGradesDialog
