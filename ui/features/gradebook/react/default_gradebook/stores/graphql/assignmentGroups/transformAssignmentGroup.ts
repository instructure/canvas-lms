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

import {AssignmentGroup as ApiAssignmentGroup} from 'api.d'
import {AssignmentGroup} from './getAssignmentGroups'

export const transformAssignmentGroup = (it: AssignmentGroup): ApiAssignmentGroup => ({
  id: it._id,
  name: it.name ?? '',
  position: it.position ?? 0,
  assignments: [],
  group_weight: it.groupWeight ?? 0,
  rules: {
    drop_highest: it.rules?.dropHighest ?? undefined,
    drop_lowest: it.rules?.dropLowest ?? undefined,
    never_drop: it.rules?.neverDrop?.map(it => it._id),
  },
  sis_source_id: it.sisId,
  integration_data: null,
})
