/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, rerender} from '@canvas/react'
import type {Root} from 'react-dom/client'
import {RubricAssignmentContainer} from '@canvas/rubrics/react/RubricAssignment'
import {
  mapRubricUnderscoredKeysToCamelCase,
  mapRubricAssociationUnderscoredKeysToCamelCase,
  RubricUnderscoreType,
  RubricAssociationUnderscore,
} from '@canvas/rubrics/react/utils'

type ENVType = {
  ACCOUNT_LEVEL_MASTERY_SCALES: boolean
  ASSIGNMENT_ID: string
  ASSIGNMENT_POINTS?: number
  COURSE_ID: string
  PERMISSIONS: {
    manage_rubrics: boolean
  }
  ai_rubrics_enabled: boolean
  assigned_rubric: RubricUnderscoreType & {
    can_update: boolean
    association_count: number
    [key: string]: any
  }
  rubric_association: RubricAssociationUnderscore
  rubric_self_assessment_ff_enabled: boolean
  context_asset_string: string
  current_user_id: string
}
declare const ENV: ENVType

const roots = new Map<string, Root>()
function createOrUpdateRoot(elementId: string, component: React.ReactElement) {
  const container = document.getElementById(elementId)
  if (!container) return

  let root = roots.get(elementId)
  if (!root) {
    root = render(component, container)
    roots.set(elementId, root)
  } else {
    rerender(root, component)
  }
}

export const renderEnhancedRubrics = () => {
  const $mountPoint = document.getElementById('enhanced-rubric-assignment-edit-mount-point')

  if ($mountPoint) {
    const envRubric = ENV.assigned_rubric
    const envRubricAssociation = ENV.rubric_association
    const assignmentRubric = envRubric
      ? {
          ...mapRubricUnderscoredKeysToCamelCase(ENV.assigned_rubric),
          can_update: ENV.assigned_rubric?.can_update,
          association_count: ENV.assigned_rubric?.association_count,
        }
      : undefined
    const assignmentRubricAssociation = envRubricAssociation
      ? mapRubricAssociationUnderscoredKeysToCamelCase(ENV.rubric_association)
      : undefined

    createOrUpdateRoot(
      'enhanced-rubric-assignment-edit-mount-point',
      <RubricAssignmentContainer
        assignmentId={ENV.ASSIGNMENT_ID}
        assignmentPointsPossible={ENV.ASSIGNMENT_POINTS}
        assignmentRubric={assignmentRubric}
        assignmentRubricAssociation={assignmentRubricAssociation}
        canManageRubrics={ENV.PERMISSIONS?.manage_rubrics}
        courseId={ENV.COURSE_ID}
        currentUserId={ENV.current_user_id}
        rubricSelfAssessmentFFEnabled={ENV.rubric_self_assessment_ff_enabled}
        aiRubricsEnabled={ENV.ai_rubrics_enabled}
      />,
    )
  }
}
