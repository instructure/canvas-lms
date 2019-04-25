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

import {bool} from 'prop-types'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import FriendlyDatetime from '../../../shared/FriendlyDatetime'
import GradeDisplay from './GradeDisplay'
import I18n from 'i18n!assignments_2_student_header_date_title'
import {StudentAssignmentShape} from '../assignmentData'
import Text from '@instructure/ui-elements/lib/components/Text'

import React from 'react'
import StepItem from '../../shared/Steps/StepItem'
import Steps from '../../shared/Steps'

function renderCollapsedContainer(step) {
  return (
    <div className="steps-main-status-label">
      <Text weight="bold">{step}</Text>
    </div>
  )
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
      {props.isCollapsed && renderCollapsedContainer(I18n.t('Unvailable'))}
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
                  dateTime={props.assignment.submissionsConnection.nodes[0].submittedAt}
                />
              </FlexItem>
            </Flex>
          }
          status="complete"
        />
        <StepItem label={I18n.t('Not Graded Yet')} />
      </Steps>
    </div>
  )
}

submittedStepContainer.propTypes = {
  assignment: StudentAssignmentShape,
  isCollapsed: bool
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
                  dateTime={props.assignment.submissionsConnection.nodes[0].submittedAt}
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
                  receivedGrade={props.assignment.submissionsConnection.nodes[0].grade}
                />
              </FlexItem>
            </Flex>
          }
          status="complete"
        />
      </Steps>
    </div>
  )
}

gradedStepContainer.propTypes = {
  assignment: StudentAssignmentShape,
  isCollapsed: bool
}

function StepContainer(props) {
  const {assignment, isCollapsed, forceLockStatus} = props

  // TODO: render the step-container based on the actual assignment data.
  if (forceLockStatus || assignment.lockInfo.isLocked) {
    return unavailableStepContainer({isCollapsed})
  } else if (assignment.submissionsConnection.nodes[0].state === 'graded') {
    return gradedStepContainer({isCollapsed, assignment})
  } else if (assignment.submissionsConnection.nodes[0].state === 'submitted') {
    return submittedStepContainer({isCollapsed, assignment})
  } else {
    return availableStepContainer({isCollapsed})
  }
}

StepContainer.propTypes = {
  assignment: StudentAssignmentShape,
  forceLockStatus: bool
}

export default React.memo(StepContainer)
