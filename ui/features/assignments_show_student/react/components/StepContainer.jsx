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

import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import {bool} from 'prop-types'
import React from 'react'
import StepItem, {stepLabels} from '../Steps/StepItem/index'
import Steps from '../Steps/index'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {Text} from '@instructure/ui-text'

function renderCollapsedContainer(step) {
  return (
    <div className="steps-main-status-label" data-testid="collapsed-step-container">
      <Text weight="bold">{step}</Text>
    </div>
  )
}

function availableStepContainer(props) {
  return (
    <div className="steps-container" data-testid="available-step-container">
      {props.isCollapsed && renderCollapsedContainer(stepLabels.available)}
      <Steps isCollapsed={props.isCollapsed}>
        {props.assignment.lockInfo.isLocked ? (
          <StepItem label={stepLabels.unavailable} status="unavailable" />
        ) : (
          <StepItem label={stepLabels.available} status="complete" />
        )}
        <StepItem
          label={stepLabels.upload}
          status={props.assignment.lockInfo.isLocked ? 'incomplete' : 'in-progress'}
        />
        <StepItem label={stepLabels.submit} status="incomplete" />
        <StepItem label={stepLabels.notGradedYet} status="incomplete" />
      </Steps>
    </div>
  )
}

availableStepContainer.propTypes = {
  assignment: Assignment.shape,
  isCollapsed: bool,
}

function unavailableStepContainer(props) {
  return (
    <div className="steps-container" data-testid="unavailable-step-container">
      {props.isCollapsed && renderCollapsedContainer(stepLabels.unavailable)}
      <Steps isCollapsed={props.isCollapsed}>
        <StepItem label={stepLabels.unavailable} status="unavailable" />
        <StepItem label={stepLabels.upload} status="incomplete" />
        <StepItem label={stepLabels.submit} status="incomplete" />
        <StepItem label={stepLabels.notGradedYet} status="incomplete" />
      </Steps>
    </div>
  )
}

unavailableStepContainer.propTypes = {
  isCollapsed: bool,
}

function uploadedStepContainer(props) {
  return (
    <div className="steps-container" data-testid="uploaded-step-container">
      {props.isCollapsed && renderCollapsedContainer(stepLabels.uploaded)}
      <Steps isCollapsed={props.isCollapsed}>
        {props.assignment.lockInfo.isLocked ? null : (
          <StepItem label={stepLabels.available} status="complete" />
        )}
        <StepItem label={stepLabels.uploaded} status="complete" />
        <StepItem
          label={stepLabels.submit}
          status={props.assignment.lockInfo.isLocked ? 'unavailable' : 'in-progress'}
        />
        <StepItem label={stepLabels.notGradedYet} status="incomplete" />
      </Steps>
    </div>
  )
}

uploadedStepContainer.propTypes = {
  assignment: Assignment.shape,
  isCollapsed: bool,
}

function submittedStepContainer(props) {
  return (
    <div className="steps-container" data-testid="submitted-step-container">
      {props.isCollapsed && renderCollapsedContainer(stepLabels.submitted)}
      <Steps isCollapsed={props.isCollapsed}>
        {props.assignment.lockInfo.isLocked ? null : (
          <StepItem label={stepLabels.available} status="complete" />
        )}
        <StepItem label={stepLabels.uploaded} status="complete" />
        <StepItem label={stepLabels.submitted} status="complete" />
        <StepItem label={stepLabels.notGradedYet} status="incomplete" />
      </Steps>
    </div>
  )
}

submittedStepContainer.propTypes = {
  assignment: Assignment.shape,
  isCollapsed: bool,
  submission: Submission.shape,
}

function gradedStepContainer(props) {
  return (
    <div className="steps-container" data-testid="graded-step-container">
      {props.isCollapsed && renderCollapsedContainer(stepLabels.graded)}
      <Steps isCollapsed={props.isCollapsed}>
        {props.assignment.lockInfo.isLocked ? null : (
          <StepItem label={stepLabels.available} status="complete" />
        )}
        <StepItem label={stepLabels.uploaded} status="complete" />
        <StepItem label={stepLabels.submitted} status="complete" />
        <StepItem label={stepLabels.graded} status="complete" />
      </Steps>
    </div>
  )
}

function selectStepContainer(props) {
  const {assignment, submission, isCollapsed, forceLockStatus} = props
  if (!submission || forceLockStatus) {
    return unavailableStepContainer({isCollapsed})
  } else if (submission.state === 'graded') {
    return gradedStepContainer({isCollapsed, assignment, submission})
  } else if (submission.state === 'submitted') {
    return submittedStepContainer({isCollapsed, assignment, submission})
  } else if (submission.submissionDraft && submission.submissionDraft.meetsAssignmentCriteria) {
    return uploadedStepContainer({assignment, isCollapsed})
  }
  return availableStepContainer({assignment, isCollapsed})
}

export default function StepContainer({assignment, submission, isCollapsed, forceLockStatus}) {
  return selectStepContainer({assignment, submission, isCollapsed, forceLockStatus})
}

// TODO: We are calling this as a function, not through jsx. Lets make sure
//       the propType validations properly that way. If not we need to remove
//       these or actually using jsx to call them.
gradedStepContainer.propTypes = {
  assignment: Assignment.shape,
  isCollapsed: bool,
  submission: Submission.shape,
}

StepContainer.propTypes = {
  assignment: Assignment.shape,
  forceLockStatus: bool,
  isCollapsed: bool,
  submission: Submission.shape,
}
