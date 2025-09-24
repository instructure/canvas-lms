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

import {mockScan3, mockScanData} from '../../../../shared/react/stores/mockData'
import {calculateTotalIssuesCount} from '../../../../shared/react/utils/apiData'

describe('calculateTotalIssuesCount', () => {
  it('returns 0 if the scans array is empty', () => {
    expect(calculateTotalIssuesCount([])).toBe(0)
  })

  it('returns 0 if the scans has only no-issue items', () => {
    const data = [mockScan3]
    expect(calculateTotalIssuesCount(data)).toBe(0)
  })

  it('returns the total count of issues from all scans', () => {
    expect(calculateTotalIssuesCount(mockScanData)).toBe(5)
  })
})
