// @ts-nocheck
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

import React from 'react'
import {filter, each} from 'lodash'
import assignmentUtils from './assignmentUtils'
import PostGradesDialogCorrectionsPage from './PostGradesDialogCorrectionsPage'
import PostGradesDialogNeedsGradingPage from './PostGradesDialogNeedsGradingPage'
import PostGradesDialogSummaryPage from './PostGradesDialogSummaryPage'
import PostGradesStore from './PostGradesStore'
import type {AssignmentWithOverride} from '../default_gradebook/gradebook.d'

type Props = {
  store: ReturnType<typeof PostGradesStore>
  closeDialog: (event) => void
}

class PostGradesDialog extends React.Component<Props> {
  boundForceUpdate?: () => void

  componentDidMount() {
    this.boundForceUpdate = this.forceUpdate.bind(this)
    this.props.store.addChangeListener(this.boundForceUpdate)
  }

  componentWillUnmount() {
    this.props.store.removeChangeListener(this.boundForceUpdate as () => void)
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
      a.overrideForThisSection &&
      a.currentlySelected.id.toString() === a.overrideForThisSection.course_section_id &&
      typeof a.hadOriginalErrors === 'undefined'
    ) {
      return true
    }
    return false
  }

  validMultipleOverride = a => {
    const invalid_overrides = filter(a.overrides, o => o == null)
    if (
      invalid_overrides.length === 0 &&
      a.due_at == null &&
      Array.isArray(a.overrides) &&
      a.overrides.length > 0 &&
      a.overrides.length === a.sectionCount
    ) {
      return true
    } else {
      return false
    }
  }

  invalidAssignments = (assignments, store) => {
    const original_error_assignments = assignmentUtils.withOriginalErrors(assignments)
    const invalid_assignments: AssignmentWithOverride[] = []
    each(assignments, a => {
      // override for a section is valid but the 'Everyone Else' scenario is still invalid
      if (this.validOverrideForSelection(store, a)) {
        return
      }

      // for handling an assignment with an override for each section and all of them being valid
      if (this.validMultipleOverride(a)) {
        // no-op
      }

      // assignments that have been ignored
      else if (a.please_ignore) {
        // no-op
      }

      // for handling the 'Everyone Else' scenario on the section that doesn't have an override
      else if (
        a.currentlySelected.id.toString() === store.overrideForEveryone(a) &&
        a.currentlySelected.type === 'section' &&
        a.due_at != null &&
        !a.hadOriginalErrors
      ) {
        // no-op
      }

      // for handling the 'Everyone Else' scenario at the course level with sections that have overrides and other sections that are tied under the course "override"
      else if (a.currentlySelected.type === 'course' && a.due_at != null && !a.hadOriginalErrors) {
        // no-op
      }

      // for handling the 'Everyone Else' scenario on the section that does have an override
      else if (
        (original_error_assignments.length > 0 || original_error_assignments.length === 0) &&
        store.validCheck(a) &&
        a.overrideForThisSection &&
        a.currentlySelected.id.toString() === a.overrideForThisSection.course_section_id &&
        a.currentlySelected.type === 'section' &&
        !a.hadOriginalErrors
      ) {
        // no-op
      }

      // for handling the 'Everyone Else' scenario on the course
      else if (
        store.validCheck(a) &&
        a.overrideForThisSection &&
        (a.currentlySelected.id.toString() === a.overrideForThisSection.course_section_id ||
          a.currentlySelected.id.toString() !== a.overrideForThisSection.course_section_id) &&
        a.currentlySelected.type !== 'section' &&
        !a.hadOriginalErrors
      ) {
        // no-op
      }

      // explicitly check for assignment for the entire course and no overrides
      else if (
        (typeof a.overrides === 'undefined' || a.overrides.length === 0) &&
        (original_error_assignments.length > 0 || original_error_assignments.length === 0) &&
        a.due_at != null &&
        store.validCheck(a) &&
        !a.hadOriginalErrors
      ) {
        // no-op
      }

      // is invalid
      else {
        invalid_assignments.push(a)
      }
    })
    return invalid_assignments
  }

  pageSet = (page: string, errors) => {
    if (page === 'corrections' && errors.length === 0) {
      page = 'summary'
    } else if (page === 'summary' && errors.length !== 0) {
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
      case 'summary': {
        const assignments = store.getState().assignments
        // TODO: fix this as Array<AssignmentWithOverride> cast
        const postCount = assignmentUtils.notIgnored(
          assignments as Array<AssignmentWithOverride>
        ).length
        const needsGradingCount = assignmentUtils.needsGrading(
          assignments as Array<AssignmentWithOverride>
        ).length
        return (
          <PostGradesDialogSummaryPage
            postCount={postCount}
            needsGradingCount={needsGradingCount}
            advanceToNeedsGradingPage={this.advanceToNeedsGradingPage}
            postGrades={this.postGrades}
          /> // /
        )
      }
      case 'needsGrading': {
        const assignments = store.getState().assignments

        // TODO: fix this as Array<AssignmentWithOverride> cast
        const needsGrading = assignmentUtils.needsGrading(
          assignments as Array<AssignmentWithOverride>
        )
        return (
          <PostGradesDialogNeedsGradingPage
            needsGrading={needsGrading}
            leaveNeedsGradingPage={this.leaveNeedsGradingPage}
          /> // /
        )
      }
    }
  }
}

export default PostGradesDialog
