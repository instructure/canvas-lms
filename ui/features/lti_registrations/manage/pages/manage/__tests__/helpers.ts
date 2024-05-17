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

import type {LtiRegistration} from 'features/lti_registrations/manage/model/LtiRegistration'
import type {LtiRegistrationId} from 'features/lti_registrations/manage/model/LtiRegistrationId'
import type {AccountId} from 'features/lti_registrations/manage/model/AccountId'
import type {DeveloperKeyId} from 'features/lti_registrations/manage/model/DeveloperKeyId'
import type {LtiRegistrationAccountBindingId} from 'features/lti_registrations/manage/model/LtiRegistrationAccountBinding'
import type {UserId} from 'features/lti_registrations/manage/model/UserId'
import type {PaginatedList} from 'features/lti_registrations/manage/api/PaginatedList'

export const mockPageOfRegistrations = (
  ...names: Array<string>
): PaginatedList<LtiRegistration> => {
  return {
    data: mockRegistrations(...names),
    total: names.length,
  }
}

const mockRegistrations = (...names: Array<string>): Array<LtiRegistration> => {
  return names.map((n, i) => {
    const id = i.toString()
    const date = new Date()
    const common = {
      account_id: id as AccountId,
      created_at: date,
      created_by: id as UserId,
      updated_at: date,
      updated_by: id as UserId,
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
  })
}
