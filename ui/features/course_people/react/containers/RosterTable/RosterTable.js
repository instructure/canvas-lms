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
import {useQuery} from 'react-apollo'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import {ROSTER_QUERY} from '../../../graphql/Queries'
import LoadingIndicator from '@canvas/loading-indicator'
import {readableRoleName} from '@canvas/k5/react/utils'

const I18n = useI18nScope('course_people')

// InstUI Table.ColHeader id prop is not passed to HTML <th> element
const idProps = name => ({
  id: name,
  'data-testid': name
})

const OBSERVER_ENROLLMENT = 'ObserverEnrollment'

const RosterTable = () => {
  const {loading, data} = useQuery(ROSTER_QUERY, {
    variables: {courseID: ENV.course.id},
    fetchPolicy: 'cache-and-network',
    errorPolicy: 'all'
  })

  if (loading) return <LoadingIndicator />

  const tableRows = data.course.usersConnection.edges.map(edge => {
    const {name, _id, sisId, enrollments, loginId} = edge.node
    const {totalActivityTime} = enrollments[0]

    const sectionNames = enrollments.map(enrollment => {
      if (enrollment.type === OBSERVER_ENROLLMENT) return null
      return <div key={`section-${enrollment.id}`}>{enrollment.section.name}</div>
    })

    const enrollmentRoles = enrollments.map(enrollment => {
      if (enrollment.type === OBSERVER_ENROLLMENT) {
        return enrollment.associatedUser ? (
          <div key={`role-${enrollment.associatedUser.id}`}>
            {I18n.t('Observing: %{user_name}', {user_name: enrollment.associatedUser.name})}
          </div>
        ) : null
      }
      return <div key={`role-${enrollment.id}`}>{readableRoleName(enrollment.type)}</div>
    })

    const lastActivityAt = enrollments.map(enrollment => {
      if (enrollment.type === OBSERVER_ENROLLMENT) return null
      return <div key={`last-activity-${enrollment.id}`}>{enrollment.lastActivityAt}</div>
    })

    return (
      <Table.Row key={_id} data-testid="roster-table-data-row">
        <Table.Cell>{/* Avatar Component */}</Table.Cell>
        <Table.Cell>{name}</Table.Cell>
        <Table.Cell>{loginId}</Table.Cell>
        <Table.Cell>{sisId}</Table.Cell>
        <Table.Cell>{sectionNames}</Table.Cell>
        <Table.Cell>{enrollmentRoles}</Table.Cell>
        <Table.Cell>{lastActivityAt}</Table.Cell>
        <Table.Cell>{totalActivityTime}</Table.Cell>
        <Table.Cell>{/* Menu IconButton */}</Table.Cell>
      </Table.Row>
    )
  })

  return (
    <Table caption={I18n.t('Course Roster')}>
      <Table.Head data-testid="roster-table-head">
        <Table.Row>
          <Table.ColHeader {...idProps('colheader-avatar')}>{}</Table.ColHeader>
          <Table.ColHeader {...idProps('colheader-name')}>{I18n.t('Name')}</Table.ColHeader>
          <Table.ColHeader {...idProps('colheader-login-id')}>{I18n.t('Login ID')}</Table.ColHeader>
          <Table.ColHeader {...idProps('colheader-sis-id')}>{I18n.t('SIS ID')}</Table.ColHeader>
          <Table.ColHeader {...idProps('colheader-section')}>{I18n.t('Section')}</Table.ColHeader>
          <Table.ColHeader {...idProps('colheader-role')}>{I18n.t('Role')}</Table.ColHeader>
          <Table.ColHeader {...idProps('colheader-last-activity')}>
            {I18n.t('Last Activity')}
          </Table.ColHeader>
          <Table.ColHeader {...idProps('colheader-total-activity')}>
            {I18n.t('Total Activity')}
          </Table.ColHeader>
          <Table.ColHeader {...idProps('colheader-context-menu')}>{}</Table.ColHeader>
        </Table.Row>
      </Table.Head>
      <Table.Body>{tableRows}</Table.Body>
    </Table>
  )
}

RosterTable.propTypes = {}

RosterTable.defaultProps = {}

export default RosterTable
