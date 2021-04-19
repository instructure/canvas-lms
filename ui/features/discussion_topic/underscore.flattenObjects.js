/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import _ from 'underscore'
// backward is a stupid requirement for discussions
_.flattenObjects = function(array, key, backward, output) {
  if (!_.isArray(array)) {
    array = [array]
  }
  if (!_.isArray(output)) {
    output = []
  }
  _.each(array, object => {
    output.push(object)
    if (object[key]) {
      let children = object[key]
      if (backward) {
        children = _.clone(children)
        children.reverse()
      }
      _.flattenObjects(children, key, backward, output)
    }
  })
  return output
}
