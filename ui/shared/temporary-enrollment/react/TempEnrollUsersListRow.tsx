/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import useFetchApi from '@canvas/use-fetch-api-hook'
import {IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {
  IconCalendarClockLine,
  IconCalendarClockSolid,
  IconCalendarReservedSolid,
} from '@instructure/ui-icons'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import {EnrollmentType, MODULE_NAME, PROVIDER, RECIPIENT, Role} from './types'
import {TempEnrollModal} from './TempEnrollModal'
import {createAnalyticPropsGenerator} from './util/analytics'

const I18n = useI18nScope('temporary_enrollment')

const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

export function generateIcon(role: string | null) {
  switch (role) {
    case PROVIDER:
      return <IconCalendarClockSolid color="success" />
    case RECIPIENT:
      return <IconCalendarReservedSolid color="success" />
    default:
      return <IconCalendarClockLine />
  }
}

export function generateTooltip(enrollmentType: EnrollmentType, name: string) {
  switch (enrollmentType) {
    case PROVIDER:
      return I18n.t('Manage %{name}’s Temporary Enrollment Recipients', {name})
    case RECIPIENT:
      return I18n.t('Manage %{name}’s Temporary Enrollment Providers', {name})
    default:
      return I18n.t('Create Temporary Enrollment Pairing for %{name}', {name})
  }
}

interface Props {
  user: {
    id: string
    name: string
    avatar_url?: string
  }
  permissions: {
    can_add_teacher: boolean
    can_add_ta: boolean
    can_add_student: boolean
    can_add_observer: boolean
    can_add_designer: boolean
    can_read_sis: boolean
    can_manage_admin_users: boolean
    can_add_temporary_enrollments: boolean
    can_edit_temporary_enrollments: boolean
    can_delete_temporary_enrollments: boolean
  }
  roles: Role[]
  handleSubmitEditUserForm?: () => void
}

interface TemporaryEnrollmentData {
  is_provider: boolean
  is_recipient: boolean
}

export default function TempEnrollUsersListRow(props: Props) {
  const [editMode, setEditMode] = useState(false)
  const [isProvider, setIsProvider] = useState(false)
  const [isRecipient, setIsRecipient] = useState(false)

  const tempEnrollPermissions = {
    canAdd: props.permissions.can_add_temporary_enrollments,
    canEdit: props.permissions.can_edit_temporary_enrollments,
    canDelete: props.permissions.can_delete_temporary_enrollments,
  }

  const enrollPerm = {
    teacher: props.permissions.can_add_teacher,
    ta: props.permissions.can_add_ta,
    student: props.permissions.can_add_student,
    observer: props.permissions.can_add_observer,
    designer: props.permissions.can_add_observer,
  }

  useFetchApi(
    // @ts-ignore - this hook isn't ts-ified
    {
      path: `/api/v1/users/${props.user.id}/temporary_enrollment_status`,
      success: (json: TemporaryEnrollmentData) => setTemporaryEnrollmentState(json),
      error: showFlashError(I18n.t('Failed to fetch temporary enrollment data')),
    },
    [props.user.id]
  )

  function renderTempEnrollModal(
    enrollmentType: EnrollmentType,
    icon: JSX.Element,
    editModeStatus: boolean,
    toggleOrSetEditModeFunction: () => boolean | void
  ) {
    const tooltipText = generateTooltip(enrollmentType, props.user.name)

    return (
      <TempEnrollModal
        enrollmentType={enrollmentType}
        user={props.user}
        canReadSIS={props.permissions.can_read_sis}
        permissions={enrollPerm}
        roles={props.roles}
        isEditMode={editModeStatus}
        onToggleEditMode={toggleOrSetEditModeFunction}
        tempEnrollPermissions={tempEnrollPermissions}
      >
        <Tooltip data-testid="user-list-row-tooltip" renderTip={tooltipText}>
          <IconButton
            {...analyticProps(icon.type.displayName)}
            withBorder={false}
            withBackground={false}
            size="small"
            screenReaderLabel={tooltipText}
            onClick={toggleOrSetEditModeFunction}
          >
            {icon}
          </IconButton>
        </Tooltip>
      </TempEnrollModal>
    )
  }

  function setTemporaryEnrollmentState(res: TemporaryEnrollmentData) {
    setIsProvider(res.is_provider)
    setIsRecipient(res.is_recipient)
  }

  function toggleEditMode() {
    setEditMode(prev => !prev)
  }

  function renderTempEnrollIcon() {
    if (!isProvider && !isRecipient) {
      return renderTempEnrollModal(null, generateIcon(null), false, () => setEditMode(false))
    }
    if (isProvider && !isRecipient) {
      return renderTempEnrollModal(PROVIDER, generateIcon(PROVIDER), editMode, toggleEditMode)
    }
    if (!isProvider && isRecipient) {
      return (
        <>
          {renderTempEnrollModal(RECIPIENT, generateIcon(RECIPIENT), editMode, toggleEditMode)}

          {renderTempEnrollModal(null, generateIcon(null), false, () => setEditMode(false))}
        </>
      )
    }
    if (isProvider && isRecipient) {
      return (
        <>
          {renderTempEnrollModal(RECIPIENT, generateIcon(RECIPIENT), editMode, toggleEditMode)}

          {renderTempEnrollModal(PROVIDER, generateIcon(PROVIDER), editMode, toggleEditMode)}
        </>
      )
    }
  }
  return renderTempEnrollIcon()
}
