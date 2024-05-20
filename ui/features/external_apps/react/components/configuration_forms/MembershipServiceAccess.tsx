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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {Checkbox} from '@instructure/ui-checkbox'
import type {I18nType} from './types'

const I18n: I18nType = useI18nScope('external_tools')

export interface MembershipServiceAccessProps {
  checked: boolean
  onChange: () => void
  membershipServiceFeatureFlagEnabled: boolean
}

export default function MembershipServiceAccess({
  checked,
  onChange,
  membershipServiceFeatureFlagEnabled,
}: MembershipServiceAccessProps) {
  return (
    <>
      {membershipServiceFeatureFlagEnabled && (
        <Checkbox
          id="allow_membership_service_access"
          label={I18n.t('Allow this tool to access the IMS Names and Role Provisioning Service')}
          checked={checked}
          onChange={onChange}
        />
      )}
    </>
  )
}
