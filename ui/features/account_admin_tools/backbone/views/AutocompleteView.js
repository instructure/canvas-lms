//
// Copyright (C) 2013 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import $ from 'jquery'
import template from '../../jst/autocomplete.handlebars'
import 'jqueryui/menu'
import 'jqueryui/autocomplete'
import _inherits from '@babel/runtime/helpers/esm/inheritsLoose'

_inherits(AutocompleteView, Backbone.View)

export default function AutocompleteView(options) {
  this.options = options
  this.collection = this.options.collection
  Backbone.View.apply(this, arguments)

  if (!this.options.minLength) this.options.minLength = 3
  if (!this.options.labelProperty) this.options.labelProperty = 'name'
  if (!this.options.valueProperty) this.options.valueProperty = 'id'
  if (!this.options.fieldName) this.options.fieldName = this.options.valueProperty
  if (!this.options.placeholder) this.options.placeholder = this.options.fieldName
  if (!this.options.sourceParameters) this.options.sourceParameters = {}
}

Object.assign(AutocompleteView.prototype, {
  template,

  els: {
    '[data-name=autocomplete_search_term]': '$searchTerm',
    '[data-name=autocomplete_search_value]': '$searchValue',
  },

  toJSON() {
    return this.options
  },

  afterRender() {
    return this.$searchTerm.autocomplete({
      minLength: this.options.minLength,
      select: $.proxy(this.autocompleteSelect, this),
      source: $.proxy(this.autocompleteSource, this),
      change: $.proxy(this.autocompleteSelect, this),
    })
  },

  autocompleteSource(request, response) {
    this.$searchTerm.addClass('loading')
    const params = {data: this.options.sourceParameters}
    params.data.search_term = request.term
    const {labelProperty} = this.options

    function success() {
      const items = this.collection.map(item => {
        let label
        if ($.isFunction(labelProperty)) label = labelProperty(item)
        if (!label) label = item.get(labelProperty)
        return {model: item, label}
      })
      this.$searchTerm.removeClass('loading')
      return response(items)
    }

    return this.collection.fetch(params).success($.proxy(success, this))
  },

  autocompleteSelect(event, ui) {
    if (ui.item && ui.item.value) {
      return this.$searchValue.val(ui.item.model.id)
    } else {
      return this.$searchValue.val(null)
    }
  },
})
