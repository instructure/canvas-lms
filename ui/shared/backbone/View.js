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
import {forEach, map} from 'lodash'
import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import mixin from './mixin'

const slice = [].slice

export function patch(Backbone) {
  // Extends Backbone.View on top of itself to be 100X more useful
  Backbone.View = (function (superClass) {
    extend(View, superClass)

    function View() {
      this.renderView = this.renderView.bind(this)
      this.createBindings = this.createBindings.bind(this)
      this.render = this.render.bind(this)
      return View.__super__.constructor.apply(this, arguments)
    }

    // Define default options, options passed in to the view will overwrite these
    //
    // @api public
    View.prototype.defaults = {}

    // Configures elements to cache after render. Keys are css selector strings,
    // values are the name of the property to store on the instance.
    //
    // Example:
    //
    //   class FooView extends Backbone.View
    //     els:
    //       '.toolbar': '$toolbar'
    //       '#main': '$main'
    //
    // @api public
    View.prototype.els = null

    // Defines a key on the options object to be added as an instance property
    // like `model`, `collection`, `el`, etc.
    //
    // Example:
    //   class SomeView extends Backbone.View
    //     @optionProperty 'foo'
    //   view = new SomeView foo: 'bar'
    //   view.foo #=> 'bar'
    //
    //  @param {String} property
    //  @api public
    View.optionProperty = function (property) {
      return (this.__optionProperties__ = (this.__optionProperties__ || []).concat([property]))
    }

    // Avoids subclasses that simply add a new template
    View.optionProperty('template')

    // Defines a child view that is automatically rendered with the parent view.
    // When creating an instance of the parent view the child view is passed in
    // as an `optionProperty` on the key `name` and its element will be set to
    // the first match of `selector` in the parent view's template.
    //
    // Example:
    //   class SearchView
    //     @child 'inputFilterView', '.filter'
    //     @child 'collectionView', '.results'
    //
    //   view = new SearchView
    //     inputFilterView: new InputFilterView
    //     collectionView: new CollectionView
    //   view.inputFilterView? #=> true
    //   view.collectionView? #=> true
    //
    // @param {String} name
    // @param {String} selector
    // @api public
    View.child = function (name, selector) {
      this.optionProperty(name)
      if (this.__childViews__ == null) {
        this.__childViews__ = []
      }
      return (this.__childViews__ = this.__childViews__.concat([
        {
          name,
          selector,
        },
      ]))
    }

    // Initializes the view.
    //
    // - Stores the view in the element data as 'view'
    // - Sets @model.view and @collection.view to itself
    //
    // @param {Object} options
    // @api public
    View.prototype.initialize = function (options) {
      this.options = {...this.defaults, ...options}
      this.setOptionProperties()
      this.storeChildrenViews()
      this.$el.data('view', this)
      this._setViewProperties()
      if (this.__initialize__) {
        const ref = this.__initialize__
        for (let i = 0, len = ref.length; i < len; i++) {
          const fn = ref[i]
          fn.call(this)
        }
      }
      this.attach()
      return this
    }

    // Store all children views for easy access.
    //   ie:
    //      @view.children # {@view1, @view2}
    //
    // @api private
    View.prototype.storeChildrenViews = function () {
      if (!this.constructor.__childViews__) {
        return
      }
      return (this.children = map(
        this.constructor.__childViews__,
        (function (_this) {
          return function (viewObj) {
            return _this[viewObj.name]
          }
        })(this)
      ))
    }

    // Sets the option properties
    //
    // @api private
    View.prototype.setOptionProperties = function () {
      const ref = this.constructor.__optionProperties__
      const results = []
      for (let i = 0, len = ref.length; i < len; i++) {
        const property = ref[i]
        if (this.options[property] !== void 0) {
          results.push((this[property] = this.options[property]))
        } else {
          results.push(void 0)
        }
      }
      return results
    }

    // Renders the view, calls render hooks
    //
    // @api public
    View.prototype.render = function () {
      this.renderEl()
      this._afterRender()
      return this
    }

    // Renders the HTML for the element
    //
    // @api public
    View.prototype.renderEl = function () {
      if (this.template) {
        return this.$el.html(this.template(this.toJSON()))
      }
    }

    // Caches elements from `els` config
    //
    // @api private
    View.prototype.cacheEls = function () {
      if (this.els) {
        const ref = this.els
        const results = []
        for (const selector in ref) {
          const name = ref[selector]
          results.push((this[name] = this.$(selector)))
        }
        return results
      }
    }

    // Internal afterRender
    //
    // @api private
    View.prototype._afterRender = function () {
      this.cacheEls()
      this.createBindings()
      if (this.options.views) {
        this.renderViews()
      }
      this.renderChildViews()
      return this.afterRender()
    }

    // Define in subclasses to add behavior to your view, ie. creating
    // datepickers, dialogs, etc.
    //
    // Example:
    //
    //   class SomeView extends Backbone.View
    //     els: '.dialog': '$dialog'
    //     afterRender: ->
    //       @$dialog.dialog()
    //
    // @api private
    View.prototype.afterRender = function () {
      // magic from `mixin`
      if (this.__afterRender__) {
        const ref = this.__afterRender__
        const results = []
        for (let i = 0, len = ref.length; i < len; i++) {
          const fn = ref[i]
          results.push(fn.call(this))
        }
        return results
      }
    }

    // Define in subclasses to attach your collection/model events
    //
    // Example:
    //
    //   class SomeView extends Backbone.View
    //     attach: ->
    //       @model.on 'change', @render
    //
    // @api public
    View.prototype.attach = function () {
      if (this.__attach__) {
        const ref = this.__attach__
        const results = []
        for (let i = 0, len = ref.length; i < len; i++) {
          const fn = ref[i]
          results.push(fn.call(this))
        }
        return results
      }
    }

    // Defines the locals for the template with intelligent defaults.
    //
    // Order of defaults, highest priority first:
    //
    // 1. `@model.present()`
    // 2. `@model.toJSON()`
    // 3. `@collection.present()`
    // 4. `@collection.toJSON()`
    // 5. `@options`
    //
    // Using `present` is encouraged so that when a model or collection is saved
    // to the app it doesn't send along non-persistent attributes.
    //
    // Also adds the view's `cid`.
    //
    // @api public
    View.prototype.toJSON = function () {
      const model = this.model || this.collection
      const json = model ? (model.present ? model.present() : model.toJSON()) : this.options
      json.cid = this.cid
      if (window.ENV != null) {
        json.ENV = window.ENV
      }
      return json
    }

    // Finds, renders, and assigns all child views defined with `View.child`.
    //
    // @api private
    View.prototype.renderChildViews = function () {
      let i, len, name, ref1, selector, target
      if (!this.constructor.__childViews__) {
        return
      }
      const ref = this.constructor.__childViews__
      for (i = 0, len = ref.length; i < len; i++) {
        ref1 = ref[i]
        name = ref1.name
        selector = ref1.selector
        if (this[name] == null) {
          if (typeof console !== 'undefined' && console !== null) {
            // eslint-disable-next-line no-console
            if (typeof console.warn === 'function') {
              // eslint-disable-next-line no-console
              console.warn("I need a child view '" + name + "' but one was not provided")
            }
          }
        }
        if (!this[name]) {
          continue
        }
        target = this.$(selector)
        this[name].setElement(target)
        this[name].render()
      }
      return null
    }

    // Binds a `@model` data to the element's html. Whenever the data changes
    // the view is updated automatically. The value will be html-escaped by
    // default, but the view can define a format method to specify other
    // formatting behavior with `@format`.
    //
    // Example:
    //
    //   <div data-bind="foo">{I will always mirror @model.get('foo') in here}</div>
    //
    // @api private

    /*
  xsslint safeString.method format
  */

    View.prototype.createBindings = function (_index, _el) {
      return this.$('[data-bind]').each(
        (function (_this) {
          return function (index, el) {
            const $el = $(el)
            const attribute = $el.data('bind')
            return _this.model.on('change:' + attribute, function (model, value) {
              return $el.html(_this.format(attribute, value))
            })
          }
        })(this)
      )
    }

    // Formats bound attributes values before inserting into the element when
    // using `data-bind` in the template.
    //
    // @param {String} attribute
    // @param {String} value
    // @api private
    View.prototype.format = function (attribute, value) {
      return htmlEscape(value)
    }

    // Use in cases where normal links occur inside elements with events.
    //
    // Example:
    //
    //   class RecentItemsView
    //     events:
    //       'click .header': 'expand'
    //       'click .header a': 'stopPropagation'
    //
    // @param {$Event} event
    // @api public
    View.prototype.stopPropagation = function (event) {
      return event.stopPropagation()
    }

    // Mixes in objects to a view's definition, being mindful of certain
    // properties (like events) that need to be merged also.
    //
    // @param {Object} mixins...
    // @api public
    View.mixin = function () {
      const mixins = arguments.length >= 1 ? slice.call(arguments, 0) : []
      // eslint-disable-next-line prefer-spread
      return mixin.apply(null, [this].concat(slice.call(mixins)))
    }

    // DEPRECATED - don't use views option, use `child` constructor method
    View.prototype.renderViews = function () {
      forEach(this.options.views, this.renderView)
      return this.options.views
    }

    // DEPRECATED
    View.prototype.renderView = function (view, selector) {
      let target = this.$('#' + selector)
      if (!target.length) {
        target = this.$('.' + selector)
      }
      view.setElement(target)
      view.render()
      return this[selector] != null ? this[selector] : (this[selector] = view)
    }

    View.prototype.hide = function () {
      return this.$el.hide()
    }

    View.prototype.show = function () {
      return this.$el.show()
    }

    View.prototype.toggle = function () {
      return this.$el.toggle()
    }

    // Set view property for attached model/collection objects. If
    // @setViewProperties is set to false, view properties will
    // not be set.
    //
    // Example:
    //   class SampleView extends Backbone.View
    //     setViewProperties: false
    //
    // @api private
    View.prototype._setViewProperties = function () {
      if (this.setViewProperties === false) {
        return
      }
      if (this.model) {
        this.model.view = this
      }
      if (this.collection) {
        this.collection.view = this
      }
    }

    return View
  })(Backbone.View)
}
