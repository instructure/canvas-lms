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
import { connect } from 'react-redux'
import { StoreState, PaceContext } from '../../types'
import { Pill } from '@instructure/ui-pill'
import { Flex } from '@instructure/ui-flex'
import { getIsDraftPace, getCoursePaceItems } from '../../reducers/course_paces'
import { isBulkEnrollment } from '../../reducers/pace_contexts'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_stats')

interface CourseStatsProps {
  readonly assignmentsCount: number
  readonly isDraftPace: boolean
  readonly paceContext: PaceContext
  readonly isBulkEnrollment: boolean
}

export const CourseStats = ({
  assignmentsCount,
  isDraftPace,
  paceContext,
  isBulkEnrollment
}: CourseStatsProps) => {
  const StatusElement = ({ title, statValue, dataTestId }: { title: string, statValue: string | number, dataTestId: string }) => {

    return (
      <Flex.Item>
        <Pill statusLabel={title} data-testid={dataTestId}>
          {statValue}
        </Pill>
      </Flex.Item>
    )
  }
  return (
    <Flex gap="small" margin="small none" data-testid="course-stats-info">
      {isDraftPace &&
        <StatusElement title={I18n.t('Status')} statValue={I18n.t('Draft')} dataTestId='status-draft' />
      }
      {
        paceContext.type !== "StudentEnrollment" && !isBulkEnrollment &&
        <StatusElement title={I18n.t('Students Enrolled')} statValue={paceContext?.associated_student_count} dataTestId='student-enrollment-count' />
      }
      {
        isBulkEnrollment &&
        <StatusElement title={I18n.t('Students in Bulk Edit')} statValue={paceContext?.associated_student_count} dataTestId='bulk-student-enrollment-count' />
      }
      <StatusElement title={I18n.t('Assignment Count')} statValue={assignmentsCount} dataTestId='assignments-count' />
    </Flex>
  )
}

const mapStateToProps = (state: StoreState) => {
  return {
    assignmentsCount: getCoursePaceItems(state).length,
    isDraftPace: getIsDraftPace(state),
    isBulkEnrollment: isBulkEnrollment(state)
  }
}

export default connect(mapStateToProps)(CourseStats)
