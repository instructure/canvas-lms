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

export default function populateCollection(collection, payload, replace) {
  let setter, setterOptions

  if (arguments.length === 2) {
    replace = true
  }

  setter = replace ? 'reset' : 'add'
  setterOptions = replace ? {parse: true} : {parse: true, merge: true}

  collection[setter].call(collection, payload, setterOptions)
}
