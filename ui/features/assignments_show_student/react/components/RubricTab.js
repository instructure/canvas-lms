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
import {arrayOf} from 'prop-types'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import {fillAssessment} from '@canvas/rubrics/react/helpers'
import I18n from 'i18n!assignments_2'
import {ProficiencyRating} from '@canvas/assignments/graphql/student/ProficiencyRating'
import React, {useMemo, useState} from 'react'
import {Rubric} from '@canvas/assignments/graphql/student/Rubric'
import {RubricAssessment} from '@canvas/assignments/graphql/student/RubricAssessment'
import {RubricAssociation} from '@canvas/assignments/graphql/student/RubricAssociation'
import RubricComponent from '@canvas/rubrics/react/Rubric'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-layout'

const ENROLLMENT_STRINGS = {
  StudentEnrollment: I18n.t('Student'),
  TeacherEnrollment: I18n.t('Teacher'),
  TaEnrollment: I18n.t('TA')
}

function transformRubricData(rubric) {
  const rubricCopy = JSON.parse(JSON.stringify(rubric))
  rubricCopy.criteria.forEach(criterion => {
    if (criterion.outcome) {
      criterion.learning_outcome_id = criterion.outcome._id
    }
    delete criterion.outcome
  })
  return rubricCopy
}

function transformRubricAssessmentData(rubricAssessment) {
  const assessmentCopy = JSON.parse(JSON.stringify(rubricAssessment))
  assessmentCopy.data.forEach(rating => {
    rating.criterion_id = rating.criterion ? rating.criterion.id : null
    rating.learning_outcome_id = rating.outcome ? rating.outcome._id : null
    delete rating.criterion
    delete rating.outcome
  })
  return assessmentCopy
}

function formatAssessor(assessor) {
  if (!assessor?.name) {
    return I18n.t('Anonymous')
  }

  const enrollment = ENROLLMENT_STRINGS[assessor.enrollments?.[0]?.type]
  return enrollment ? `${assessor.name} (${enrollment})` : assessor.name
}

export default function RubricTab(props) {
  // We need to hoist the learning_outcome_id up one level to match the expected
  // props in the `<RubricComponent>`. Memoize this so we don't need to do it on
  // every render
  const rubric = useMemo(() => transformRubricData(props.rubric), [props.rubric])
  const assessments = useMemo(
    () => props.assessments?.map(assessment => transformRubricAssessmentData(assessment)),
    [props.assessments]
  )
  const [displayedAssessmentId, setDisplayedAssessmentId] = useState(assessments?.[0]?._id)

  // This will always be undefined if there are no assessments, or the displayed
  // assessments if any assessments are present
  const displayedAssessment = assessments?.find(
    assessment => assessment._id === displayedAssessmentId
  )

  return (
    <div data-testid="rubric-tab">
      <View as="div" margin="none none medium">
        <ToggleDetails
          defaultExpanded={displayedAssessment != null}
          fluidWidth
          summary={<Text weight="bold">{I18n.t('View Rubric')}</Text>}
        >
          {!!assessments?.length && (
            <div style={{marginBottom: '22px', width: '325px'}}>
              <CanvasSelect
                label={I18n.t('Select Grader')}
                value={displayedAssessment._id}
                onChange={(e, optionValue) => setDisplayedAssessmentId(optionValue)}
              >
                {assessments.map(assessment => (
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

          <RubricComponent
            customRatings={props.proficiencyRatings}
            rubric={rubric}
            rubricAssessment={fillAssessment(rubric, displayedAssessment || {})}
            rubricAssociation={props.rubricAssociation}
          />
        </ToggleDetails>
      </View>
    </div>
  )
}

RubricTab.propTypes = {
  assessments: arrayOf(RubricAssessment.shape),
  proficiencyRatings: arrayOf(ProficiencyRating.shape),
  rubric: Rubric.shape,
  rubricAssociation: RubricAssociation.shape
}
