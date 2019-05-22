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

import {AssignmentShape, SubmissionShape} from '../assignmentData'
import {bool} from 'prop-types'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import FriendlyDatetime from '../../../shared/FriendlyDatetime'
import GradeDisplay from './GradeDisplay'
import I18n from 'i18n!assignments_2_student_header_date_title'
import React from 'react'
import StepItem from '../../shared/Steps/StepItem'
import Steps from '../../shared/Steps'
import Text from '@instructure/ui-elements/lib/components/Text'

function renderCollapsedContainer(step) {
  return (
    <div className="steps-main-status-label">
      <Text weight="bold">{step}</Text>
    </div>
  )
}

function allowNextAttempt(assignment, submission) {
  return assignment.allowedAttempts === null || submission.attempt < assignment.allowedAttempts
}

function availableStepContainer(props) {
  return (
    <div className="steps-container" data-testid="available-step-container">
      {props.isCollapsed && renderCollapsedContainer(I18n.t('Available'))}
      <Steps isCollapsed={props.isCollapsed}>
        <StepItem label={I18n.t('Available')} status="complete" />
        <StepItem label={I18n.t('Upload')} status="in-progress" />
        <StepItem label={I18n.t('Submit')} />
        <StepItem label={I18n.t('Not Graded Yet')} />
      </Steps>
    </div>
  )
}

availableStepContainer.propTypes = {
  isCollapsed: bool
}

function unavailableStepContainer(props) {
  return (
    <div className="steps-container" data-testid="unavailable-step-container">
      {props.isCollapsed && renderCollapsedContainer(I18n.t('Unavailable'))}
      <Steps isCollapsed={props.isCollapsed}>
        <StepItem label={I18n.t('Unavailable')} status="unavailable" />
        <StepItem label={I18n.t('Upload')} />
        <StepItem label={I18n.t('Submit')} />
        <StepItem label={I18n.t('Not Graded Yet')} />
      </Steps>
    </div>
  )
}

unavailableStepContainer.propTypes = {
  isCollapsed: bool
}

function uploadedStepContainer(props) {
  return (
    <div className="steps-container" data-testid="uploaded-step-container">
      {props.isCollapsed && renderCollapsedContainer(I18n.t('Uploaded'))}
      <Steps isCollapsed={props.isCollapsed}>
        <StepItem label={I18n.t('Available')} status="complete" />
        <StepItem label={I18n.t('Uploaded')} status="complete" />
        <StepItem label={I18n.t('Submit')} status="in-progress" />
        <StepItem label={I18n.t('Not Graded Yet')} />
      </Steps>
    </div>
  )
}

uploadedStepContainer.propTypes = {
  isCollapsed: bool
}

function submittedStepContainer(props) {
  return (
    <div className="steps-container" data-testid="submitted-step-container">
      {props.isCollapsed && renderCollapsedContainer(I18n.t('Submitted'))}
      <Steps isCollapsed={props.isCollapsed}>
        <StepItem label={I18n.t('Available')} status="complete" />
        <StepItem label={I18n.t('Uploaded')} status="complete" />
        <StepItem
          label={
            <Flex direction="column">
              <FlexItem>{I18n.t('Submitted')}</FlexItem>
              <FlexItem>
                <FriendlyDatetime
                  format={I18n.t('#date.formats.full')}
                  dateTime={props.submission.submittedAt}
                />
              </FlexItem>
            </Flex>
          }
          status="complete"
        />
        <StepItem label={I18n.t('Not Graded Yet')} />
        {allowNextAttempt(props.assignment, props.submission) && !props.isCollapsed ? (
          <StepItem label={I18n.t('New Attempt')} status="button" />
        ) : null}
      </Steps>
    </div>
  )
}

submittedStepContainer.propTypes = {
  assignment: AssignmentShape,
  isCollapsed: bool,
  submission: SubmissionShape
}

function gradedStepContainer(props) {
  return (
    <div className="steps-container" data-testid="graded-step-container">
      {props.isCollapsed && renderCollapsedContainer(I18n.t('Graded'))}
      <Steps isCollapsed={props.isCollapsed}>
        <StepItem label={I18n.t('Available')} status="complete" />
        <StepItem label={I18n.t('Uploaded')} status="complete" />
        <StepItem
          label={
            <Flex direction="column">
              <FlexItem>{I18n.t('Submitted')}</FlexItem>
              <FlexItem>
                <FriendlyDatetime
                  format={I18n.t('#date.formats.full')}
                  dateTime={props.submission.submittedAt}
                />
              </FlexItem>
            </Flex>
          }
          status="complete"
        />
        <StepItem
          label={
            <Flex direction="column">
              <FlexItem>{I18n.t('Grade')}</FlexItem>
              <FlexItem>
                <GradeDisplay
                  displaySize="small"
                  gradingType={props.assignment.gradingType}
                  pointsPossible={props.assignment.pointsPossible}
                  receivedGrade={props.submission.grade}
                />
              </FlexItem>
            </Flex>
          }
          status="complete"
        />
        {allowNextAttempt(props.assignment, props.submission) && !props.isCollapsed ? (
          <StepItem label={I18n.t('New Attempt')} status="button" />
        ) : null}
      </Steps>
    </div>
  )
}

// TODO: We are calling this as a function, not through jsx. Lets make sure
//       the propType validations properly that way. If not we need to remove
//       these or actually using jsx to call them.
gradedStepContainer.propTypes = {
  assignment: AssignmentShape,
  isCollapsed: bool,
  submission: SubmissionShape
}

function StepContainer(props) {
  const {assignment, submission, isCollapsed, forceLockStatus} = props
  if (forceLockStatus || assignment.lockInfo.isLocked) {
    return unavailableStepContainer({isCollapsed})
  } else if (submission.state === 'graded') {
    return gradedStepContainer({isCollapsed, assignment, submission})
  } else if (submission.state === 'submitted') {
    return submittedStepContainer({isCollapsed, assignment, submission})
  } else if (submission.submissionDraft) {
    return uploadedStepContainer({isCollapsed})
  } else {
    return availableStepContainer({isCollapsed})
  }
}

StepContainer.propTypes = {
  assignment: AssignmentShape,
  forceLockStatus: bool,
  isCollapsed: bool,
  submission: SubmissionShape
}

export default React.memo(StepContainer)
