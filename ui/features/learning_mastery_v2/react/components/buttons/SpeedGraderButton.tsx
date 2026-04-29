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

import React from 'react'
import {Button} from '@instructure/ui-buttons'
import {IconSpeedGraderLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface SpeedGraderButtonProps {
  courseId: string
  assignmentId: string
  studentId?: string
  disabled?: boolean
}

export const SpeedGraderButton: React.FC<SpeedGraderButtonProps> = ({
  courseId,
  assignmentId,
  studentId,
  disabled = false,
}) => {
  const assignmentParam = `assignment_id=${assignmentId}`
  const studentParam = studentId ? `student_id=${studentId}` : ''
  const speedGraderUrlParams = studentParam ? `${assignmentParam}&${studentParam}` : assignmentParam
  const speedGraderUrl = encodeURI(
    `/courses/${courseId}/gradebook/speed_grader?${speedGraderUrlParams}`,
  )

  return (
    <Button
      href={speedGraderUrl}
      renderIcon={<IconSpeedGraderLine />}
      disabled={disabled}
      target="_blank"
      rel="noopener"
    >
      {I18n.t('SpeedGrader')}
    </Button>
  )
}
