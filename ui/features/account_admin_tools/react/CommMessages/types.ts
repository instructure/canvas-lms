/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import type {TextInputProps} from '@instructure/ui-text-input'
import type {PillProps} from '@instructure/ui-pill'

export type CommMessageWorkflowState =
  | 'created'
  | 'staged'
  | 'sending'
  | 'sent'
  | 'bounced'
  | 'dashboard'
  | 'closed'
  | 'cancelled'

export type CommMessage = {
  id: string
  to: string
  from: string
  from_name: string
  subject: string
  body: string
  html_body?: string
  created_at: string
  sent_at: string | null
  workflow_state: CommMessageWorkflowState
}

export type User = {
  id: string
  name: string
  login_id: string
  avatar_url: string
  sortable_name: string
}

export type MessagesQueryParams = {
  userId: string
  userName: string
  startTime: string | undefined
  endTime: string | undefined
}

export type WorkflowStateColorMap = Readonly<
  Record<CommMessage['workflow_state'], NonNullable<PillProps['color']>>
>

export type FormMessage = Required<TextInputProps>['messages'][0]
