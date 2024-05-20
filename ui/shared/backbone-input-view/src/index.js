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

import {View} from '@canvas/backbone'

// Generic form element View that manages the inputs data and the model
// or collection it belongs to.

class InputView extends View {
  static initClass() {
    this.prototype.tagName = 'input'

    this.prototype.defaults = {modelAttribute: 'unnamed'}
  }

  initialize() {
    super.initialize(...arguments)
    return this.setupElement()
  }

  //
  // When setElement is called, need to setupElement again

  setElement() {
    super.setElement(...arguments)
    return this.setupElement()
  }

  setupElement() {
    this.lastValue = this.el?.value
    this.modelAttribute = this.$el.attr('name') || this.options?.modelAttribute
    return this.modelAttribute
  }

  attach() {
    if (!this.collection) {
      return
    }
    this.collection.on('beforeFetch', () => this.$el.addClass('loading'))
    return this.collection.on('fetch', () => this.$el.removeClass('loading'))
  }

  updateModel() {
    let {value} = this.el
    // TODO this needs to be refactored out into some validation
    // rules or something
    if (
      value &&
      value.length < this.options.minLength &&
      !(this.options.allowSmallerNumbers && value > 0)
    ) {
      if (!this.options.setParamOnInvalid) return
      value = false
    }
    return this.setParam(value)
  }

  setParam(value) {
    this.model?.set(this.modelAttribute, value)
    if (value === '') {
      return this.collection?.deleteParam(this.modelAttribute)
    } else {
      return this.collection?.setParam(this.modelAttribute, value)
    }
  }
}

InputView.prototype.tagName = 'input'
InputView.prototype.defaults = {modelAttribute: 'unnamed'}

export default InputView
