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
import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Outcome, Student, StudentRollupData} from '@canvas/outcomes/react/types/rollup'
import {View} from '@instructure/ui-view'
import TruncateWithTooltip from '@canvas/instui-bindings/react/TruncateWithTooltip'
import {AssignmentSection} from './AssignmentSection'
import {NavigatorProps} from './Navigator'
import {StudentSection} from './StudentSection'
import {OutcomeResultSection} from './OutcomeResultSection'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface StudentAssignmentDetailTrayProps {
  open: boolean
  onDismiss: () => void
  outcome: Outcome
  courseId: string
  student: Student
  assignment: {
    id: string
    name: string
    htmlUrl: string
  }
  assignmentNavigator: NavigatorProps
  studentNavigator: NavigatorProps
  rollups: StudentRollupData[]
  outcomes: Outcome[]
}

const TrayHeader = ({title, onClose}: {title: string; onClose: () => void}) => (
  <Flex direction="row" data-testid="tray-header" padding="none none small">
    <Flex.Item>
      <CloseButton
        size="small"
        screenReaderLabel={I18n.t('Close Student Assignment Details')}
        onClick={onClose}
        data-testid="close-tray-button"
      />
    </Flex.Item>
    <Flex.Item shouldGrow={true} shouldShrink={true}>
      <View as="div" textAlign="center">
        <Text weight="bold">
          <TruncateWithTooltip>{title}</TruncateWithTooltip>
        </Text>
      </View>
    </Flex.Item>
  </Flex>
)

export const StudentAssignmentDetailTray: React.FC<StudentAssignmentDetailTrayProps> = ({
  open,
  onDismiss,
  outcome,
  courseId,
  student,
  assignment,
  assignmentNavigator,
  studentNavigator,
  rollups,
  outcomes,
}) => {
  return (
    <Tray
      label={I18n.t('Student Assignment Details')}
      placement="end"
      size="small"
      open={open}
      onDismiss={onDismiss}
      data-testid="student-assignment-detail-tray"
    >
      <Flex direction="column" padding="medium">
        <TrayHeader title={outcome.title} onClose={onDismiss} />
        <AssignmentSection
          courseId={courseId}
          studentId={student.id}
          currentAssignment={{
            id: assignment.id,
            name: assignment.name,
            htmlUrl: assignment.htmlUrl,
          }}
          hasPrevious={assignmentNavigator.hasPrevious}
          hasNext={assignmentNavigator.hasNext}
          onPrevious={assignmentNavigator.onPrevious}
          onNext={assignmentNavigator.onNext}
        />
        <hr />
        <StudentSection
          currentStudent={student}
          masteryReportUrl={`/courses/${courseId}/grades/${student.id}#tab-outcomes`}
          hasPrevious={studentNavigator.hasPrevious}
          hasNext={studentNavigator.hasNext}
          onPrevious={studentNavigator.onPrevious}
          onNext={studentNavigator.onNext}
        />
        <hr />
        <OutcomeResultSection
          courseId={courseId}
          studentId={student.id}
          assignmentId={assignment.id}
          rollups={rollups}
          outcomes={outcomes}
        />
      </Flex>
    </Tray>
  )
}
