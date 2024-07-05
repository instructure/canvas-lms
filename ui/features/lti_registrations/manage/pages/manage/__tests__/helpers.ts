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

import type {PaginatedList} from '../../../api/PaginatedList'
import type {AccountId} from '../../../model/AccountId'
import type {LtiRegistration} from '../../../model/LtiRegistration'
import type {LtiRegistrationAccountBindingId} from '../../../model/LtiRegistrationAccountBinding'
import type {LtiRegistrationId} from '../../../model/LtiRegistrationId'
import {ZUserId} from '../../../model/UserId'
import type {DeveloperKeyId} from '../../../model/developer_key/DeveloperKeyId'

export const mockPageOfRegistrations = (
  ...names: Array<string>
): PaginatedList<LtiRegistration> => {
  return {
    data: mockRegistrations(...names),
    total: names.length,
  }
}

const mockRegistrations = (...names: Array<string>): Array<LtiRegistration> =>
  names.map(mockRegistration)

export const mockRegistration = (n: string, i: number): LtiRegistration => {
  const id = i.toString()
  const date = new Date()
  const user = {
    created_at: date,
    id: ZUserId.parse(id),
    integration_id: id,
    login_id: id,
    name: 'User Name',
    short_name: 'Short User Name',
    sis_import_id: id,
    sis_user_id: id,
    sortable_name: 'Sortable User Name',
  }
  const common = {
    account_id: id as AccountId,
    created_at: date,
    created_by: user,
    updated_at: date,
    updated_by: user,
    workflow_state: 'on',
  }
  return {
    id: id as LtiRegistrationId,
    name: n,
    ...common,
    account_binding: {
      id: id as LtiRegistrationAccountBindingId,
      registration_id: id as unknown as LtiRegistrationId,
      ...common,
    },
    developer_key_id: id as DeveloperKeyId,
    internal_service: false,
    ims_registration_id: id,
    legacy_configuration_id: null,
    manual_configuration_id: null,
    admin_nickname: n,
  }
}
