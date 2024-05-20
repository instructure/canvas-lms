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
import type {EnrollmentType, Role} from './types'
import {MODULE_NAME, PROVIDER, RECIPIENT, TOOLTIP_MAX_WIDTH} from './types'
import {TempEnrollModal} from './TempEnrollModal'
import {createAnalyticPropsGenerator} from './util/analytics'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import type {EnvCommon} from '@canvas/global/env/EnvCommon'

declare const ENV: GlobalEnv & EnvCommon

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

export function generateTooltipText(enrollmentType: EnrollmentType, name: string): string {
  let message
  switch (enrollmentType) {
    case PROVIDER:
      message = I18n.t('Manage Temporary Enrollment Recipients for %{name}', {name})
      break
    case RECIPIENT:
      message = I18n.t('Manage Temporary Enrollment Providers for %{name}', {name})
      break
    default:
      message = I18n.t('Create Temporary Enrollment Pairing for %{name}', {name})
  }
  return message
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
      ...(ENV.ACCOUNT_ID !== ENV.ROOT_ACCOUNT_ID && {params: {account_id: ENV.ACCOUNT_ID}}),
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
  ): JSX.Element {
    const tooltipText = generateTooltipText(enrollmentType, props.user.name)
    const tooltipJsx = (
      <View as="div" textAlign="center" maxWidth={TOOLTIP_MAX_WIDTH}>
        <Text size="small">{tooltipText}</Text>
      </View>
    )

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
        <Tooltip data-testid="user-list-row-tooltip" renderTip={tooltipJsx}>
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
    // default return statement to ensure a value is always returned
    return null
  }
  // ensure the component always returns a valid JSX element or null
  return renderTempEnrollIcon() || null
}
