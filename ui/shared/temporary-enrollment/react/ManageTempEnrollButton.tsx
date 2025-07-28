/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {TempEnrollModal} from './TempEnrollModal'
import {Button} from '@instructure/ui-buttons'
import {IconCalendarClockLine} from '@instructure/ui-icons'
import React, {useCallback, useState} from 'react'
import {
  type Role,
  type RolePermissions,
  type TemporaryEnrollmentStatus,
  type ModifyPermissions,
  PROVIDER,
} from './types'
import useFetchApi from '@canvas/use-fetch-api-hook'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('temporary_enrollment')

export interface ManageTempEnrollButtonProps {
  user: {
    id: string
    name: string
  }
  modifyPermissions: ModifyPermissions
  can_read_sis: boolean
  roles: Role[]
  rolePermissions: RolePermissions
}

function ManageTempEnrollButton(props: ManageTempEnrollButtonProps) {
  const [isProvider, setIsProvider] = useState(false)
  const [editMode, setEditMode] = useState(false)

  const setProvider = useCallback((json: TemporaryEnrollmentStatus) => {
    setIsProvider(json.is_provider)
  }, [])

  useFetchApi(
    {
      path: `/api/v1/users/${props.user.id}/temporary_enrollment_status`,
      ...(ENV.ACCOUNT_ID !== ENV.ROOT_ACCOUNT_ID && {params: {account_id: ENV.ACCOUNT_ID}}),
      success: setProvider,
      error: useCallback(
        () => showFlashError(I18n.t('Failed to fetch temporary enrollment data')),
        [],
      ),
    },
    [props.user.id],
  )

  function toggleEditMode() {
    setEditMode(prev => !prev)
  }

  if (isProvider) {
    return (
      <TempEnrollModal
        enrollmentType={PROVIDER}
        user={props.user}
        canReadSIS={props.can_read_sis}
        rolePermissions={props.rolePermissions}
        roles={props.roles}
        isEditMode={editMode}
        onToggleEditMode={toggleEditMode}
        modifyPermissions={props.modifyPermissions}
      >
        <Button
          onClick={toggleEditMode}
          textAlign="start"
          // @ts-expect-error
          renderIcon={IconCalendarClockLine}
          display="block"
          color="success"
          margin="x-small 0"
        >
          {I18n.t('Temporary Enrollments')}
        </Button>
      </TempEnrollModal>
    )
  } else {
    return null
  }
}

export default ManageTempEnrollButton
