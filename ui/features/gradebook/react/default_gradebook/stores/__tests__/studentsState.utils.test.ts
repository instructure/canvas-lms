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

import {smartStudentsPerSubmissionRequest} from '../studentsState.utils'
import GRADEBOOK_GRAPHQL_CONFIG from '../graphql/config'

describe('studentsState.utils', () => {
  describe('smartStudentsPerSubmissionRequest', () => {
    it('returns the initial number when calculated value is larger', () => {
      const result = smartStudentsPerSubmissionRequest(250)
      expect(result).toBe(GRADEBOOK_GRAPHQL_CONFIG.initialNumberOfStudentsPerSubmissionRequest)
    })

    it('returns the calculated value when it is smaller than the initial number', () => {
      const result = smartStudentsPerSubmissionRequest(50)
      expect(result).toBe(5)
    })

    it('returns the minimum number when totalCount is very small', () => {
      const result = smartStudentsPerSubmissionRequest(5)
      expect(result).toBe(GRADEBOOK_GRAPHQL_CONFIG.minNumberOfStudentsPerSubmissionRequest)
    })

    it('returns the minimum number when totalCount equals maxSubmissionRequestCount', () => {
      const result = smartStudentsPerSubmissionRequest(
        GRADEBOOK_GRAPHQL_CONFIG.maxSubmissionRequestCount,
      )
      expect(result).toBe(GRADEBOOK_GRAPHQL_CONFIG.minNumberOfStudentsPerSubmissionRequest)
    })

    it('handles zero totalCount with minimum', () => {
      const result = smartStudentsPerSubmissionRequest(0)
      expect(result).toBe(GRADEBOOK_GRAPHQL_CONFIG.minNumberOfStudentsPerSubmissionRequest)
    })

    it('returns exactly the initial number when calculated value equals it', () => {
      const targetValue = GRADEBOOK_GRAPHQL_CONFIG.initialNumberOfStudentsPerSubmissionRequest
      const totalCount = targetValue * GRADEBOOK_GRAPHQL_CONFIG.maxSubmissionRequestCount

      const result = smartStudentsPerSubmissionRequest(totalCount)
      expect(result).toBe(GRADEBOOK_GRAPHQL_CONFIG.initialNumberOfStudentsPerSubmissionRequest)
    })

    it('handles fractional divisions correctly', () => {
      const result = smartStudentsPerSubmissionRequest(35)
      expect(result).toBe(4)
    })
  })
})
