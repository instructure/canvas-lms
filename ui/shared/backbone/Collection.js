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

/* eslint-disable no-void */

import {extend} from './utils'
import mixin from './mixin'
import DefaultUrlMixin from './DefaultUrlMixin'
import {
  each,
  extend as lodashExtend,
  first,
  keyBy,
  isArray,
  isBoolean,
  isEmpty,
  isObject,
  isString,
  keys,
  map,
  omit,
  pick,
} from 'lodash'

const slice = [].slice

export function patch(Backbone) {
  Backbone.Collection = (function (superClass) {
    extend(Collection, superClass)

    function Collection() {
      return Collection.__super__.constructor.apply(this, arguments)
    }

    // # Mixes in objects to a model's definition, being mindful of certain
    // # properties (like defaults) that need to be merged also.
    // #
    // # @param {Object} mixins...
    // # @api public
    Collection.mixin = function () {
      const mixins = arguments.length >= 1 ? slice.call(arguments, 0) : []
      // eslint-disable-next-line prefer-spread
      return mixin.apply(null, [this].concat(slice.call(mixins)))
    }

    Collection.mixin(DefaultUrlMixin)

    // # Define default options, options passed in to the constructor will
    // # overwrite these
    Collection.prototype.defaults = {
      // # Define some parameters for fetching, they'll be added to the url
      // #
      // # For example:
      // #
      // #   params:
      // #     foo: 'bar'
      // #     baz: [1,2]
      // #
      // # becomes:
      // #
      // #   ?foo=bar&baz[]=1&baz[]=2
      params: void 0,
      // # If using the conventional default URL, define a resource name here or
      // # on your model. See `_defaultUrl` for more details.
      resourceName: void 0,
      // # If using the conventional default URL, define this, or let it fall back
      // # to ENV.context_asset_url. See `_defaultUrl` for more details.
      contextAssetString: void 0,
    }

    // # Defines a key on the options object to be added as an instance property
    // # like `model`, `collection`, `el`, etc. on a Backbone.View
    // #
    // # Example:
    // #   class UserCollection extends Backbone.Collection
    // #     @optionProperty 'sections'
    // #   view = new UserCollection
    // #     sections: new SectionCollection
    // #   view.sections #=> SectionCollection
    // #
    // #  @param {String} property
    // #  @api public
    Collection.optionProperty = function (property) {
      return (this.__optionProperties__ = (this.__optionProperties__ || []).concat([property]))
    }

    // # Sets the option properties
    // #
    // # @api private
    Collection.prototype.setOptionProperties = function () {
      let i, len, property
      const ref = this.constructor.__optionProperties__
      const results = []
      for (i = 0, len = ref.length; i < len; i++) {
        property = ref[i]
        if (this.options[property] !== void 0) {
          results.push((this[property] = this.options[property]))
        } else {
          results.push(void 0)
        }
      }
      return results
    }

    // # `options` will be merged into @defaults. Some options will become direct
    // # properties of your instance, see `_directPropertyOptions`
    Collection.prototype.initialize = function (models, options) {
      this.options = lodashExtend({}, this.defaults, options)
      this.setOptionProperties()
      return Collection.__super__.initialize.apply(this, arguments)
    }

    // # Sets a paramter on @options.params that will be used in `fetch`
    Collection.prototype.setParam = function (name, value) {
      let base
      if ((base = this.options).params == null) {
        base.params = {}
      }
      this.options.params[name] = value
      return this.trigger('setParam', name, value)
    }

    // # Sets multiple params at once and triggers setParams event
    // #
    // # @param {Object} params
    Collection.prototype.setParams = function (params) {
      let name, value
      for (name in params) {
        value = params[name]
        this.setParam(name, value)
      }
      return this.trigger('setParams', params)
    }

    // Deletes a parameter from @options.params
    Collection.prototype.deleteParam = function (name) {
      let ref
      if ((ref = this.options.params) != null) {
        delete ref[name]
      }
      return this.trigger('deleteParam', name)
    }

    Collection.prototype.fetch = function (options) {
      if (options == null) {
        options = {}
      }
      // TODO: we might want to merge options.data and options.params here instead
      if (options.data == null && this.options.params != null) {
        options.data = this.options.params
      }
      return Collection.__super__.fetch.call(this, options)
    }

    Collection.prototype.url = function () {
      return this._defaultUrl()
    }

    Collection.optionProperty('contextAssetString')

    Collection.optionProperty('resourceName')

    // # Overridden to allow recognition of jsonapi.org url style compound
    // # documents.
    // #
    // # These compound documents side load related objects as secondary
    // # collections under the linked attribute, rather than embedded within
    // # the primary collection's objects. The primary collection is defined
    // # by following the jsonapi.org standard.  This will look for the first
    // # collection after removing reserved keys.
    // #
    // # To adapt this style to Backbone, we check for any jsonapi.org reserved
    // # keys and, if any are found, we extract the first primary collection and
    // # pre-process any declared side loads into the embedded format that Backbone
    // # expects.
    // #
    // # Declaring recognized side loads is done through the `sideLoad' property
    // # on the collection class. The value of this property is an object whose
    // # keys identify the target relation property on the primary objects. The
    // # values for those keys can either be `true', a string, or an object.
    // #
    // # If the value is an object, the foreign key and side loaded collection
    // # name are identified by the `foreignKey' and `collection' properties,
    // # respectively. Absent properties are inferred from the relation name.
    // #
    // # A value is `true' is treated the same as an empty object (side load
    // # defined, but properties to be inferred). A string value is treated as a
    // # hash with a collection name, leaving the foreign key to be inferred.
    // #
    // # If the value of a foreign key is an array it will be treated as a to_many
    // # relationship and load all related documents.
    // #
    // # For examples, the following are all identical:
    // #
    // #   sideLoad:
    // #     author: true
    // #
    // #   sideLoad:
    // #     author:
    // #       collection: 'authors'
    // #
    // #   sideLoad:
    // #     author:
    // #       foreignKey: 'author'
    // #       collection: 'authors'
    // #
    // # If the authors are instead contained in the `people' collection, the
    // # following can be used interchangeably:
    // #
    // #   sideLoad:
    // #     author:
    // #       collection: 'people'
    // #
    // #   sideLoad:
    // #     author:
    // #       foreignKey: 'author'
    // #       collection: 'people'
    // #
    // # Alternately, if the collection is `authors' and the target relation
    // # property is `author', but the foreign key is `person' (such a silly
    // # API), you can use:
    // #
    // #   sideLoad:
    // #     author:
    // #       foreignKey: 'person'
    // #
    Collection.prototype.parse = function (response, options) {
      if (response == null) {
        return Collection.__super__.parse.apply(this, arguments)
      }
      const rootMeta = pick(response, 'meta', 'links', 'linked')
      if (isEmpty(rootMeta)) {
        return Collection.__super__.parse.apply(this, arguments)
      }
      const collections = omit(response, 'meta', 'links', 'linked')
      if (isEmpty(collections)) {
        return Collection.__super__.parse.apply(this, arguments)
      }
      const collectionKeys = keys(collections)
      const primaryCollectionKey = first(collectionKeys)
      const primaryCollection = collections[primaryCollectionKey]
      if (primaryCollection == null) {
        return Collection.__super__.parse.apply(this, arguments)
      }
      if (collectionKeys.length > 1) {
        if (typeof console !== 'undefined' && console !== null) {
          // eslint-disable-next-line no-console
          if (typeof console.warn === 'function') {
            // eslint-disable-next-line no-console
            console.warn(
              "Found more then one primary collection, using '" + primaryCollectionKey + "'."
            )
          }
        }
      }
      const index = {}
      each(rootMeta.linked || {}, function (link, key) {
        return (index[key] = keyBy(link, 'id'))
      })
      if (isEmpty(index)) {
        return Collection.__super__.parse.call(this, primaryCollection, options)
      }
      each(this.sideLoad || {}, function (meta, relation) {
        let collection, foreignKey
        if (isBoolean(meta) && meta) {
          meta = {}
        }
        if (isString(meta)) {
          meta = {
            collection: meta,
          }
        }
        if (!isObject(meta)) {
          return
        }
        foreignKey = meta.foreignKey
        collection = meta.collection
        if (foreignKey == null) {
          foreignKey = '' + relation
        }
        if (collection == null) {
          collection = relation + 's'
        }
        collection = index[collection] || {}
        each(primaryCollection, function (item) {
          let related
          if (!item.links) {
            return
          }
          related = null
          const id = item.links[foreignKey]
          if (isArray(id)) {
            if (isEmpty(collection)) {
              collection = index[relation] || index[foreignKey]
              if (collection == null) {
                // eslint-disable-next-line no-throw-literal
                throw (
                  "Could not find linked collection for '" +
                  relation +
                  "' using '" +
                  foreignKey +
                  "'."
                )
              }
            }
            related = map(id, function (pk) {
              return collection[pk]
            })
          } else {
            related = collection[id]
          }
          if (id != null && related != null) {
            item[relation] = related
            delete item.links[foreignKey]
            if (isEmpty(item.links)) {
              return delete item.links
            }
          }
        })
      })
      return Collection.__super__.parse.call(this, primaryCollection, options)
    }

    return Collection
  })(Backbone.Collection)
}
