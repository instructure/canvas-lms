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

import React from 'react'
import {Portal} from '@instructure/ui-portal'
import ActAsModal from './ActAsModal'

type ActAsUserData = {
  user: {
    name?: string
    short_name?: string
    pronouns?: string
    id?: number | string
    avatar_image_url?: string
    sortable_name?: string
    email?: string
    pseudonyms?: Array<{
      login_id?: number | string
      sis_id?: number | string
      integration_id?: number | string
    }>
  }
}

export function Component() {
  const mountPoint: HTMLElement | null = document.querySelector('#act_as_modal')
  if (!mountPoint) {
    return null
  }
  const actAsUserData = (ENV as unknown as {act_as_user_data: ActAsUserData}).act_as_user_data
  return (
    <Portal open={true} mountNode={mountPoint}>
      <ActAsModal user={actAsUserData.user} />
    </Portal>
  )
}
