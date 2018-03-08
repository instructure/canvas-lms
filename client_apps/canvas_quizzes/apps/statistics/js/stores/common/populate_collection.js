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
   * Populate a collection with some data.
   *
   * @method populateCollection
   * @member Statistics.Stores
   *
   * @param {Backbone.Collection} collection
   * @param {Object} payload
   *        The payload to extract data from. This is what you received by
   *        hitting the Canvas JSON-API endpoints.
   *
   * @param {Boolean} [replace=true]
   *        Consider the incoming data as a replacement for the current one.
   *        E.g, the collections will be reset instead of just adding the
   *        new data.
   *
   */
  return function populateCollection(collection, payload, replace) {
    var setter, setterOptions

    if (arguments.length === 2) {
      replace = true
    }

    setter = replace ? 'reset' : 'add'
    setterOptions = replace ? {parse: true} : {parse: true, merge: true}

    collection[setter].call(collection, payload, setterOptions)
  }
})
