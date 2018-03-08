/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(function() {
  /**
   * @method fromJSONAPI
   * @member Models
   *
   * Given a JSON payload, extract an object that *might* be scoped inside
   * a named JSON-API collection key. In the case that key does not exist,
   * regular JSON payload is assumed and the top-level object is returned.
   *
   * @param {Object} payload
   *
   * @param {String} collKey
   *        Key to the primary collection you expect to exist in the payload.
   *
   * @param {Boolean} [wantsObject=false]
   *        In the case the extracted object turns out to be an array, you can
   *        pass this to true and retrieve the first item in the array.
   *        It is common for JSON-API payloads to wrap single objects in an
   *        array.
   *
   * @return {Object|Array}
   */
  return function fromJSONAPI(payload, collKey, wantsObject) {
    var data = {}

    if (payload) {
      if (payload[collKey]) {
        data = payload[collKey]
      } else {
        data = payload
      }
    }

    if (wantsObject && Array.isArray(data)) {
      return data[0]
    } else {
      return data
    }
  }
})
