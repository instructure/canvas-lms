/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import rules from '../index'

const ruleMap = rules.map(rule => [rule.id, rule])

test.each(ruleMap)('%s should have a linkText function if it has a link', (ruleId, rule) => {
  if (rule.link && rule.link.length) {
    expect(rule.linkText).toBeInstanceOf(Function)
  }
})

test('all rules should have an id property', () => {
  expect(ruleMap.every(x => x[0])).toBeTruthy()
})

test('all rules should have unique id properties', () => {
  const ruleSet = new Set()
  ruleMap.forEach(x => ruleSet.add(x[0]))
  expect(ruleSet.size).toBe(ruleMap.length)
})
