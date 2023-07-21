/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {arrayOf, bool} from 'prop-types'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import {fillAssessment} from '@canvas/rubrics/react/helpers'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ProficiencyRating} from '@canvas/assignments/graphql/student/ProficiencyRating'
import React from 'react'
import {Rubric} from '@canvas/assignments/graphql/student/Rubric'
import {RubricAssessment} from '@canvas/assignments/graphql/student/RubricAssessment'
import {RubricAssociation} from '@canvas/assignments/graphql/student/RubricAssociation'
import RubricComponent from '@canvas/rubrics/react/Rubric'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import useStore from './stores/index'

const I18n = useI18nScope('assignments_2')

const ENROLLMENT_STRINGS = {
  StudentEnrollment: I18n.t('Student'),
  TeacherEnrollment: I18n.t('Teacher'),
  TaEnrollment: I18n.t('TA'),
}

function formatAssessor(assessor) {
  if (!assessor?.name) {
    return I18n.t('Anonymous')
  }

  const enrollment = ENROLLMENT_STRINGS[assessor.enrollments?.[0]?.type]
  return enrollment ? `${assessor.name} (${enrollment})` : assessor.name
}

export default function RubricTab(props) {
  const displayedAssessment = useStore(state => state.displayedAssessment)

  const findAssessmentById = id => {
    return props.assessments?.find(assessment => assessment._id === id)
  }

  const onAssessmentChange = updatedAssessment => {
    useStore.setState({displayedAssessment: updatedAssessment})
  }

  const assessmentSelectorChanged = assessmentId => {
    const assessment = findAssessmentById(assessmentId)
    const filledAssessment = fillAssessment(props.rubric, assessment || {})
    useStore.setState({displayedAssessment: filledAssessment})
  }

  const hasSubmittedAssessment = props.assessments?.some(
    assessment => assessment.assessor?._id === ENV.current_user.id
  )

  return (
    <div data-testid="rubric-tab">
      <View as="div" margin="none none medium">
        {props.peerReviewModeEnabled && !hasSubmittedAssessment && (
          <Alert variant="info" hasShadow={false}>
            {I18n.t(
              'Fill out the rubric below after reviewing the student submission to complete this review.'
            )}
          </Alert>
        )}
        <ToggleDetails
          defaultExpanded={true}
          fluidWidth={true}
          data-testid="fill-out-rubric-toggle"
          summary={
            <Text weight="bold">
              {props.peerReviewModeEnabled ? I18n.t('Fill Out Rubric') : I18n.t('View Rubric')}
            </Text>
          }
        >
          {!props.peerReviewModeEnabled && !!props.assessments?.length && (
            <div style={{marginBottom: '22px', width: '325px'}}>
              <CanvasSelect
                label={I18n.t('Select Grader')}
                value={displayedAssessment?._id}
                data-testid="select-grader-dropdown"
                onChange={(e, optionValue) => assessmentSelectorChanged(optionValue)}
              >
                {props.assessments.map(assessment => (
                  <CanvasSelect.Option
                    key={assessment._id}
                    value={assessment._id}
                    id={assessment._id}
                  >
                    {formatAssessor(assessment.assessor)}
                  </CanvasSelect.Option>
                ))}
              </CanvasSelect>
            </div>
          )}

          {props.rubric && (
            <RubricComponent
              customRatings={props.proficiencyRatings}
              rubric={props.rubric}
              rubricAssessment={displayedAssessment}
              rubricAssociation={props.rubricAssociation}
              onAssessmentChange={
                props.peerReviewModeEnabled && !hasSubmittedAssessment ? onAssessmentChange : null
              }
            />
          )}
        </ToggleDetails>
      </View>
    </div>
  )
}

RubricTab.propTypes = {
  assessments: arrayOf(RubricAssessment.shape),
  proficiencyRatings: arrayOf(ProficiencyRating.shape),
  rubric: Rubric.shape,
  rubricAssociation: RubricAssociation.shape,
  peerReviewModeEnabled: bool,
}

RubricTab.defaultProps = {
  peerReviewModeEnabled: false,
}
