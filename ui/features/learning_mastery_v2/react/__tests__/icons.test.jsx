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
  it('returns the right SVG', () => {
    expect(svgUrl(5, 3)).toMatch(/exceeds_mastery/)
    expect(svgUrl(3, 3)).toMatch(/mastery/)
    expect(svgUrl(2, 3)).toMatch(/near_mastery/)
    expect(svgUrl(1, 3)).toMatch(/remediation/)
    expect(svgUrl(0, 3)).toMatch(/no_evidence/)
    expect(svgUrl(null, 3)).toMatch(/unassessed/)
  })
})
