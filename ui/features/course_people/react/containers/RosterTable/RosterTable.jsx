/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import AvatarLink from '../../components/AvatarLink/AvatarLink'
import NameLink from '../../components/NameLink/NameLink'
import StatusPill from '../../components/StatusPill/StatusPill'
import RosterTableRowMenuButton from '../../components/RosterTableRowMenuButton/RosterTableRowMenuButton'
import {secondsToStopwatchTime} from '../../../util/utils'
import RosterTableLastActivity from '../../components/RosterTableLastActivity/RosterTableLastActivity'
import RosterTableRoles from '../../components/RosterTableRoles/RosterTableRoles'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {arrayOf, object, shape} from 'prop-types'
import {OBSERVER_ENROLLMENT, STUDENT_ENROLLMENT} from '../../../util/constants'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('course_people')

// InstUI Table.ColHeader id prop is not passed to HTML <th> element
const idProps = name => ({
  id: name,
  'data-testid': name,
})

const RosterTable = ({data}) => {
  const {
    view_user_logins,
    read_sis,
    read_reports,
    can_allow_admin_actions,
    manage_admin_users,
    manage_students,
  } = ENV?.permissions || {}
  const showCourseSections = ENV?.course?.hideSectionsOnCourseUsersPage === false

  const tableRows = data.course.usersConnection.nodes.map(node => {
    const {name, _id, sisId, enrollments, loginId, avatarUrl, pronouns} = node
    const {totalActivityTime, htmlUrl, state} = enrollments[0]
    const canRemoveUser = enrollments.every(enrollment => enrollment.canBeRemoved)
    const canManageUser = enrollments.some(enrollment => enrollment.type !== STUDENT_ENROLLMENT)
      ? can_allow_admin_actions || manage_admin_users
      : manage_students
    const sectionNames = enrollments.map(enrollment => {
      if (enrollment.type === OBSERVER_ENROLLMENT) return null
      return (
        <Text as="div" wrap="break-word" key={`section-${enrollment.id}`}>
          {enrollment.section.name}
        </Text>
      )
    })

    return (
      <Table.Row key={_id} data-testid="roster-table-data-row">
        <Table.Cell>
          <AvatarLink avatarUrl={avatarUrl} name={name} href={htmlUrl} />
        </Table.Cell>
        <Table.Cell data-testid="roster-table-name-cell">
          <NameLink
            studentId={_id}
            htmlUrl={htmlUrl}
            pronouns={pronouns}
            name={name}
            enrollments={enrollments}
          />
          <StatusPill state={state} />
        </Table.Cell>
        {view_user_logins && (
          <Table.Cell>
            <Text wrap="break-word">{loginId}</Text>
          </Table.Cell>
        )}
        {read_sis && (
          <Table.Cell>
            <Text wrap="break-word">{sisId}</Text>
          </Table.Cell>
        )}
        {showCourseSections && <Table.Cell>{sectionNames}</Table.Cell>}
        <Table.Cell>
          <RosterTableRoles enrollments={enrollments} />
        </Table.Cell>
        {read_reports && (
          <Table.Cell>
            <RosterTableLastActivity enrollments={enrollments} />
          </Table.Cell>
        )}
        {read_reports && (
          <Table.Cell>
            <Text wrap="break-word">
              {totalActivityTime > 0 && secondsToStopwatchTime(totalActivityTime)}
            </Text>
          </Table.Cell>
        )}
        <Table.Cell>
          {(canManageUser || canRemoveUser) && <RosterTableRowMenuButton name={name} />}
        </Table.Cell>
      </Table.Row>
    )
  })

  return (
    <Table caption={I18n.t('Course Roster')}>
      <Table.Head data-testid="roster-table-head">
        <Table.Row>
          <Table.ColHeader {...idProps('colheader-avatar')} width="64px">
            <ScreenReaderContent>{I18n.t('Profile Pictures')}</ScreenReaderContent>
          </Table.ColHeader>
          <Table.ColHeader {...idProps('colheader-name')}>{I18n.t('Name')}</Table.ColHeader>
          {view_user_logins && (
            <Table.ColHeader {...idProps('colheader-login-id')}>
              {I18n.t('Login ID')}
            </Table.ColHeader>
          )}
          {read_sis && (
            <Table.ColHeader {...idProps('colheader-sis-id')}>{I18n.t('SIS ID')}</Table.ColHeader>
          )}
          {showCourseSections && (
            <Table.ColHeader {...idProps('colheader-section')}>{I18n.t('Section')}</Table.ColHeader>
          )}
          <Table.ColHeader {...idProps('colheader-role')}>
            <View as="div" minWidth="9ch">
              {I18n.t('Role')}
            </View>
          </Table.ColHeader>
          {read_reports && (
            <Table.ColHeader {...idProps('colheader-last-activity')}>
              {I18n.t('Last Activity')}
            </Table.ColHeader>
          )}
          {read_reports && (
            <Table.ColHeader {...idProps('colheader-total-activity')}>
              {I18n.t('Total Activity')}
            </Table.ColHeader>
          )}
          <Table.ColHeader {...idProps('colheader-administrative-links')}>
            <ScreenReaderContent>{I18n.t('Administrative Links')}</ScreenReaderContent>
          </Table.ColHeader>
        </Table.Row>
      </Table.Head>
      <Table.Body>{tableRows}</Table.Body>
    </Table>
  )
}

RosterTable.propTypes = {
  data: shape({
    course: shape({
      usersConnection: shape({
        nodes: arrayOf(object).isRequired,
      }).isRequired,
    }).isRequired,
  }).isRequired,
}

RosterTable.defaultProps = {}

export default RosterTable
