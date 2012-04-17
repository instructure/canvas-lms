#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# cache.coffee
# defines a caching mixin for classes. may use memory, sessionStorage, or
# localStorage to hold cached data. also accepts a prefix to namespace any
# data stored (e.g. if using localStorage).
#
# ex.
#
# class Thing
#   constructor: ->
#     $.extend true, this, cache
#     ...
#
# thing = new Thing
# thing.cache.use 'memory'
# thing.cache.set 'key', 'value'
# thing.cache.get 'key'

define ['underscore'], (_) ->
  cache:
    prefix: ''
    store: {}

    ##
    # set the storage mechanism. available options are:
    #   * memory
    #   * sessionStorage
    #   * localStorage
    #
    #   ex.
    #
    #   @obj.cache.use 'localStorage'
    #
    # @api public
    use: (store) ->
      @store = switch store
        when 'memory' then {}
        when 'sessionStorage' then sessionStorage
        when 'localStorage' then localStorage

    ##
    # create a unique key from an array of arguments by
    # converting them to json.
    #
    # @return String
    # @api private
    toKey: (key...) ->
      @prefix + (JSON.stringify(arg) for arg in _.flatten(key)).join '|'

    ##
    # given a key, return an item from the cache. a key may
    # be a single string, array, object, or a combination of
    # those.
    #
    # ex.
    #
    # @thing.cache.get 'keyName'
    # @thing.cache.get [1, 2, 3], @name, @params
    #
    # @return String|Object|Array|Boolean
    # @api public
    get: (key...) ->
      if val = @store[@toKey(key)]
        JSON.parse val
      else
        null

    ##
    # given a value and a key, store data in the cache. returns
    # the cache object so that additional set actions can be
    # chained.
    #
    # ex.
    #
    # @thing.set 'value', 'keyValue'
    # @thing.set { value: 123 }, [@name, request.params]
    # @thing
    #   .set('value1', 'key1')
    #   .set('value2', 'key2')
    #
    # @api public
    set: (key..., value) ->
      @store[@toKey(key)] = JSON.stringify value
      this

    ##
    # given a key, remove its contents from the cache
    remove: (key...) ->
      delete @store[@toKey(key)]

