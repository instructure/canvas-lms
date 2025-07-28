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

import React, {FC, cloneElement} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {
  IconMoreLine,
  IconGroupLine,
  IconClockLine,
  IconUserLine,
  IconLinkLine,
  IconExportLine,
} from '@instructure/ui-icons'
import useCoursePeopleContext from '../../hooks/useCoursePeopleContext'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_people')

type MenuItemProps = {
  href: string
  icon: React.ReactElement
  label: string
  testId: string
}

const CoursePeopleOptionsMenu: FC = () => {
  const {
    canAllowCourseAdminActions,
    canGenerateObserverPairingCode,
    canManageStudents,
    canReadPriorRoster,
    canReadReports,
    canReadRoster,
    canViewAllGrades,
    userIsInstructor,
    selfRegistration,
    groupsUrl,
    priorEnrollmentsUrl,
    interactionsReportUrl,
    userServicesUrl,
    observerPairingCodesUrl,
  } = useCoursePeopleContext()

  const canViewPriorEnrollments =
    canAllowCourseAdminActions && canManageStudents && canReadPriorRoster
  const canViewStudentInteractionsReport = userIsInstructor && canReadReports && canViewAllGrades
  const canExportPairingCodes = selfRegistration && canGenerateObserverPairingCode

  const MenuItem = ({href, icon, label, testId}: MenuItemProps) => (
    <Menu.Item href={href} data-testid={testId}>
      {cloneElement(icon, {size: 'x-small'})}
      <View margin="0 0 0 x-small">{label}</View>
    </Menu.Item>
  )

  if (
    !canReadRoster &&
    !canViewPriorEnrollments &&
    !canViewStudentInteractionsReport &&
    !canExportPairingCodes
  )
    return null

  return (
    <Menu
      label="Course People Options Menu"
      trigger={
        <IconButton
          renderIcon={IconMoreLine}
          screenReaderLabel={I18n.t('More Options')}
          data-testid="course-people-options-menu-button"
          margin="none none none medium"
        />
      }
    >
      {canReadRoster && (
        <MenuItem
          href={groupsUrl}
          icon={<IconGroupLine />}
          label={I18n.t('View User Groups')}
          testId="view-user-groups-option"
        />
      )}
      {canViewPriorEnrollments && (
        <MenuItem
          href={priorEnrollmentsUrl}
          icon={<IconClockLine />}
          label={I18n.t('View Prior Enrollments')}
          testId="view-prior-enrollments-option"
        />
      )}
      {canViewStudentInteractionsReport && (
        <MenuItem
          href={interactionsReportUrl}
          icon={<IconUserLine />}
          label={I18n.t('Student Interactions Report')}
          testId="view-student-interactions-report-option"
        />
      )}
      {canReadRoster && (
        <MenuItem
          href={userServicesUrl}
          icon={<IconLinkLine />}
          label={I18n.t('View Registered Services')}
          testId="view-registered-services-option"
        />
      )}
      {canExportPairingCodes && (
        <MenuItem
          href={observerPairingCodesUrl}
          icon={<IconExportLine />}
          label={I18n.t('Export Pairing Codes')}
          testId="export-pairing-codes-option"
        />
      )}
    </Menu>
  )
}

export default CoursePeopleOptionsMenu
