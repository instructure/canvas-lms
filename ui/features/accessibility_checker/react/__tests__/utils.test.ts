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

import {calculateTotalIssuesCount} from '../utils'

describe('calculateTotalIssuesCount', () => {
  it('returns 0 if all keys are missing', () => {
    expect(calculateTotalIssuesCount({})).toBe(0)
  })

  it('returns 0 if all counts are zero', () => {
    const data = {
      pages: {
        1: {count: 0},
        2: {count: 0},
      },
      assignments: {
        3: {count: 0},
      },
      attachments: {
        4: {count: 0},
      },
    }
    expect(calculateTotalIssuesCount(data as any)).toBe(0)
  })

  it('sums counts from all keys', () => {
    const data = {
      pages: {
        1: {count: 2},
        2: {count: 3},
      },
      assignments: {
        3: {count: 4},
      },
      attachments: {
        4: {count: 1},
      },
    }
    expect(calculateTotalIssuesCount(data as any)).toBe(2 + 3 + 4 + 1)
  })

  it('ignores items without count property', () => {
    const data = {
      pages: {
        1: {count: 2},
        2: {},
      },
      assignments: {
        3: {count: 4},
      },
      attachments: {
        4: {},
      },
    }
    expect(calculateTotalIssuesCount(data as any)).toBe(2 + 4)
  })

  it('handles missing keys', () => {
    const data = {
      pages: {
        1: {count: 2},
      },
      // assignments and attachments missing
    }
    expect(calculateTotalIssuesCount(data as any)).toBe(2)
  })
})
