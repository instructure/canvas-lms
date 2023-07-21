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
import AvatarLink from '../AvatarLink/AvatarLink'
import NameLink from '../NameLink/NameLink'
import StatusPill from '../StatusPill/StatusPill'
import RosterTableRowMenuButton from '../RosterTableRowMenuButton/RosterTableRowMenuButton'
import {secondsToStopwatchTime} from '../../../util/utils'
import RosterTableLastActivity from '../RosterTableLastActivity/RosterTableLastActivity'
import RosterTableRoles from '../RosterTableRoles/RosterTableRoles'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Table} from '@instructure/ui-table'
import {arrayOf, bool, number, shape, string} from 'prop-types'
import {OBSERVER_ENROLLMENT, STUDENT_ENROLLMENT} from '../../../util/constants'

const I18n = useI18nScope('course_people')

// InstUI Table.ColHeader id prop is not passed to HTML <th> element
const idProps = name => ({
  id: name,
  'data-testid': name,
})

const RosterCard = ({courseUsersConnectionNode}) => {
  const {
    view_user_logins,
    read_sis,
    read_reports,
    can_allow_admin_actions,
    manage_admin_users,
    manage_students,
  } = ENV?.permissions || {}
  const showCourseSections = ENV?.course?.hideSectionsOnCourseUsersPage === false

  const {name, _id, sisId, enrollments, loginId, avatarUrl, pronouns} = courseUsersConnectionNode
  const {totalActivityTime, htmlUrl, state} = enrollments[0]
  const canRemoveUser = enrollments.every(enrollment => enrollment.canBeRemoved)
  const canManageUser = enrollments.some(enrollment => enrollment.type !== STUDENT_ENROLLMENT)
    ? can_allow_admin_actions || manage_admin_users
    : manage_students

  const tableRows = enrollments.map(enrollment => {
    const {id, section, type, associatedUser} = enrollment
    if (type === OBSERVER_ENROLLMENT && !associatedUser) return null

    return (
      <Table.Row key={id} data-testid="enrollment-table-data-row">
        {showCourseSections && (
          <Table.Cell>
            {type !== OBSERVER_ENROLLMENT && <Text wrap="break-word">{section.name}</Text>}
          </Table.Cell>
        )}
        <Table.Cell>
          <RosterTableRoles enrollments={[enrollment]} />
        </Table.Cell>
        {read_reports && (
          <Table.Cell>
            <RosterTableLastActivity enrollments={[enrollment]} />
          </Table.Cell>
        )}
        {read_reports && (
          <Table.Cell>
            <Text wrap="break-word">
              {totalActivityTime > 0 && secondsToStopwatchTime(totalActivityTime)}
            </Text>
          </Table.Cell>
        )}
      </Table.Row>
    )
  })
  return (
    <View
      as="div"
      borderWidth="small"
      borderRadius="medium"
      shadow="resting"
      width="100%"
      margin="small 0"
      padding="small"
    >
      <Flex as="div" alignItems="start" border-sizing="border-box" margin="0 0 x-small 0">
        <Flex.Item as="div" margin="0 small 0 0" shouldShrink={true} size="inherit">
          <AvatarLink avatarUrl={avatarUrl} name={name} href={htmlUrl} />
        </Flex.Item>
        <Flex.Item as="div" shouldShrink={true} shouldGrow={true} size="inherit" align="center">
          <NameLink
            studentId={_id}
            htmlUrl={htmlUrl}
            pronouns={pronouns}
            name={name}
            enrollments={enrollments}
          />
          <StatusPill state={state} />
        </Flex.Item>
        <Flex.Item as="div" margin="0 0 0 small" shouldShrink={true} size="inherit">
          {(canManageUser || canRemoveUser) && <RosterTableRowMenuButton name={name} />}
        </Flex.Item>
      </Flex>
      {view_user_logins && loginId && (
        <View display="block">
          <Text weight="bold">{I18n.t('Login ID:')}&nbsp;</Text>
          <Text wrap="break-word">{loginId}</Text>
        </View>
      )}
      {read_sis && sisId && (
        <View display="block">
          <Text weight="bold">{I18n.t('SIS ID:')}&nbsp;</Text>
          <Text wrap="break-word">{sisId}</Text>
        </View>
      )}
      <Table caption={I18n.t('Enrollment Details')} layout="fixed">
        <Table.Head data-testid="enrollment-table-head">
          <Table.Row>
            {showCourseSections && (
              <Table.ColHeader {...idProps('colheader-section')}>
                {I18n.t('Section')}
              </Table.ColHeader>
            )}
            <Table.ColHeader {...idProps('colheader-role')}>{I18n.t('Role')}</Table.ColHeader>
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
          </Table.Row>
        </Table.Head>
        <Table.Body>{tableRows}</Table.Body>
      </Table>
    </View>
  )
}

RosterCard.propTypes = {
  courseUsersConnectionNode: shape({
    name: string.isRequired,
    _id: string.isRequired,
    sisId: string,
    enrollments: arrayOf(
      shape({
        totalActivityTime: number,
        htmlUrl: string.isRequired,
        state: string.isRequired,
        canBeRemoved: bool.isRequired,
        id: string.isRequired,
        section: shape({
          _id: string.isRequired,
          name: string.isRequired,
        }),
        type: string.isRequired,
        associatedUser: shape({
          _id: string.isRequired,
          name: string.isRequired,
        }),
      })
    ),
    loginId: string,
    avatarUrl: string,
    pronouns: string,
  }),
}

RosterCard.defaultProps = {}

export default RosterCard
