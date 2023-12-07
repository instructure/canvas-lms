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

import type {GradingSchemeDataRow} from '@instructure/grading-utils'

export const calculateHighRangeForDataRow = (
  rowIndex: number,
  gradingSchemeData: GradingSchemeDataRow[]
): number => {
  // if this is the first row, high range is 1 (ie, 100%).  For all other rows, the high range is just the prior data row's low range
  return rowIndex === 0 ? 1 : gradingSchemeData[rowIndex - 1].value
}
