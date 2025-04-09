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
import React from 'react'
import SortableTable from './SortableTable'
import {BaseTableProps} from './SimpleTable'

export type InsightsTableProps = BaseTableProps & {
  perPage: number
}

const InsightsTable: React.FC<InsightsTableProps> = ({caption, headers, rows, perPage}) => {
  return <SortableTable caption={caption} headers={headers} rows={rows} perPage={perPage} />
}

export default InsightsTable
