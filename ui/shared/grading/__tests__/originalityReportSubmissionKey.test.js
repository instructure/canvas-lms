/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import originalityReportSubmissionKey from '../originalityReportSubmissionKey'

function submission(overrides = {}) {
  return {
    id: 1,
    submitted_at: '05 October 2011 14:48 UTC',
    ...overrides
  }
}

describe('originalityReportSubmissionKey', () => {
  it('returns the key for the submission', () => {
    expect(originalityReportSubmissionKey(submission())).toEqual(
      'submission_1_2011-10-05T14:48:00Z'
    )
  })

  describe('when the submission does not have a valid "submitted_at"', () => {
    const overrides = {
      submitted_at: 'banana'
    }

    it('returns the an empty string', () => {
      expect(originalityReportSubmissionKey(submission(overrides))).toEqual('')
    })
  })
})
