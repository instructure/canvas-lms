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

import {notifyTinyMCE} from './dom'

/**
 * Enhances a rule by wrapping its update method to notify TinyMCE of changes
 * @param {Object} rule - The rule to enhance
 * @param {Function} [enhanceMethod] - Optional custom method to notify TinyMCE
 * @returns {Object} - The enhanced rule
 */
export function enhanceRule(rule, enhanceMethod = null) {
  // Skip if the rule doesn't have an update method
  if (!rule.update) {
    return rule
  }

  const enhance = enhanceMethod || notifyTinyMCE
  const enhancedRule = {...rule}
  const originalUpdate = rule.update
  enhancedRule.update = (elem, data) => {
    const result = originalUpdate(elem, data)
    enhance()
    return result
  }

  return enhancedRule
}

/**
 * Enhances an array of rules by wrapping their update methods to notify TinyMCE of changes
 * @param {Array} rules - The array of rules to enhance
 * @param {Function} [enhanceMethod] - Optional custom method to notify TinyMCE
 * @returns {Array} - The array of enhanced rules
 */
export function enhanceRules(rules, enhanceMethod = null) {
  return rules.map(rule => enhanceRule(rule, enhanceMethod))
}
