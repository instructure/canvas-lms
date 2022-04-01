/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {advancedOnlyCommands, containsAdvancedSyntax} from '../advancedOnlySyntax'

describe('containsAdvancedSyntax', () => {
  it('flags equations containing any advanced command', () => {
    advancedOnlyCommands.map(command => {
      const equation = `some equation containing ${command}`
      expect(containsAdvancedSyntax(equation)).toBe(true)
    })
  })

  it('does not flag equations that do not contain advanced commands', () => {
    const nonAdvancedEquations = ['\\sqrt{x}', '\\sum_{k=1}^{n} k = (n(n+1)) / 2', 'E = mc^2']
    nonAdvancedEquations.map(equation => {
      expect(containsAdvancedSyntax(equation)).toBe(false)
    })
  })
})
