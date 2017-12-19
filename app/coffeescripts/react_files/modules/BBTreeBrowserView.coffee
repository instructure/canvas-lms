#
# Copyright (C) 2014 - present Instructure, Inc.
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

define [
  'jquery'
  'i18n!BBTreeBrowserView'
  '../../views/TreeBrowserView'
], ($, I18n, TreeBrowserView) ->

  class BBTreeBrowserView
    @views: []
    @create: (bbOptions, options = {}) ->
      options.render ||= false
      view  = new TreeBrowserView(bbOptions)
      viewObj = {view, viewOptions: bbOptions, renderOptions: options}
      length = @views.push(viewObj)
      index = length - 1
      @set(index, {index})

      if options.render
        console.error(I18n.t("`element` option missing error: An element to attach the TreeBrowserView to must be specified when setting the render option to 'true' for BBTreeBrowserView")) unless options.element?
        @render(index, options.element, options.callback) if options.element

      return @get(index)
    @set: (index, newValues = {}) ->
      if currentValues = @get(index)
        values = $.extend(currentValues, newValues)
        currentValues = values
    @get: (index) ->
      @views[index] or null
    @getView: (index) ->
      @get(index)?.view or null
    @remove: (index) ->
      @views.splice(index, 1)
      @refresh()
    @getViews: ->
      @views
    @render: (index, element, callback) ->
      setTimeout(=>
        @getView(index)?.render()?.$el?.appendTo(element)
      , 0)
      callback() if typeof callback is "function"
    @refresh: ->
      for item in @views
        index = item.index
        previous = @get(index)
        @remove(index)
        item.view.destroyView()
        refreshed = @create(previous.viewOptions, previous.renderOptions)
        unless previous.renderOptions.render
          @render(refreshed.index, refreshed.renderOptions.element, refreshed.renderOptions.callback)
        refreshed

