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

import React, {useCallback, useState} from 'react'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {
  IconCalendarClockLine,
  IconCalendarClockSolid,
  IconCalendarReservedSolid,
} from '@instructure/ui-icons'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {EnrollmentType, Role, TemporaryEnrollmentStatus} from './types'
import {MODULE_NAME, PROVIDER, RECIPIENT, TOOLTIP_MAX_WIDTH} from './types'
import {TempEnrollModal} from './TempEnrollModal'
import {createAnalyticPropsGenerator} from './util/analytics'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import type {EnvCommon} from '@canvas/global/env/EnvCommon'

declare const ENV: GlobalEnv & EnvCommon

const I18n = createI18nScope('temporary_enrollment')

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
    can_allow_course_admin_actions: boolean
    can_add_temporary_enrollments: boolean
    can_edit_temporary_enrollments: boolean
    can_delete_temporary_enrollments: boolean
  }
  roles: Role[]
  handleSubmitEditUserForm?: () => void
}

export default function TempEnrollUsersListRow(props: Props) {
  const [editMode, setEditMode] = useState(false)
  const [status, setStatus] = useState<TemporaryEnrollmentStatus>({
    is_provider: false,
    is_recipient: false,
    can_provide: false,
  })

  const setEnrollmentState = useCallback((json: TemporaryEnrollmentStatus) => setStatus(json), [])

  const modifyPermissions = {
    canAdd: props.permissions.can_add_temporary_enrollments,
    canEdit: props.permissions.can_edit_temporary_enrollments,
    canDelete: props.permissions.can_delete_temporary_enrollments,
  }

  const rolePermissions = {
    teacher: props.permissions.can_add_teacher,
    ta: props.permissions.can_add_ta,
    student: props.permissions.can_add_student,
    observer: props.permissions.can_add_observer,
    designer: props.permissions.can_add_observer,
  }

  useFetchApi(
    {
      path: `/api/v1/users/${props.user.id}/temporary_enrollment_status`,
      ...(ENV.ACCOUNT_ID !== ENV.ROOT_ACCOUNT_ID && {params: {account_id: ENV.ACCOUNT_ID}}),
      success: setEnrollmentState,
      error: useCallback(
        () => showFlashError(I18n.t('Failed to fetch temporary enrollment data')),
        [],
      ),
    },
    [props.user.id],
  )

  function renderTempEnrollModal(
    enrollmentType: EnrollmentType,
    icon: JSX.Element,
    editModeStatus: boolean,
    toggleOrSetEditModeFunction: () => boolean | void,
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
        modifyPermissions={modifyPermissions}
        roles={props.roles}
        isEditMode={editModeStatus}
        onToggleEditMode={toggleOrSetEditModeFunction}
        rolePermissions={rolePermissions}
      >
        <Tooltip renderTip={tooltipJsx}>
          <IconButton
            {...analyticProps(icon.type.displayName)}
            data-testid="user-list-row-tooltip"
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

  function toggleEditMode() {
    setEditMode(prev => !prev)
  }

  function renderTempEnrollIcon() {
    const {is_provider, is_recipient, can_provide} = status

    if (!is_provider && !is_recipient && can_provide) {
      return renderTempEnrollModal(null, generateIcon(null), false, () => setEditMode(false))
    } else if (is_provider && !is_recipient) {
      return renderTempEnrollModal(PROVIDER, generateIcon(PROVIDER), editMode, toggleEditMode)
    } else if (!is_provider && is_recipient && can_provide) {
      return (
        <>
          {renderTempEnrollModal(RECIPIENT, generateIcon(RECIPIENT), editMode, toggleEditMode)}

          {renderTempEnrollModal(null, generateIcon(null), false, () => setEditMode(false))}
        </>
      )
    } else if (is_provider && is_recipient) {
      return (
        <>
          {renderTempEnrollModal(RECIPIENT, generateIcon(RECIPIENT), editMode, toggleEditMode)}

          {renderTempEnrollModal(PROVIDER, generateIcon(PROVIDER), editMode, toggleEditMode)}
        </>
      )
    } else if (!is_provider && is_recipient && !can_provide) {
      return renderTempEnrollModal(RECIPIENT, generateIcon(RECIPIENT), editMode, toggleEditMode)
    } else {
      // default return statement to ensure a value is always returned
      return null
    }
  }
  // ensure the component always returns a valid JSX element or null
  return renderTempEnrollIcon() || null
}
