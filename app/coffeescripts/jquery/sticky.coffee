#
# Copyright (C) 2012 - present Instructure, Inc.
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

define ['underscore', 'jquery'], (_, $) ->

  class Sticky

    @instances: []

    @initialized: false

    @$container = $ window

    @initialize: ->
      @$container.on 'scroll', _.debounce(@checkInstances, 10)
      @initialized = true

    @addInstance: (instance) ->
      @initialize() unless @initialized
      @instances.push instance
      @checkInstances()

    @removeInstance: (instance) ->
      @initialize() unless @initialized
      @instances = _.reject @instances, (i) -> i == instance
      @checkInstances()

    @checkInstances: =>
      containerTop = @$container.scrollTop()
      for instance in @instances
        if containerTop >= instance.top
          instance.stick() unless instance.stuck
        else
          instance.unstick() if instance.stuck
      null

    constructor: (@$el) ->
      @top = @$el.offset().top
      @stuck = false
      @constructor.addInstance this

    stick: ->
      @$el.addClass 'sticky'
      @stuck = true

    unstick: ->
      @$el.removeClass 'sticky'
      @stuck = false

    remove: ->
      @unstick()
      @constructor.removeInstance this

  $.fn.sticky = ->
    @each -> new Sticky $ this

  $ -> $('[data-sticky]').sticky()

  Sticky
