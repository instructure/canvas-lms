/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import fakeENV from '@canvas/test-utils/fakeENV'
import SpeedGrader from '../speed_grader'

describe('SpeedGrader grade parsing and types', () => {
  beforeEach(() => {
    fakeENV.setup({SINGLE_NQ_SESSION_ENABLED: true})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('shouldParseGrade', () => {
    it('returns true when grading type is percent', () => {
      ENV.grading_type = 'percent'
      expect(SpeedGrader.EG.shouldParseGrade()).toBe(true)
    })

    it('returns true when grading type is points', () => {
      ENV.grading_type = 'points'
      expect(SpeedGrader.EG.shouldParseGrade()).toBe(true)
    })

    it('returns false when grading type is neither percent nor points', () => {
      ENV.grading_type = 'letter_grade'
      expect(SpeedGrader.EG.shouldParseGrade()).toBe(false)
    })
  })

  describe('isGradingTypePercent', () => {
    it('returns true when grading type is percent', () => {
      ENV.grading_type = 'percent'
      expect(SpeedGrader.EG.isGradingTypePercent()).toBe(true)
    })

    it('returns false when grading type is not percent', () => {
      ENV.grading_type = 'points'
      expect(SpeedGrader.EG.isGradingTypePercent()).toBe(false)
    })
  })
})
