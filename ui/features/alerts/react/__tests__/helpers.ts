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

import {Alert as AlertData, CriterionType} from '../types'

export const alert: AlertData = {
  id: '32',
  criteria: [
    {
      criterion_type: CriterionType.Interaction,
      threshold: 2,
    },
    {
      criterion_type: CriterionType.UngradedCount,
      threshold: 3,
    },
    {
      criterion_type: CriterionType.UngradedTimespan,
      threshold: 4,
    },
  ],
  recipients: ['1', ':student', ':teachers'],
  repetition: 5,
}

export const accountRole = {id: '1', label: 'Account Admin'}
