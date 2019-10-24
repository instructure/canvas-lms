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

import {Assignment} from '../graphqlData/Assignment'
import {bool} from 'prop-types'
import I18n from 'i18n!assignments_2_student_header_date_title'
import React from 'react'
import StepItem from '../../shared/Steps/StepItem'
import Steps from '../../shared/Steps'
import StudentViewContext from './Context'
import {Submission} from '../graphqlData/Submission'
import {Text} from '@instructure/ui-elements'

function renderCollapsedContainer(step) {
  return (
    <div className="steps-main-status-label" data-testid="collapsed-step-container">
      <Text weight="bold">{step}</Text>
    </div>
  )
}

function allowNextAttempt(assignment, submission) {
  return assignment.allowedAttempts === null || submission.attempt < assignment.allowedAttempts
}

function availableStepContainer(props, context) {
  return (
    <div className="steps-container" data-testid="available-step-container">
      {props.isCollapsed && renderCollapsedContainer(I18n.t('Available'))}
      <Steps isCollapsed={props.isCollapsed}>
        {context.prevButtonEnabled && !props.isCollapsed ? (
          <StepItem label={I18n.t('Previous')} status="button" />
        ) : null}
        <StepItem label={I18n.t('Available')} status="complete" />
        <StepItem label={I18n.t('Upload')} status="in-progress" />
        <StepItem label={I18n.t('Submit')} status="incomplete" />
        <StepItem label={I18n.t('Not Graded Yet')} status="incomplete" />
        {context.nextButtonEnabled && !props.isCollapsed ? (
          <StepItem label={I18n.t('Next')} status="button" />
        ) : null}
      </Steps>
    </div>
  )
}

availableStepContainer.propTypes = {
  isCollapsed: bool
}

function unavailableStepContainer(props, context) {
  return (
    <div className="steps-container" data-testid="unavailable-step-container">
      {props.isCollapsed && renderCollapsedContainer(I18n.t('Unavailable'))}
      <Steps isCollapsed={props.isCollapsed}>
        {context.prevButtonEnabled && !props.isCollapsed ? (
          <StepItem label={I18n.t('Previous')} status="button" />
        ) : null}
        <StepItem label={I18n.t('Unavailable')} status="unavailable" />
        <StepItem label={I18n.t('Upload')} status="incomplete" />
        <StepItem label={I18n.t('Submit')} status="incomplete" />
        <StepItem label={I18n.t('Not Graded Yet')} status="incomplete" />
        {context.nextButtonEnabled && !props.isCollapsed ? (
          <StepItem label={I18n.t('Next')} status="button" />
        ) : null}
      </Steps>
    </div>
  )
}

unavailableStepContainer.propTypes = {
  isCollapsed: bool
}

function uploadedStepContainer(props, context) {
  return (
    <div className="steps-container" data-testid="uploaded-step-container">
      {props.isCollapsed && renderCollapsedContainer(I18n.t('Uploaded'))}
      <Steps isCollapsed={props.isCollapsed}>
        {context.prevButtonEnabled && !props.isCollapsed ? (
          <StepItem label={I18n.t('Previous')} status="button" />
        ) : null}
        <StepItem label={I18n.t('Available')} status="complete" />
        <StepItem label={I18n.t('Uploaded')} status="complete" />
        <StepItem label={I18n.t('Submit')} status="in-progress" />
        <StepItem label={I18n.t('Not Graded Yet')} status="incomplete" />
      </Steps>
    </div>
  )
}

uploadedStepContainer.propTypes = {
  isCollapsed: bool
}

function submittedStepContainer(props, context) {
  return (
    <div className="steps-container" data-testid="submitted-step-container">
      {props.isCollapsed && renderCollapsedContainer(I18n.t('Submitted'))}
      <Steps isCollapsed={props.isCollapsed}>
        {context.prevButtonEnabled && !props.isCollapsed ? (
          <StepItem label={I18n.t('Previous')} status="button" />
        ) : null}
        <StepItem label={I18n.t('Available')} status="complete" />
        <StepItem label={I18n.t('Uploaded')} status="complete" />
        <StepItem label={I18n.t('Submitted')} status="complete" />
        <StepItem label={I18n.t('Not Graded Yet')} status="incomplete" />
        {allowNextAttempt(props.assignment, props.submission) &&
        !context.nextButtonEnabled &&
        !props.isCollapsed ? (
          <StepItem label={I18n.t('New Attempt')} status="button" />
        ) : null}
        {context.nextButtonEnabled && !props.isCollapsed ? (
          <StepItem label={I18n.t('Next')} status="button" />
        ) : null}
      </Steps>
    </div>
  )
}

submittedStepContainer.propTypes = {
  assignment: Assignment.shape,
  isCollapsed: bool,
  submission: Submission.shape
}

function gradedStepContainer(props, context) {
  return (
    <div className="steps-container" data-testid="graded-step-container">
      {props.isCollapsed && renderCollapsedContainer(I18n.t('Graded'))}
      <Steps isCollapsed={props.isCollapsed}>
        {context.prevButtonEnabled && !props.isCollapsed ? (
          <StepItem label={I18n.t('Previous')} status="button" />
        ) : null}
        <StepItem label={I18n.t('Available')} status="complete" />
        <StepItem label={I18n.t('Uploaded')} status="complete" />
        <StepItem label={I18n.t('Submitted')} status="complete" />
        <StepItem label={I18n.t('Graded')} status="complete" />
        {allowNextAttempt(props.assignment, props.submission) &&
        !context.nextButtonEnabled &&
        !props.isCollapsed ? (
          <StepItem label={I18n.t('New Attempt')} status="button" />
        ) : null}
        {context.nextButtonEnabled && !props.isCollapsed ? (
          <StepItem label={I18n.t('Next')} status="button" />
        ) : null}
      </Steps>
    </div>
  )
}

function selectStepContainer(props, context) {
  const {assignment, submission, isCollapsed, forceLockStatus} = props
  if (forceLockStatus || assignment.lockInfo.isLocked) {
    return unavailableStepContainer({isCollapsed}, context)
  } else if (submission.state === 'graded') {
    return gradedStepContainer({isCollapsed, assignment, submission}, context)
  } else if (submission.state === 'submitted') {
    return submittedStepContainer({isCollapsed, assignment, submission}, context)
  } else if (submission.submissionDraft && submission.submissionDraft.meetsAssignmentCriteria) {
    return uploadedStepContainer({isCollapsed}, context)
  }
  return availableStepContainer({isCollapsed}, context)
}

function StepContainer(props) {
  const {assignment, submission, isCollapsed, forceLockStatus} = props
  return (
    <StudentViewContext.Consumer>
      {context =>
        selectStepContainer({assignment, submission, isCollapsed, forceLockStatus}, context)
      }
    </StudentViewContext.Consumer>
  )
}

// TODO: We are calling this as a function, not through jsx. Lets make sure
//       the propType validations properly that way. If not we need to remove
//       these or actually using jsx to call them.
gradedStepContainer.propTypes = {
  assignment: Assignment.shape,
  isCollapsed: bool,
  submission: Submission.shape
}

StepContainer.propTypes = {
  assignment: Assignment.shape,
  forceLockStatus: bool,
  isCollapsed: bool,
  submission: Submission.shape
}

export default React.memo(StepContainer)
