/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {svgUrl} from '../icons'

describe('icons', () => {
  describe('svgUrl', () => {
    it('returns exceeds_mastery icon when points are above mastery threshold', () => {
      expect(svgUrl(5, 3)).toMatch('/images/outcomes/exceeds_mastery.svg')
      expect(svgUrl(4, 3)).toMatch('/images/outcomes/exceeds_mastery.svg')
      expect(svgUrl(3.1, 3)).toMatch('/images/outcomes/exceeds_mastery.svg')
    })

    it('returns mastery icon when points match mastery threshold', () => {
      expect(svgUrl(3, 3)).toMatch('/images/outcomes/mastery.svg')
      expect(svgUrl(0, 0)).toMatch('/images/outcomes/mastery.svg')
    })

    it('returns near_mastery icon when points are 1 below mastery threshold', () => {
      expect(svgUrl(2, 3)).toMatch('/images/outcomes/near_mastery.svg')
      expect(svgUrl(-1, 0)).toMatch('/images/outcomes/near_mastery.svg')
    })

    it('returns remediation icon when points are 2 below mastery threshold', () => {
      expect(svgUrl(1, 3)).toMatch('/images/outcomes/remediation.svg')
      expect(svgUrl(-2, 0)).toMatch('/images/outcomes/remediation.svg')
    })

    it('returns no_evidence icon when points are more than 2 below mastery threshold', () => {
      expect(svgUrl(0, 3)).toMatch('/images/outcomes/no_evidence.svg')
      expect(svgUrl(-5, 3)).toMatch('/images/outcomes/no_evidence.svg')
      expect(svgUrl(-100, 3)).toMatch('/images/outcomes/no_evidence.svg')
    })

    it('returns unassessed icon when points are null', () => {
      expect(svgUrl(null, 3)).toMatch('/images/outcomes/unassessed.svg')
      expect(svgUrl(null, 10)).toMatch('/images/outcomes/unassessed.svg')
      expect(svgUrl(null, 0)).toMatch('/images/outcomes/unassessed.svg')
    })
  })
})
