/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import {arrayOf, func, object, shape, string} from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Table} from '@instructure/ui-table'
import {Tooltip} from '@instructure/ui-tooltip'
import {
  IconCalendarClockLine,
  IconCalendarReservedLine,
  IconEditLine,
  IconMasqueradeLine,
  IconMessageLine,
} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import CreateOrUpdateUserModal from './CreateOrUpdateUserModal'
import UserLink from './UserLink'
import {TempEnrollModal} from '@canvas/temporary-enrollment/react/TempEnrollModal'
import {fetchTemporaryEnrollments} from '@canvas/temporary-enrollment/react/api/enrollment'

const I18n = useI18nScope('account_course_user_search')

export default function UsersListRow({
  accountId,
  user,
  permissions,
  handleSubmitEditUserForm,
  roles,
}) {
  const [editMode, setEditMode] = useState(false)
  const [enrollmentsAsProvider, setEnrollmentsAsProvider] = useState([])
  const [enrollmentsAsRecipient, setEnrollmentsAsRecipient] = useState([])

  // check if user has permissions to enable the temporary enrollment feature
  const canTempEnroll =
    permissions.can_add_temporary_enrollments &&
    (permissions.can_manage_admin_users ||
      (permissions.can_add_designer &&
        permissions.can_add_student &&
        permissions.can_add_teacher &&
        permissions.can_add_ta &&
        permissions.can_add_observer))

  // map role-specific and admin-level permissions to consolidated booleans
  const enrollPerm = {
    teacher: permissions.can_add_teacher || permissions.can_manage_admin_users,
    ta: permissions.can_add_ta || permissions.can_manage_admin_users,
    student: permissions.can_add_student || permissions.can_manage_admin_users,
    observer: permissions.can_add_observer || permissions.can_manage_admin_users,
    designer: permissions.can_add_observer || permissions.can_manage_admin_users,
  }

  useEffect(() => {
    const fetchAllEnrollments = async () => {
      try {
        const [recipientData, providerData] = await Promise.all([
          // provider-related enrollments
          fetchTemporaryEnrollments(user.id, false),
          // recipient-related enrollments
          fetchTemporaryEnrollments(user.id, true),
        ])

        setEnrollmentsAsProvider(providerData)
        setEnrollmentsAsRecipient(recipientData)
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error('Failed to fetch enrollments: ', error)
      }
    }

    fetchAllEnrollments()
  }, [user.id])

  // render temporary enrollment modal, tooltip, and icon
  function renderTempEnrollModal(
    enrollmentType,
    tempEnrollments,
    icon,
    editModeStatus,
    toggleFunction,
    setEditModeFunction
  ) {
    const tooltipText = generateTitle(enrollmentType)

    return (
      <TempEnrollModal
        title={generateTitle}
        enrollmentType={enrollmentType}
        user={user}
        canReadSIS={permissions.can_read_sis}
        permissions={enrollPerm}
        accountId={accountId}
        roles={roles}
        tempEnrollments={tempEnrollments}
        isEditMode={editModeStatus}
        onToggleEditMode={toggleFunction || setEditModeFunction}
      >
        <Tooltip data-testid="user-list-row-tooltip" renderTip={tooltipText}>
          <IconButton
            withBorder={false}
            withBackground={false}
            size="small"
            screenReaderLabel={tooltipText}
            onClick={toggleFunction || setEditModeFunction}
          >
            {icon}
          </IconButton>
        </Tooltip>
      </TempEnrollModal>
    )
  }

  // generate temporary enrollment modal title based on enrollment type
  function generateTitle(enrollmentType) {
    switch (enrollmentType) {
      case 'provider':
        return I18n.t('%{name}’s Temporary Enrollment Recipients', {name: user.name})
      case 'recipient':
        return I18n.t('%{name}’s Temporary Enrollment Providers', {name: user.name})
      default:
        return I18n.t('Assign temporary enrollments to %{name}', {name: user.name})
    }
  }

  // toggle current edit mode state
  function toggleEditMode() {
    setEditMode(prev => !prev)
  }

  // set edit mode state explicitly using provided value
  function setEditModeExplicitly(value) {
    setEditMode(value)
  }

  // render appropriate icon(s) based on the user’s roles
  function renderTempEnrollIcon() {
    const editIcon = <IconCalendarReservedLine title={I18n.t('Edit Temporary Enrollment')} />
    const createIcon = <IconCalendarClockLine title={I18n.t('Create Temporary Enrollment')} />

    // user is not a provider or recipient
    if (enrollmentsAsProvider.length === 0 && enrollmentsAsRecipient.length === 0) {
      return renderTempEnrollModal(null, null, createIcon, false, null, () =>
        setEditModeExplicitly(false)
      )
    }

    // user is a provider but not a recipient
    if (enrollmentsAsProvider.length > 0 && enrollmentsAsRecipient.length === 0) {
      return renderTempEnrollModal(
        'provider',
        enrollmentsAsProvider,
        createIcon,
        editMode,
        toggleEditMode,
        null
      )
    }

    // user is a recipient but not a provider
    if (enrollmentsAsProvider.length === 0 && enrollmentsAsRecipient.length > 0) {
      return (
        <>
          {renderTempEnrollModal(
            'recipient',
            enrollmentsAsRecipient,
            editIcon,
            editMode,
            toggleEditMode,
            null
          )}

          {renderTempEnrollModal(null, null, createIcon, false, null, () =>
            setEditModeExplicitly(false)
          )}
        </>
      )
    }

    // user is both a provider and a recipient
    if (enrollmentsAsProvider.length > 0 && enrollmentsAsRecipient.length > 0) {
      return (
        <>
          {renderTempEnrollModal(
            'recipient',
            enrollmentsAsRecipient,
            editIcon,
            editMode,
            toggleEditMode,
            null
          )}

          {renderTempEnrollModal(
            'provider',
            enrollmentsAsProvider,
            editIcon,
            editMode,
            toggleEditMode,
            null
          )}
        </>
      )
    }
  }

  return (
    <Table.Row>
      <Table.RowHeader>
        <UserLink
          href={`/accounts/${accountId}/users/${user.id}`}
          avatarName={user.short_name}
          name={user.sortable_name}
          avatar_url={user.avatar_url}
          size="x-small"
        />
      </Table.RowHeader>
      <Table.Cell data-heap-redact-text="">{user.email}</Table.Cell>
      <Table.Cell data-heap-redact-text="">{user.sis_user_id}</Table.Cell>
      <Table.Cell>{user.last_login && <FriendlyDatetime dateTime={user.last_login} />}</Table.Cell>
      <Table.Cell>
        {canTempEnroll && renderTempEnrollIcon()}

        {permissions.can_masquerade && (
          <Tooltip
            data-testid="user-list-row-tooltip"
            renderTip={I18n.t('Act as %{name}', {name: user.name})}
          >
            <IconButton
              withBorder={false}
              withBackground={false}
              size="small"
              href={`/users/${user.id}/masquerade`}
              screenReaderLabel={I18n.t('Act as %{name}', {name: user.name})}
            >
              <IconMasqueradeLine title={I18n.t('Act as %{name}', {name: user.name})} />
            </IconButton>
          </Tooltip>
        )}
        {permissions.can_message_users && (
          <Tooltip
            data-testid="user-list-row-tooltip"
            renderTip={I18n.t('Send message to %{name}', {name: user.name})}
          >
            <IconButton
              data-heap-redact-attributes="href"
              withBorder={false}
              withBackground={false}
              size="small"
              href={`/conversations?user_name=${user.name}&user_id=${user.id}`}
              screenReaderLabel={I18n.t('Send message to %{name}', {name: user.name})}
            >
              <IconMessageLine title={I18n.t('Send message to %{name}', {name: user.name})} />
            </IconButton>
          </Tooltip>
        )}
        {permissions.can_edit_users && (
          <CreateOrUpdateUserModal
            createOrUpdate="update"
            url={`/accounts/${accountId}/users/${user.id}`}
            user={user}
            afterSave={handleSubmitEditUserForm}
          >
            <span>
              <Tooltip
                data-testid="user-list-row-tooltip"
                renderTip={I18n.t('Edit %{name}', {name: user.name})}
              >
                <IconButton
                  withBorder={false}
                  withBackground={false}
                  size="small"
                  screenReaderLabel={I18n.t('Edit %{name}', {name: user.name})}
                >
                  <IconEditLine title={I18n.t('Edit %{name}', {name: user.name})} />
                </IconButton>
              </Tooltip>
            </span>
          </CreateOrUpdateUserModal>
        )}
      </Table.Cell>
    </Table.Row>
  )
}

UsersListRow.propTypes = {
  accountId: string.isRequired,
  user: CreateOrUpdateUserModal.propTypes.user.isRequired,
  handleSubmitEditUserForm: func.isRequired,
  permissions: object.isRequired,
  roles: arrayOf(
    shape({
      id: string.isRequired,
      label: string.isRequired,
    })
  ).isRequired,
}

UsersListRow.displayName = 'Row'
