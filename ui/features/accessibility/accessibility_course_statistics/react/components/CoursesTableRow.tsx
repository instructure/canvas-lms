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
import {
  IconPublishSolid,
  IconUnpublishedLine,
  IconCheckSolid,
  IconWarningLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {Course} from '../../types/course'
import {Badge, BadgeProps} from '@instructure/ui-badge'
import {Flex} from '@instructure/ui-flex'

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

const SISIdCell: React.FC<{sisId?: string}> = ({sisId}) => (
  <Table.Cell data-testid="sis-id-cell">{sisId || ''}</Table.Cell>
)

const TermCell: React.FC<{termName?: string}> = ({termName}) => (
  <Table.Cell data-testid="term-cell">{termName || ''}</Table.Cell>
)

const TeachersCell: React.FC<{teachers?: Course['teachers']}> = ({teachers}) => {
  const [showAll, setShowAll] = useState(false)
  const nonNullTeachers = teachers ?? []
  const teachersToShow = showAll ? nonNullTeachers : nonNullTeachers.slice(0, 2)

  return (
    <Table.Cell data-testid="teachers-cell">
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
      {nonNullTeachers.length > 2 && !showAll && (
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
  <Table.Cell data-testid="subaccount-cell">
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
  <Table.Cell data-testid="student-count-cell">{count ?? 0}</Table.Cell>
)

const NoReportContent: React.FC = () => <>{I18n.t('No report')}</>

const CheckingContent: React.FC = () => (
  <Flex gap="x-small">
    <Spinner renderTitle={I18n.t('Checking...')} size="x-small" />
    {I18n.t('Checking...')}
  </Flex>
)

const NoIssuesContent: React.FC = () => (
  <span className="published-status published-course">
    <IconPublishSolid size="x-small" />
    <ScreenReaderContent>{I18n.t('No issues')}</ScreenReaderContent>
  </span>
)

const IssuesBadgeContent: React.FC<{count: number; variant: BadgeProps['variant']}> = ({
  count,
  variant,
}) => <Badge standalone={true} variant={variant} count={count}></Badge>

const FailedContent: React.FC = () => (
  <Flex gap="x-small">
    <IconWarningLine size="x-small" color="error" />
    {I18n.t('Failed scan')}
  </Flex>
)

const ActiveIssuesCell: React.FC<{statistic?: Course['accessibility_course_statistic']}> = ({
  statistic,
}) => {
  const renderContent = () => {
    if (!statistic) {
      return <NoReportContent />
    }

    switch (statistic.workflow_state) {
      case 'in_progress':
      case 'queued':
        return <CheckingContent />
      case 'active': {
        const issueCount = statistic.active_issue_count ?? 0
        return issueCount === 0 ? (
          <NoIssuesContent />
        ) : (
          <IssuesBadgeContent variant="danger" count={issueCount} />
        )
      }
      case 'failed':
        return <FailedContent />
      case 'initialized':
      case 'deleted':
      default:
        return <NoReportContent />
    }
  }

  return <Table.Cell data-testid="issues-cell">{renderContent()}</Table.Cell>
}

const ResolvedIssuesCell: React.FC<{statistic?: Course['accessibility_course_statistic']}> = ({
  statistic,
}) => {
  const issueCount = statistic?.resolved_issue_count ?? 0
  return (
    <Table.Cell data-testid="resolved-issues-cell">
      {issueCount === 0 ? null : <IssuesBadgeContent variant="success" count={issueCount} />}
    </Table.Cell>
  )
}

export const CoursesTableRow: React.FC<CoursesTableRowProps> = ({course, showSISIds}) => {
  return (
    <Table.Row key={course.id}>
      <StatusCell workflowState={course.workflow_state} />
      <CourseNameCell courseId={course.id} courseName={course.name} />
      <ActiveIssuesCell statistic={course.accessibility_course_statistic} />
      <ResolvedIssuesCell statistic={course.accessibility_course_statistic} />
      {showSISIds && <SISIdCell sisId={course.sis_course_id} />}
      <TermCell termName={course.term?.name} />
      <TeachersCell teachers={course.teachers} />
      <SubaccountCell subaccountId={course.subaccount_id} subaccountName={course.subaccount_name} />
      <StudentCountCell count={course.total_students} />
    </Table.Row>
  )
}
