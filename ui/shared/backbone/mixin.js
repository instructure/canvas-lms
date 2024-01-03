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

import {extend, flatten} from 'lodash'

// Merges mixins into target, being mindful of certain properties (like
// events) that need to be merged also.

const magicMethods = ['attach', 'afterRender', 'initialize']
const magicMethodRegex = new RegExp(`^(?:\
__(${magicMethods.join('|')})__\
|(${magicMethods.join('|')})\
)$`)

export default function (target, ...mixins) {
  let key
  if (typeof target === 'function') {
    target = target.prototype
  }
  for (const mixin of Array.from(mixins)) {
    for (key in mixin) {
      // don't blow away old events, merge them
      let match
      const prop = mixin[key]
      if (['events', 'defaults', 'els'].includes(key)) {
        // don't extend parent embedded objects, copy them
        const parentClassKey =
          target.constructor != null ? target.constructor.prototype[key] : undefined
        target[key] = extend({}, parentClassKey, target[key], prop)
        // crazy magic multiple inheritence
      } else if ((match = key.match(magicMethodRegex))) {
        let name
        const [alreadyMixedIn, notMixedInYet] = Array.from(match.slice(1))
        ;(target[(name = `__${alreadyMixedIn || notMixedInYet}__`)] || (target[name] = [])).push(
          prop
        )
      } else {
        target[key] = prop
      }
    }
  }
  for (key of Array.from(Array.from(magicMethods).map(method => `__${method}__`))) {
    if (target[key]) {
      target[key] = flatten(target[key])
    }
  }
  return target
}
