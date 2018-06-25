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
import Rubric from '../rubrics/Rubric'

import 'rubric_assessment'

const findRubric = (id) => {
  if (ENV.rubrics) {
    return ENV.rubrics.find((r) => (r.id === id))
  }
  return null
}

const findRubricAssessment = (id) => {
  if (ENV.rubric_assessments) {
    return ENV.rubric_assessments.find((r) => (r.id === id))
  }
  return null
}

const rubricElements = document.querySelectorAll(".react_rubric_container")
Array.prototype.forEach.call(rubricElements, (rubricElement) => {
  const assessment = findRubricAssessment(rubricElement.dataset.rubricAssessmentId)
  ReactDOM.render((
    <Rubric
      rubric={findRubric(rubricElement.dataset.rubricId)}
      rubricAssessment={assessment}
      rubricAssociation={assessment.rubric_association}
      customRatings={ENV.outcome_proficiency ? ENV.outcome_proficiency.ratings : []}
    />
  ), rubricElement)
})
