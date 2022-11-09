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

const hasProp = {}.hasOwnProperty

export function extend(child, parent) {
  for (const key in parent) {
    if (hasProp.call(parent, key)) child[key] = parent[key]
  }
  function Ctor() {
    this.constructor = child
  }
  Ctor.prototype = parent.prototype
  child.prototype = new Ctor()
  child.__super__ = parent.prototype
  return child
}

/**
 * since you can't use es6 Object initializer getter shorthand (eg: {get foo(){ return 'bar'}})
 * in coffeescript, this is a helper to do it the manual way using Object.defineProperty
 * @param {Object} [hostObject] the object that you want to define the getters onto
 * @param {Object} getters key/value pairs of "propertyName" and getter functions. eg: {foo: () => "bar"}
 * @returns {Object} hostObject
 */
export function shimGetterShorthand(hostObject, getters) {
  Object.keys(getters).forEach(key =>
    Object.defineProperty(hostObject, key, {
      get: getters[key],
      enumerable: true,
      configurable: true,
    })
  )
  return hostObject
}
