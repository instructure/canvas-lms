/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {Table} from '@instructure/ui-table'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {Avatar} from '@instructure/ui-avatar'
import {Spinner} from '@instructure/ui-spinner'
import {IconPublishSolid, IconUnpublishedLine, IconCheckSolid} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {Course} from '../../types/course'
import {Badge} from '@instructure/ui-badge'

const I18n = createI18nScope('accessibility_course_statistics')

interface CoursesTableRowProps {
  course: Course
  showSISIds: boolean
}

const getStatusDisplay = (workflowState: Course['workflow_state']) => {
  switch (workflowState) {
    case 'available':
      return {
        tooltip: I18n.t('Published'),
        classname: 'published-course',
        icon: <IconPublishSolid size="x-small" />,
      }
    case 'completed':
      return {
        tooltip: I18n.t('Concluded'),
        classname: 'completed-course',
        icon: <IconCheckSolid size="x-small" />,
      }
    default:
      return {
        tooltip: I18n.t('Unpublished'),
        classname: 'unpublished-course',
        icon: <IconUnpublishedLine size="x-small" />,
      }
  }
}

const StatusCell: React.FC<{workflowState: Course['workflow_state']}> = ({workflowState}) => {
  const {tooltip, classname, icon} = getStatusDisplay(workflowState)

  return (
    <Table.RowHeader textAlign="center">
      <span className={`published-status ${classname}`}>
        <Tooltip renderTip={tooltip}>
          {icon}
          <ScreenReaderContent>{tooltip}</ScreenReaderContent>
        </Tooltip>
      </span>
    </Table.RowHeader>
  )
}

const CourseNameCell: React.FC<{courseId: string; courseName: string}> = ({
  courseId,
  courseName,
}) => (
  <Table.Cell>
    <Link href={`/courses/${courseId}`} isWithinText={false}>
      {courseName}
    </Link>
  </Table.Cell>
)

const SISIdCell: React.FC<{sisId?: string}> = ({sisId}) => <Table.Cell>{sisId || ''}</Table.Cell>

const TermCell: React.FC<{termName?: string}> = ({termName}) => (
  <Table.Cell>{termName || ''}</Table.Cell>
)

const TeachersCell: React.FC<{teachers?: Course['teachers']}> = ({teachers}) => {
  const [showAll, setShowAll] = useState(false)

  if (!teachers || teachers.length === 0) {
    return <Table.Cell />
  }

  const teachersToShow = showAll ? teachers : teachers.slice(0, 2)

  return (
    <Table.Cell>
      {teachersToShow.map(teacher => (
        <div key={teacher.id}>
          <Link href={teacher.html_url} isWithinText={false}>
            <Avatar
              size="x-small"
              name={teacher.display_name}
              src={teacher.avatar_image_url}
              margin="0 x-small xxx-small 0"
              data-fs-exclude={true}
            />
            {teacher.display_name}
          </Link>
        </div>
      ))}
      {teachers.length > 2 && !showAll && (
        <Link isWithinText={false} as="button" onClick={() => setShowAll(true)}>
          <Text size="small">{I18n.t('Show More')}</Text>
        </Link>
      )}
    </Table.Cell>
  )
}

const SubaccountCell: React.FC<{
  subaccountId?: string
  subaccountName?: string
}> = ({subaccountId, subaccountName}) => (
  <Table.Cell>
    {subaccountName && subaccountId ? (
      <Link href={`/accounts/${subaccountId}`} isWithinText={false}>
        {subaccountName}
      </Link>
    ) : (
      ''
    )}
  </Table.Cell>
)

const StudentCountCell: React.FC<{count?: number}> = ({count}) => (
  <Table.Cell>{count ?? 0}</Table.Cell>
)

const IssuesCell: React.FC<{statistic?: Course['accessibility_course_statistic']}> = ({
  statistic,
}) => {
  if (
    !statistic ||
    statistic.workflow_state === 'initialized' ||
    statistic.workflow_state === 'deleted'
  ) {
    return <Table.Cell>{I18n.t('No report')}</Table.Cell>
  }

  if (statistic.workflow_state === 'in_progress' || statistic.workflow_state === 'queued') {
    return (
      <Table.Cell>
        <Spinner renderTitle={I18n.t('Checking...')} size="x-small" margin="0 x-small 0 0" />
        {I18n.t('Checking...')}
      </Table.Cell>
    )
  }

  if (statistic.workflow_state === 'active') {
    const activeIssueCount = statistic.active_issue_count ?? 0
    return activeIssueCount === 0 ? (
      <Table.Cell>
        <span className="published-status published-course">
          <IconPublishSolid size="x-small" />
          <ScreenReaderContent>{I18n.t('No issues')}</ScreenReaderContent>
        </span>
      </Table.Cell>
    ) : (
      <Table.Cell>
        <Badge standalone={true} variant="danger" count={activeIssueCount}></Badge>
      </Table.Cell>
    )
  }

  if (statistic.workflow_state === 'failed') {
    return <Table.Cell>{I18n.t('Failed')}</Table.Cell>
  }

  return <Table.Cell />
}

export const CoursesTableRow: React.FC<CoursesTableRowProps> = ({course, showSISIds}) => {
  return (
    <Table.Row key={course.id}>
      <StatusCell workflowState={course.workflow_state} />
      <CourseNameCell courseId={course.id} courseName={course.name} />
      <IssuesCell statistic={course.accessibility_course_statistic} />
      {showSISIds && <SISIdCell sisId={course.sis_course_id} />}
      <TermCell termName={course.term?.name} />
      <TeachersCell teachers={course.teachers} />
      <SubaccountCell subaccountId={course.subaccount_id} subaccountName={course.subaccount_name} />
      <StudentCountCell count={course.total_students} />
    </Table.Row>
  )
}
