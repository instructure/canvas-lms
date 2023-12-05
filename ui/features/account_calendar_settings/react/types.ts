/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import type {FetchLinkHeader} from '@canvas/do-fetch-api-effect/types'

export type Collection = {
  [id: number]: Account
}

export type AccountData = {
  id: string
  name: string
  parent_account_id: string | null
  root_account_id: string
  visible: boolean
  sub_account_count: number
}

export type Account = {
  id: number
  name: string
  heading?: string
  label?: string
  parent_account_id: number | null
  sub_account_count: number
  children: any[]
  visible: boolean
  auto_subscribe?: boolean
}

export type VisibilityChange = {
  id: number
  visible: boolean
}

export type SubscriptionChange = {
  id: number
  auto_subscribe: boolean
}

export type ExpandedAccounts = number[]

export type FetchAccountDataResponse = {
  json: AccountData[]
  link: FetchLinkHeader
}

export type UpdateAccountDataResponse = {
  json: {message: string}
}
