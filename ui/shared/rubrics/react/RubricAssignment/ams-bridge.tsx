/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import type {Root} from 'react-dom/client'
import {render, rerender} from '@canvas/react'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import {Alert} from '@instructure/ui-alerts'
import {RubricAssignmentContainer} from './components/RubricAssignmentContainer'
import type {RubricAssignmentContainerProps} from './components/RubricAssignmentContainer'
import {useAssignmentRubric} from './hooks/useAssignmentRubric'
import type {Rubric} from '../types/rubric'
import {useEffect} from 'react'

type ENVType = {
  COURSE_ID: string
  PERMISSIONS: {
    manage_rubrics: boolean
  }
  ai_rubrics_enabled: boolean
  current_user_id: string
  rubric_self_assessment_ff_enabled: boolean
}
declare const ENV: ENVType

/**
 * Internal Canvas wrapper component that fetches all data internally
 */
function CanvasRubricBridge({
  assignmentId,
  assignmentPointsPossible,
  onRubricChange,
  onRubricLoaded,
}: AmsRubricConfig) {
  const courseId = ENV.COURSE_ID
  const currentUserId = ENV.current_user_id

  const {
    data: rubricData,
    isLoading: rubricLoading,
    error: rubricError,
  } = useAssignmentRubric(courseId, assignmentId)

  // Get configuration values from ENV
  const canManageRubrics = ENV.PERMISSIONS.manage_rubrics
  const rubricSelfAssessmentFFEnabled = ENV.rubric_self_assessment_ff_enabled
  const aiRubricsEnabled = ENV.ai_rubrics_enabled

  useEffect(() => {
    onRubricLoaded()
  }, [rubricData, onRubricLoaded])

  const handleOnRubricChange = (rubric: Rubric | undefined) => {
    onRubricChange(!!rubric)
  }

  // Handle error state
  if (rubricError) {
    return <Alert variant="error">{rubricError.message || 'Failed to load rubric'}</Alert>
  }

  return (
    <>
      {!rubricLoading && (
        <RubricAssignmentContainer
          assignmentId={assignmentId}
          courseId={courseId}
          currentUserId={currentUserId}
          assignmentPointsPossible={assignmentPointsPossible}
          assignmentRubric={rubricData?.rubric}
          assignmentRubricAssociation={rubricData?.rubricAssociation}
          canManageRubrics={canManageRubrics}
          rubricSelfAssessmentFFEnabled={rubricSelfAssessmentFFEnabled}
          aiRubricsEnabled={aiRubricsEnabled}
          onRubricChange={handleOnRubricChange}
          containerStyles={{width: '100%'}}
        />
      )}
    </>
  )
}

export type AmsRubricConfig = {
  assignmentId: string
  assignmentPointsPossible: number
  onRubricChange: (isAdded: boolean) => void
  onRubricLoaded: () => void
}

/**
 * Controller for managing the rubric component lifecycle
 */
export type RubricController = {
  render: (config: AmsRubricConfig) => void
  unmount: () => void
}

/**
 * Create a rubric controller for a DOM container
 *
 * This approach avoids React version mismatch issues by letting Canvas
 * render the component into a DOM node using Canvas's own React instance.
 *
 * @param container - DOM element to render into
 * @returns Controller object with render and unmount methods
 */
export function createRubricController(container: HTMLElement): RubricController {
  let root: Root | null = render(
    <QueryClientProvider client={queryClient}>
      <CanvasRubricBridge
        assignmentId=""
        assignmentPointsPossible={0}
        onRubricChange={() => {}}
        onRubricLoaded={() => {}}
      />
    </QueryClientProvider>,
    container,
  )

  return {
    render: (config: AmsRubricConfig) => {
      if (!root) {
        root = render(
          <QueryClientProvider client={queryClient}>
            <CanvasRubricBridge
              assignmentId={config.assignmentId}
              assignmentPointsPossible={config.assignmentPointsPossible}
              onRubricChange={config.onRubricChange}
              onRubricLoaded={config.onRubricLoaded}
            />
          </QueryClientProvider>,
          container,
        )
      } else {
        rerender(
          root,
          <QueryClientProvider client={queryClient}>
            <CanvasRubricBridge
              assignmentId={config.assignmentId}
              assignmentPointsPossible={config.assignmentPointsPossible}
              onRubricChange={config.onRubricChange}
              onRubricLoaded={config.onRubricLoaded}
            />
          </QueryClientProvider>,
        )
      }
    },

    unmount: () => {
      if (root) {
        root.unmount()
        root = null
      }
    },
  }
}

export type {RubricAssignmentContainerProps}
