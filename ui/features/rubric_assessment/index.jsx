/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import Rubric from '@canvas/rubrics/react/Rubric'
import {fillAssessment} from '@canvas/rubrics/react/helpers'
import ready from '@instructure/ready'

const findRubric = id => {
  if (ENV.rubrics) {
    return ENV.rubrics.find(r => r.id === id)
  }
  return null
}

const findRubricAssessment = id => {
  if (ENV.rubric_assessments) {
    return ENV.rubric_assessments.find(r => r.id === id)
  }
  return null
}

ready(() => {
  const rubricElements = document.querySelectorAll('.react_rubric_container')
  Array.prototype.forEach.call(rubricElements, rubricElement => {
    const rubric = findRubric(rubricElement.dataset.rubricId)
    const assessment = findRubricAssessment(rubricElement.dataset.rubricAssessmentId)
    ReactDOM.render(
      <Rubric
        rubric={rubric}
        rubricAssessment={fillAssessment(rubric, assessment || {})}
        rubricAssociation={assessment.rubric_association}
        customRatings={ENV.outcome_proficiency ? ENV.outcome_proficiency.ratings : []}
        flexWidth={ENV.gradebook_non_scoring_rubrics_enabled}
      />,
      rubricElement
    )
  })
})
