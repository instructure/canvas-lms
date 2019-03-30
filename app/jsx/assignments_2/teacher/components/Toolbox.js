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

import React from 'react'
import {bool, func} from 'prop-types'

import I18n from 'i18n!assignments_2'
import {Mutation} from 'react-apollo'

import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Link from '@instructure/ui-elements/lib/components/Link'
import Text from '@instructure/ui-elements/lib/components/Text'
import Button from '@instructure/ui-buttons/lib/components/Button'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

import IconEmail from '@instructure/ui-icons/lib/Line/IconEmail'
import IconSpeedGrader from '@instructure/ui-icons/lib/Line/IconSpeedGrader'
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'

import {TeacherAssignmentShape, SET_WORKFLOW} from '../assignmentData'
import AssignmentPoints from './Editables/AssignmentPoints'

// let's use these helpers from the gradebook so we're consistent
import {
  hasSubmitted,
  hasSubmission
} from '../../../gradezilla/shared/helpers/messageStudentsWhoHelper'

function assignmentIsNew(assignment) {
  return !assignment.lid
}

function assignmentIsPublished(assignment) {
  return assignment.state === 'published'
}

export default class Toolbox extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    onChangeAssignment: func.isRequired,
    onUnsubmittedClick: func,
    onDelete: func,
    onPublishChangeComplete: func,
    onError: func,
    readOnly: bool
  }

  static defaultProps = {
    onUnsubmittedClick: () => {},
    onDelete: () => {},
    onPublishChangeComplete: () => {},
    onError: () => {},
    readOnly: true
  }

  state = {
    pointsMode: 'view'
  }

  submissions() {
    // TODO: We will need to exhaust the submissions pagination for this to work correctly
    return this.props.assignment.submissions.nodes
  }

  countSubmissions(fn) {
    return this.submissions().reduce((memo, submission) => memo + (fn(submission) ? 1 : 0), 0)
  }

  // TODO: publish => save all pending edits, including state
  //     unpublish => just update state
  // so if event.target.checked, we need to call back up to whatever will
  // do the save.
  handlePublishChange = (mutateAssignmentWorkflow, event) => {
    const newState = event.target.checked ? 'published' : 'unpublished'
    mutateAssignmentWorkflow({
      variables: {id: this.props.assignment.lid, workflow: newState},
      optimisticResponse: {
        updateAssignment: {
          __typename: 'UpdateAssignmentPayload',
          assignment: {
            __typename: 'Assignment',
            id: this.props.assignment.gid,
            state: newState
          }
        }
      }
    })
    this.props.onChangeAssignment('state', newState)
  }

  renderPublished() {
    // TODO: put the label on the left side of the toggle when checkbox supports it
    // TODO: handle error when updating published
    return (
      <Mutation
        mutation={SET_WORKFLOW}
        onCompleted={this.props.onPublishChangeComplete}
        onError={this.props.onError}
      >
        {(mutateAssignmentWorkflow, {loading, _error}) => (
          <Checkbox
            label={I18n.t('Published')}
            variant="toggle"
            size="medium"
            inline
            disabled={loading}
            checked={this.props.assignment.state === 'published'}
            onChange={event => this.handlePublishChange(mutateAssignmentWorkflow, event)}
          />
        )}
      </Mutation>
    )
  }

  renderDelete() {
    return (
      <Button margin="0 0 0 x-small" icon={<IconTrash />} onClick={this.props.onDelete}>
        <ScreenReaderContent>{I18n.t('delete assignment')}</ScreenReaderContent>
      </Button>
    )
  }

  renderSpeedGraderLink() {
    const assignmentLid = this.props.assignment.lid
    const courseLid = this.props.assignment.course.lid
    const speedgraderLink = `/courses/${courseLid}/gradebook/speed_grader?assignment_id=${assignmentLid}`
    return (
      <Link href={speedgraderLink} icon={<IconSpeedGrader />} iconPlacement="end" target="_blank">
        <Text transform="uppercase" size="small" color="primary">
          {I18n.t('%{number} to grade', {number: this.props.assignment.needsGradingCount})}
        </Text>
      </Link>
    )
  }

  renderUnsubmittedButton() {
    const unsubmittedCount = this.countSubmissions(submission => !hasSubmitted(submission))
    return this.renderMessageStudentsWhoButton(
      I18n.t('%{number} unsubmitted', {number: unsubmittedCount})
    )
  }

  renderMessageStudentsWhoButton(text) {
    return (
      <Link icon={<IconEmail />} iconPlacement="end" onClick={this.props.onUnsubmittedClick}>
        <Text transform="uppercase" size="small" color="primary">
          {text}
        </Text>
      </Link>
    )
  }

  renderSubmissionStats() {
    if (assignmentIsNew(this.props.assignment) || !assignmentIsPublished(this.props.assignment)) {
      return null
    }

    return [
      <FlexItem key="to grade" padding="xx-small xx-small xxx-small">
        {this.renderSpeedGraderLink({})}
      </FlexItem>,
      <FlexItem key="message students" padding="xx-small xx-small xxx-small">
        {hasSubmission(this.props.assignment)
          ? this.renderUnsubmittedButton()
          : this.renderMessageStudentsWhoButton(I18n.t('Message Students'))}
      </FlexItem>
    ]
  }

  renderPoints() {
    return (
      <AssignmentPoints
        mode={this.state.pointsMode}
        pointsPossible={this.props.assignment.pointsPossible}
        onChange={this.handlePointsChange}
        onChangeMode={this.handlePointsChangeMode}
        readOnly={this.props.readOnly}
      />
    )
  }

  handlePointsChange = value => {
    this.props.onChangeAssignment('pointsPossible', value)
  }

  handlePointsChangeMode = mode => {
    this.setState({pointsMode: mode})
  }

  render() {
    return (
      <div data-testid="teacher-toolbox">
        <Flex direction="column">
          <FlexItem padding="xx-small xx-small small">
            {this.renderPublished()}
            {this.renderDelete()}
          </FlexItem>
          {this.renderSubmissionStats()}
          <FlexItem padding="medium xx-small large" align="end">
            {this.renderPoints()}
          </FlexItem>
        </Flex>
      </div>
    )
  }
}
