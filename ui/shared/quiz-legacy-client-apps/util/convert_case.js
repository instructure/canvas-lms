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

import Inflections from './inflections'

const camelizeStr = Inflections.camelize
const underscoreStr = Inflections.underscore

const module_ = {
  // Convert all property keys in an object to camelCase
  camelize(props) {
    let prop
    const attrs = {}

    for (prop in props) {
      if (props.hasOwnProperty(prop)) {
        attrs[camelizeStr(prop, true)] = props[prop]
      }
    }

    return attrs
  },

  underscore(props) {
    let prop
    const attrs = {}

    for (prop in props) {
      if (props.hasOwnProperty(prop)) {
        attrs[underscoreStr(prop)] = props[prop]
      }
    }

    return attrs
  },
}

export default module_
export const camelize = module_.camelize
export const underscore = module_.underscore
