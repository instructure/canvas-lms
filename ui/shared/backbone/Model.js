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

import {extend} from './utils'
import mixin from './mixin'
import './Model/computedAttributes'
import './Model/dateAttributes'
import './Model/errors'

const slice = [].slice

export function patch(Backbone) {
  Backbone.Model = (function (superClass) {
    extend(Model, superClass)

    function Model() {
      return Model.__super__.constructor.apply(this, arguments)
    }

    // Mixes in objects to a model's definition, being mindful of certain
    // properties (like defaults) that need to be merged also.
    //
    // @param {Object} mixins...
    // @api public
    Model.mixin = function () {
      const mixins = arguments.length >= 1 ? slice.call(arguments, 0) : []
      // eslint-disable-next-line prefer-spread
      return mixin.apply(null, [this].concat(slice.call(mixins)))
    }

    Model.prototype.initialize = function (attributes, options) {
      let fn, i, len, ref
      Model.__super__.initialize.apply(this, arguments)
      this.options = {...this.defaults, ...options}
      if (this.__initialize__) {
        ref = this.__initialize__
        for (i = 0, len = ref.length; i < len; i++) {
          fn = ref[i]
          fn.call(this)
        }
      }
      return this
    }

    //   Trigger an event indicating an item has started to save. This
    //   can be used to add a loading icon or trigger another event
    //   when an model tries to save itself.
    //
    //   For example, inside of the initializer of the model you want
    //   to show a loading icon you could do something like this
    //
    //   @model.on 'saving', -> console.log "Do something awesome"
    //
    // @api backbone override
    Model.prototype.save = function () {
      this.trigger('saving')
      return Model.__super__.save.apply(this, arguments)
    }

    // Method Summary
    //   Trigger an event indicating an item has started to delete. This
    //   can be used to add a loading icon or trigger an event while the
    //   model is being deleted.
    //
    //   For example, inside of the initializer of the model you want to
    //   show a loading icon, you could do something like this.
    //
    //   @model.on 'destroying', -> console.log 'Do something awesome'
    //
    // @api backbone override
    Model.prototype.destroy = function () {
      this.trigger('destroying')
      return Model.__super__.destroy.apply(this, arguments)
    }

    // Increment an attribute by 1 (or the specified amount)
    Model.prototype.increment = function (key, delta) {
      if (delta == null) {
        delta = 1
      }
      return this.set(key, this.get(key) + delta)
    }

    // Decrement an attribute by 1 (or the specified amount)
    Model.prototype.decrement = function (key, delta) {
      if (delta == null) {
        delta = 1
      }
      return this.increment(key, -delta)
    }

    // Add support for nested attributes on a backbone model. Nested
    // attributes are indicated by a . to seperate each level. You get
    // get nested attributes by doing the following.
    // ie:
    //   // given {foo: {bar: 'catz'}}
    //   @get 'foo.bar' // returns catz
    //
    // @api backbone override
    Model.prototype.deepGet = function (property) {
      let next, value
      const split = property.split('.')
      value = this.get(split.shift())
      while ((next = split.shift())) {
        value = value[next]
      }
      return value
    }

    return Model
  })(Backbone.Model)
}
