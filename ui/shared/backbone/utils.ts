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

const hasProp = {}.hasOwnProperty

type Constructor = new (...args: unknown[]) => unknown

type ExtendedConstructor<T extends Constructor> = T & {
  __super__: InstanceType<T>
}

export const extend = function <C extends Constructor, P extends Constructor>(
  child: C,
  parent: P,
): ExtendedConstructor<C> {
  for (const key in parent) {
    if (hasProp.call(parent, key)) {
      ;(child as Record<string, unknown>)[key] = (parent as Record<string, unknown>)[key]
    }
  }
  function Ctor(this: {constructor: C}) {
    this.constructor = child
  }
  Ctor.prototype = parent.prototype
  child.prototype = new (Ctor as unknown as Constructor)()
  ;(child as ExtendedConstructor<C>).__super__ = parent.prototype as InstanceType<C>
  return child as ExtendedConstructor<C>
}
