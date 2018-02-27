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

import $ from 'jquery'
import I18n from 'i18n!BBTreeBrowserView'
import TreeBrowserView from '../../views/TreeBrowserView'

export default class BBTreeBrowserView {
  static create(bbOptions, options = {}) {
    if (!options.render) {
      options.render = false
    }
    const view = new TreeBrowserView(bbOptions)
    const viewObj = {view, viewOptions: bbOptions, renderOptions: options}
    const length = this.views.push(viewObj)
    const index = length - 1
    this.set(index, {index})

    if (options.render) {
      if (options.element == null) {
        console.error(
          I18n.t(
            "`element` option missing error: An element to attach the TreeBrowserView to must be specified when setting the render option to 'true' for BBTreeBrowserView"
          )
        )
      }
      if (options.element) {
        this.render(index, options.element, options.callback)
      }
    }

    return this.get(index)
  }

  static set(index, newValues = {}) {
    let currentValues
    if ((currentValues = this.get(index))) {
      const values = $.extend(currentValues, newValues)
      return (currentValues = values)
    }
  }

  static get(index) {
    return this.views[index] || null
  }

  static getView(index) {
    return (this.get(index) && this.get(index).view) || null
  }

  static remove(index) {
    this.views.splice(index, 1)
    return this.refresh()
  }

  static getViews() {
    return this.views
  }

  static render(index, element, callback) {
    setTimeout(() => {
      const view = this.getView(index)
      if (view) {
        const res = view.render()
        res && res.$el && res.$el.appendTo(element)
      }
    }, 0)
    if (typeof callback === 'function') return callback()
  }

  static refresh() {
    return this.views.map(item => {
      const {index} = item
      const previous = this.get(index)
      this.remove(index)
      item.view.destroyView()
      const refreshed = this.create(previous.viewOptions, previous.renderOptions)
      if (!previous.renderOptions.render) {
        this.render(
          refreshed.index,
          refreshed.renderOptions.element,
          refreshed.renderOptions.callback
        )
      }
      return refreshed
    })
  }
}
BBTreeBrowserView.views = []
