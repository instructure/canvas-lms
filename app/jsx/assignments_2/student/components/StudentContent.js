/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {arrayOf, bool, func, shape, string} from 'prop-types'
import {AssignmentShape, SubmissionShape} from '../assignmentData'
import AssignmentToggleDetails from '../../shared/AssignmentToggleDetails'
import ButtonContext from './Context'
import ContentTabs from './ContentTabs'
import Header from './Header'
import I18n from 'i18n!assignments_2_student_content'
import LockedAssignment from './LockedAssignment'
import MissingPrereqs from './MissingPrereqs'
import React, {Suspense, lazy} from 'react'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'

const LoggedOutTabs = lazy(() => import('./LoggedOutTabs'))

class StudentContent extends React.Component {
  static propTypes = {
    assignment: AssignmentShape,
    onLoadMore: func,
    pageInfo: shape({
      hasPreviousPage: bool,
      startCursor: string
    }),
    submissionHistoryEdges: arrayOf(
      shape({
        cursor: string,
        node: SubmissionShape
      })
    )
  }

  state = {
    displayedCursor: null,
    orderedCursors: [],
    loadingMore: false
  }

  static getDerivedStateFromProps(props, state) {
    const historyEdges = props.submissionHistoryEdges
    const newOrderedCursors = historyEdges.map(e => e.cursor)

    let newDisplayCursor = state.displayedCursor
    let newLoadingMore = state.loadingMore
    if (historyEdges.length === 1) {
      // Handle when we did a mutation and cleared our cache, so there is only
      // the new submission present. See the mutation for details on why we
      // clear the cache in this sceniaro.
      newDisplayCursor = newOrderedCursors[0]
    } else if (state.orderedCursors.length < historyEdges.length) {
      newDisplayCursor = newOrderedCursors.filter(c => !state.orderedCursors.includes(c)).pop()
      newLoadingMore = false
    } else {
      return null
    }

    return {
      displayedCursor: newDisplayCursor,
      orderedCursors: newOrderedCursors,
      loadingMore: newLoadingMore
    }
  }

  getCurrentSubmission = () => {
    const historyEdges = this.props.submissionHistoryEdges
    const currentSubmissionEdge = historyEdges.find(e => e.cursor === this.state.displayedCursor)
    if (currentSubmissionEdge) {
      return currentSubmissionEdge.node
    }
  }

  hasNextSubmission = () => {
    const historyEdges = this.props.submissionHistoryEdges
    const currentIndex = historyEdges.findIndex(e => e.cursor === this.state.displayedCursor)
    return currentIndex !== historyEdges.length - 1
  }

  hasPrevSubmission = () => {
    if (this.props.pageInfo.hasPreviousPage) {
      return !this.state.loadingMore
    }

    const historyEdges = this.props.submissionHistoryEdges
    const currentIndex = historyEdges.findIndex(e => e.cursor === this.state.displayedCursor)
    return currentIndex !== 0 && !this.state.loadingMore
  }

  onNextSubmission = () => {
    this.setState((state, props) => {
      const historyEdges = props.submissionHistoryEdges
      const currentIndex = historyEdges.findIndex(e => e.cursor === state.displayedCursor)
      if (currentIndex === historyEdges.length - 1) {
        return null
      } else {
        const nextCursor = state.orderedCursors[currentIndex + 1]
        return {displayedCursor: nextCursor}
      }
    })
  }

  onPrevSubmission = () => {
    this.setState((state, props) => {
      const historyEdges = props.submissionHistoryEdges
      const currentIndex = historyEdges.findIndex(e => e.cursor === state.displayedCursor)

      if (currentIndex > 0) {
        const prevCursor = state.orderedCursors[currentIndex - 1]
        return {displayedCursor: prevCursor}
      } else if (props.pageInfo.hasPreviousPage && !state.loadingMore) {
        this.props.onLoadMore()
        return {loadingMore: true}
      } else {
        return null
      }
    })
  }

  renderContentBaseOnAvailability = () => {
    const submission = this.getCurrentSubmission()

    if (this.props.assignment.env.modulePrereq) {
      const prereq = this.props.assignment.env.modulePrereq
      return <MissingPrereqs preReqTitle={prereq.title} preReqLink={prereq.link} />
    } else if (this.props.assignment.lockInfo.isLocked) {
      return <LockedAssignment assignment={this.props.assignment} />
    } else if (submission === null) {
      // NOTE: handles case where user is not logged in
      return (
        <React.Fragment>
          <AssignmentToggleDetails description={this.props.assignment.description} />
          <Suspense
            fallback={<Spinner title={I18n.t('Loading')} size="large" margin="0 0 0 medium" />}
          >
            <LoggedOutTabs assignment={this.props.assignment} />
          </Suspense>
        </React.Fragment>
      )
    } else {
      return (
        <React.Fragment>
          <AssignmentToggleDetails description={this.props.assignment.description} />
          <ContentTabs assignment={this.props.assignment} submission={submission} />
        </React.Fragment>
      )
    }
  }

  render() {
    const submission = this.getCurrentSubmission()
    return (
      <div data-testid="assignments-2-student-view">
        <ButtonContext.Provider
          value={{
            prevButtonEnabled: this.hasPrevSubmission(),
            nextButtonEnabled: this.hasNextSubmission(),
            prevButtonAction: this.onPrevSubmission,
            nextButtonAction: this.onNextSubmission
          }}
        >
          <Header
            scrollThreshold={150}
            assignment={this.props.assignment}
            submission={submission}
          />
        </ButtonContext.Provider>
        {this.renderContentBaseOnAvailability()}
      </div>
    )
  }
}

export default StudentContent
