/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import './jquery/index'
import React from 'react'
import {createRoot} from 'react-dom/client'
import GeneratePairingCode from '@canvas/generate-pairing-code'
import ready from '@instructure/ready'
import ManageTempEnrollButton from '@canvas/temporary-enrollment/react/ManageTempEnrollButton'
import {CreateDSRModal} from '@canvas/dsr'
import {Button} from '@instructure/ui-buttons'
import {IconExportLine} from '@instructure/ui-icons'

ready(() => {
  const pairing_container = document.getElementById('pairing-code')

  const permissions = ENV.PERMISSIONS

  const modifyPermissions = {
    canAdd: permissions.can_add_temporary_enrollments,
    canEdit: permissions.can_edit_temporary_enrollments,
    canDelete: permissions.can_delete_temporary_enrollments,
    canView: permissions.can_view_temporary_enrollments,
  }

  const rolePermissions = {
    teacher: permissions.can_add_teacher,
    ta: permissions.can_add_ta,
    student: permissions.can_add_student,
    observer: permissions.can_add_observer,
    designer: permissions.can_add_observer,
  }

  const roles = Array.prototype.slice.call(ENV.COURSE_ROLES)

  if (pairing_container) {
    const pairingRoot = createRoot(pairing_container)
    pairingRoot.render(
      <GeneratePairingCode userId={ENV.USER_ID} name={ENV.CONTEXT_USER_DISPLAY_NAME} />,
    )
  }

  if (modifyPermissions.canView !== undefined) {
    const temp_enrollments_container = document.getElementById(
      'manage-temp-enrollments-mount-point',
    )

    if (temp_enrollments_container) {
      const tempEnrollRoot = createRoot(temp_enrollments_container)
      tempEnrollRoot.render(
        <ManageTempEnrollButton
          user={{id: ENV.USER_ID, name: ENV.CONTEXT_USER_DISPLAY_NAME}}
          modifyPermissions={modifyPermissions}
          roles={roles}
          rolePermissions={rolePermissions}
          can_read_sis={permissions.can_read_sis}
        />,
      )
    }
  }

  if (permissions.can_manage_dsr_requests) {
    const dsrModalContainer = document.getElementById('dsr-modal-mount-point')

    if (dsrModalContainer) {
      createRoot(dsrModalContainer).render(
        <CreateDSRModal
          accountId={ENV.ACCOUNT_ID}
          user={{
            id: ENV.USER_ID,
            name: ENV.CONTEXT_USER_DISPLAY_NAME,
          }}
          afterSave={() => {}}
        >
          <Button renderIcon={<IconExportLine />} display="block" textAlign="start">
            Export DSR Report
          </Button>
        </CreateDSRModal>,
      )
    }
  }
})
