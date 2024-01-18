/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {IconCheckDarkSolid, IconXSolid} from '@instructure/ui-icons'
import {AccessibleContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Badge} from '@instructure/ui-badge'
import {getK5ThemeVars} from '@canvas/k5/react/k5-theme'

const k5ThemeVariables = getK5ThemeVars()

const I18n = useI18nScope('grade_row')

// For the instui Table to render correctly with layout="stacked", (see GradeDetails)
// its body's children must be Table.Rows. It doesn't work to trick it by setting
// displayName="row".
// For this reason GradeRow is plain old js function and not a React function component.
// Except for having no PropTypes, the code is exactly the same.

/*
 * ***** CAUTION:  this looks like a React component but is not called like one!
 * ***** CAUTION:  if modifying this, do not try to add any React Hooks, they will not work!
 */

export const GradeRow = ({
  id,
  assignmentName,
  url,
  dueDate,
  assignmentGroupName,
  pointsPossible,
  gradingType,
  grade,
  submissionDate,
  unread,
  late,
  excused,
  missing,
  hasComments,
  currentUserId,
  isStacked,
  dateFormatter,
  restrictQuantitativeData,
}) => {
  const cellTheme = isStacked ? {padding: '.5rem .75rem'} : undefined

  const renderStatus = () => {
    if (late) {
      return (
        <Text color="brand" size="small">
          {submissionDate
            ? I18n.t('Late %{date}', {
                date: dateFormatter(submissionDate),
              })
            : I18n.t('Late')}
        </Text>
      )
    }
    if (missing) {
      return (
        <Text color="danger" size="small">
          {I18n.t('Missing')}
        </Text>
      )
    }
    if (submissionDate) {
      return (
        <Text color="success" size="small">
          {I18n.t('Submitted %{date}', {
            date: dateFormatter(submissionDate),
          })}
        </Text>
      )
    }
    return null
  }

  const notGradedContent = (visualIndicator = I18n.t('—')) => (
    <AccessibleContent alt={I18n.t('Not graded')}>
      <Text>{visualIndicator}</Text>
    </AccessibleContent>
  )

  const renderScore = () => {
    if (excused) {
      return <Text>{I18n.t('Excused')}</Text>
    }

    const notGraded = grade == null
    const gradeString = notGraded ? '—' : grade

    switch (gradingType) {
      case 'points':
        return notGraded ? (
          notGradedContent(I18n.t('— pts'))
        ) : (
          <Text>{I18n.t('%{score} pts', {score: gradeString})}</Text>
        )
      case 'gpa_scale':
        return notGraded ? (
          notGradedContent(I18n.t('— GPA'))
        ) : (
          <Text>{I18n.t('%{gpa} GPA', {gpa: gradeString})}</Text>
        )
      case 'pass_fail':
        return notGraded ? (
          notGradedContent()
        ) : grade === 'complete' ? (
          <AccessibleContent alt={I18n.t('Complete')}>
            <IconCheckDarkSolid />
          </AccessibleContent>
        ) : (
          <AccessibleContent alt={I18n.t('Incomplete')}>
            <IconXSolid />
          </AccessibleContent>
        )
      case 'not_graded':
        return (
          <AccessibleContent alt={I18n.t('Ungraded assignment')}>
            <Text>--</Text>
          </AccessibleContent>
        )
      default:
        // Handles 'percent', 'letter_grade'
        return notGraded ? (
          notGradedContent()
        ) : grade === 'complete' ? (
          <AccessibleContent alt={I18n.t('Complete')}>
            <IconCheckDarkSolid />
          </AccessibleContent>
        ) : (
          <Text>{grade}</Text>
        )
    }
  }

  const renderTitleCell = () => (
    <div className="grade-details__title">
      <Link
        href={url}
        isWithinText={false}
        themeOverride={{
          color: k5ThemeVariables.colors.textDarkest,
          hoverColor: k5ThemeVariables.colors.textDarkest,
        }}
      >
        {assignmentName}
      </Link>
      <span className="grade-details__status">{renderStatus()}</span>
    </div>
  )

  const shouldShowPoints = !!pointsPossible && !restrictQuantitativeData

  return (
    <Table.Row data-testid="grades-table-row" key={id}>
      <Table.Cell themeOverride={cellTheme}>
        {unread ? (
          <Badge
            type="notification"
            placement="start center"
            margin={isStacked ? '0 small' : undefined}
            formatOutput={() => (
              <ScreenReaderContent data-testid="new-grade-indicator">
                {I18n.t('New grade for %{assignmentName}', {assignmentName})}
              </ScreenReaderContent>
            )}
            themeOverride={{
              sizeNotification: '0.45rem',
            }}
          >
            {renderTitleCell()}
          </Badge>
        ) : (
          renderTitleCell()
        )}
      </Table.Cell>
      <Table.Cell themeOverride={cellTheme}>
        {dueDate && <Text>{dateFormatter(dueDate)}</Text>}
      </Table.Cell>
      <Table.Cell themeOverride={cellTheme}>
        <Text>{assignmentGroupName}</Text>
      </Table.Cell>
      <Table.Cell themeOverride={cellTheme}>
        <div className="grade-details__score">
          {renderScore()}
          {shouldShowPoints && (
            <span className="points-possible">
              <Text size="x-small">{I18n.t('Out of %{pointsPossible} pts', {pointsPossible})}</Text>
            </span>
          )}
          {hasComments && (
            <Link
              href={`${url}/submissions/${currentUserId}`}
              isWithinText={false}
              margin={isStacked ? '0 0 0 xx-small' : 'xx-small 0'}
            >
              {I18n.t('View feedback')}
            </Link>
          )}
        </div>
      </Table.Cell>
    </Table.Row>
  )
}
