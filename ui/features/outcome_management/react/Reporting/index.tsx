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

import {useMemo, useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {useStudentMasteryScores} from '@canvas/outcomes/react/hooks/useStudentMasteryScores'
import useRollups from '@canvas/outcomes/react/hooks/useRollups'
import {StudentMasteryScoreSummary} from './StudentMasteryScoreSummary'
import ReportingBreadcrumbs from './ReportingBreadcrumbs'
import StudentOutcomesTable from './StudentOutcomesTable'
import {useTransformedOutcomes} from './hooks/useTransformedOutcomes'

const I18n = createI18nScope('OutcomeManagement')

const Reporting = () => {
  const {contextId, accountLevelMasteryScalesFF} = useCanvasContext()

  const studentId = useMemo(() => {
    const params = new URLSearchParams(window.location.search)
    return params.get('student_id')
  }, [])

  const selectedUserIds = useMemo(() => {
    return studentId ? [parseInt(studentId, 10)] : []
  }, [studentId])

  const {outcomes, rollups, students, isLoading, error} = useRollups({
    courseId: contextId,
    accountMasteryScalesEnabled: accountLevelMasteryScalesFF,
    enabled: !!studentId,
    selectedUserIds,
  })

  const {outcomes: transformedOutcomes} = useTransformedOutcomes(outcomes, rollups)

  const student = useMemo(() => {
    if (!studentId || !students.length) return null
    return students.find(s => s.id === studentId) || null
  }, [studentId, students])

  const scores = useStudentMasteryScores({
    student,
    outcomes,
    rollups,
  })

  useEffect(() => {
    if (error) {
      showFlashError(I18n.t('Failed to load student details'))()
    }
  }, [error])

  if (studentId && isLoading) {
    return (
      <View data-testid="outcome-reporting" display="block" textAlign="center">
        <Spinner renderTitle={I18n.t('Loading student details')} size="large" />
      </View>
    )
  }

  return (
    <View data-testid="outcome-reporting" padding="small 0" display="block">
      <ReportingBreadcrumbs />

      {student && scores && (
        <StudentMasteryScoreSummary
          studentName={student.name || I18n.t('Student')}
          studentEmail={student.login_id}
          studentAvatarUrl={student.avatar_url}
          masteryLevel={{
            score: scores.grossAverage || 0,
            text: scores.averageText,
            iconUrl: scores.averageIconURL,
          }}
          buckets={scores.buckets}
        />
      )}

      <StudentOutcomesTable outcomes={transformedOutcomes} />
    </View>
  )
}

export default Reporting
