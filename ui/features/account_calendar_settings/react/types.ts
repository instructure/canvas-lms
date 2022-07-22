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

import {ReactElement} from 'react'

export type CollectionChild = {
  id: number
  name: string
  calendarVisible: boolean
}

export type Collection = {
  [id: number]: {
    id: number
    name: string
    collections: number[]
    children: CollectionChild[]
    renderBeforeItems?: ReactElement
  }
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
  parent_account_id: number | null
  visible: boolean
  sub_account_count: number
}
