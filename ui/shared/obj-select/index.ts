// @ts-nocheck
/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

// select properties from an object and returns a new obj with those props
// inspired by ruby's select method
// example: select(assignment, ['name', 'points']) would return a new object like { name: 'foo', points: 20 }
// esp useful for mapping state props in redux connected components
export default function select(obj: Object, props: Array<string | [string, string]>): Object {
  return props.reduce((propSet, prop) => {
    // allows aliasing selected props by passing an array like [old_prop, new_prop]
    // for examle select(assignment, ['points', ['assignment_name', 'name']]) will copy `assignment_name` into `name`
    const [src, dest] = Array.isArray(prop) ? prop : [prop, prop]
    return Object.assign(propSet, {[dest]: obj[src]})
  }, {})
}
