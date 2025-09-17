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

import {describe, expect, it} from '../../../__tests__/testPlatformShims'
import {ensureCompatibleSubmissionType} from '../LtiAssetReports'

describe('LtiAssetReports types', () => {
  describe('ensureCompatibleSubmissionType', () => {
    it("should return 'online_text_entry' for valid online_text_entry submission type", () => {
      const result = ensureCompatibleSubmissionType('online_text_entry')
      expect(result).toBe('online_text_entry')
    })

    it("should return 'online_upload' for valid online_upload submission type", () => {
      const result = ensureCompatibleSubmissionType('online_upload')
      expect(result).toBe('online_upload')
    })

    it("should return undefined for incompatible submission type 'online_url'", () => {
      const result = ensureCompatibleSubmissionType('online_url')
      expect(result).toBeUndefined()
    })

    it('should return undefined for empty string', () => {
      const result = ensureCompatibleSubmissionType('')
      expect(result).toBeUndefined()
    })

    it('should return undefined for arbitrary invalid string', () => {
      const result = ensureCompatibleSubmissionType('invalid_submission_type')
      expect(result).toBeUndefined()
    })

    it('should return undefined for null input', () => {
      expect(ensureCompatibleSubmissionType(null)).toBeUndefined()
    })

    it('should return undefined for undefined input', () => {
      expect(ensureCompatibleSubmissionType(undefined)).toBeUndefined()
    })
  })
})
