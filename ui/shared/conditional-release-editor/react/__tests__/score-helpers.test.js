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

import {scoreToPercent} from '../score-helpers'
import {Map} from 'immutable'

const LETTER_GRADE_ASSIGNMENT = Map({
  grading_type: 'letter_grade',
  grading_scheme: Map({
    A: 0.9,
    B: 0.5,
    C: 0.3,
    F: 0,
  }),
})

describe('scoreToPercent', () => {
  describe('letter_grade assignment', () => {
    it('converts letter grades to percentages', () => {
      expect(scoreToPercent('A', LETTER_GRADE_ASSIGNMENT)).toEqual(0.9)
      expect(scoreToPercent('B', LETTER_GRADE_ASSIGNMENT)).toEqual(0.5)
      expect(scoreToPercent('C', LETTER_GRADE_ASSIGNMENT)).toEqual(0.3)
      expect(scoreToPercent('F', LETTER_GRADE_ASSIGNMENT)).toEqual('0')
    })

    it('returns score if not associated with a scheme', () => {
      expect(scoreToPercent('RANDOM', LETTER_GRADE_ASSIGNMENT)).toEqual('RANDOM')
    })

    it('works with uppercase and lowercase scheme names', () => {
      const assignment = Map({
        grading_type: 'letter_grade',
        grading_scheme: Map({
          UPPERCASE: 0.7,
          lowercase: 0.6,
          miXEdCaSE: 0.1,
        }),
      })
      expect(scoreToPercent('UPPERCASE', assignment)).toEqual(0.7)
      expect(scoreToPercent('lowercase', assignment)).toEqual(0.6)
      expect(scoreToPercent('miXEdCaSE', assignment)).toEqual(0.1)
    })

    it('returns "" if score is ""', () => {
      expect(scoreToPercent('', LETTER_GRADE_ASSIGNMENT)).toEqual('')
    })
  })
})
