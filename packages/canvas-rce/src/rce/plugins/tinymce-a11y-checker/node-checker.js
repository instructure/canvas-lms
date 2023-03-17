/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import * as dom from './utils/dom'
import rules from './rules'

export default function checkNode(node, done, config = {}, additionalRules = []) {
  if (!node) {
    return
  }
  const errors = []
  const childNodeCheck = child => {
    if (child.hasAttribute('data-ignore-a11y-check')) return
    const composedRules = rules.concat(additionalRules)
    for (const rule of composedRules) {
      // eslint-disable-next-line promise/catch-or-return
      Promise.resolve(rule.test(child, config)).then(result => {
        if (!result) {
          errors.push({node: child, rule})
        }
      })
    }
  }
  const checkDone = () => {
    if (typeof done === 'function') {
      done(errors)
    }
  }
  dom.walk(node, childNodeCheck, checkDone)
}
