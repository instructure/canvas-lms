//
// Copyright (C) 2023 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

/* eslint-disable new-cap */
/* eslint-disable import/no-mutable-exports */
/* eslint-disable vars-on-top */
/* eslint-disable @typescript-eslint/no-shadow */
/* eslint-disable no-var */

// What follows is based on:
// from https://github.com/shinetech/backbone-identity-map/blob/d9d1b5faf8f5cf4ef05b358f65347745f0df2693/backbone-identity-map.js

/**
 * Identity Map for Backbone models.
 *
 * Usage:
 *
 *    var NewModel = IdentityMap(Backbone.Model.extend(
 *      {...},
 *      {...}
 *    ));
 *
 * A model that is wrapped in IdentityMap will cache models by their
 * ID. Any time you call new NewModel(), and you pass in an id
 * attribute, IdentityMap will check the cache to see if that object
 * has already been created. If so, that existing object will be
 * returned. Otherwise, a new model will be instantiated.
 *
 * Any models that are created without an ID will instantiate a new
 * object. If that model is subsequently assigned an ID, it will add
 * itself to the cache with this ID. If by that point another object
 * has already been assigned to the cache with the same ID, then
 * that object will be overridden.
 */
import {uniqueId, extend as lodashExtend} from 'lodash'

// Stores cached models:
// key: (unique identifier per class) + ':' + (model id)
// value: model object
var cache = {}

/**
 * realConstructor: a backbone model constructor function
 * returns a constructor function that acts like realConstructor,
 * but returns cached objects if possible.
 */
var IdentityMap = function (realConstructor) {
  var classCacheKey = uniqueId()
  var modelConstructor = lodashExtend(function (attributes, options) {
    // creates a new object (used if the object isn't found in
    // the cache)
    var create = function () {
      return new realConstructor(attributes, options)
    }
    var objectId = attributes && attributes[realConstructor.prototype.idAttribute]
    // if there is an ID, check if that object exists in the
    // cache already
    if (objectId) {
      var cacheKey = classCacheKey + ':' + objectId
      if (!cache[cacheKey]) {
        // the object has an ID, but isn't found in the cache
        cache[cacheKey] = create()
      } else {
        // the object was in the cache
        var object = cache[cacheKey]
        // set up the object just like new Backbone.Model() would
        if (options && options.parse) {
          attributes = object.parse(attributes)
        }
        object.set(attributes)
      }
      return cache[cacheKey]
    } else {
      var obj = create()
      // when an object's id is set, add it to the cache
      obj.on(
        'change:' + realConstructor.prototype.idAttribute,
        function (model, objectId) {
          cache[classCacheKey + ':' + objectId] = obj
          obj.off(null, null, this)
        },
        this
      )
      return obj
    }
  }, realConstructor)
  modelConstructor.prototype = realConstructor.prototype
  return modelConstructor
}

/**
 * Clears the cache. (useful for unit testing)
 */
IdentityMap.resetCache = function () {
  cache = {}
}

export default IdentityMap
