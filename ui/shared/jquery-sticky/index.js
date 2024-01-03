//
// Copyright (C) 2012 - present Instructure, Inc.
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

import {debounce, reject} from 'lodash'
import $ from 'jquery'

export default class Sticky {
  static instances = []

  static initialized = false

  static $container = $(window)

  static initialize() {
    this.$container.on('scroll', debounce(this.checkInstances, 10))
    this.initialized = true
  }

  static addInstance(instance) {
    if (!this.initialized) this.initialize()
    this.instances.push(instance)
    this.checkInstances()
  }

  static removeInstance(instance) {
    if (!this.initialized) this.initialize()
    this.instances = reject(this.instances, i => i === instance)
    this.checkInstances()
  }

  static checkInstances() {
    const containerTop = Sticky.$container.scrollTop()
    Sticky.instances.forEach(instance => {
      if (containerTop >= instance.top) {
        if (!instance.stuck) instance.stick()
      } else if (instance.stuck) instance.unstick()
    })
  }

  constructor($el) {
    this.$el = $el
    this.top = this.$el.offset().top
    this.stuck = false
    this.constructor.addInstance(this)
  }

  stick() {
    this.$el.addClass('sticky')
    this.stuck = true
  }

  unstick() {
    this.$el.removeClass('sticky')
    this.stuck = false
  }

  remove() {
    this.unstick()
    this.constructor.removeInstance(this)
  }
}

$.fn.sticky = function () {
  return this.each(function () {
    new Sticky($(this))
  })
}

$(() => $('[data-sticky]').sticky())
