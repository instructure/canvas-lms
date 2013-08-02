#
# Copyright (C) 2013 Instructure, Inc.
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

# When a user mouses within @options.threshold of the target, load additional
# javascript.
#
# Examples
#
# loader = new ProximityLoader '.target',
#   callback: (Lib) -> Lib.dostuff()
#   dependencies: ['compiled/util/Lib']
#
# loader = new ProximityLoader '.target',
#   callback: (Lib) -> Lib.dostuff()
#   delay: 100
#   dependencies: ['compiled/util/Lib']
#   threshold: 300

define [
  'jquery'
  'underscore'
], ($, _) ->

  class ProximityLoader

    # Internal: Default configuration.
    #
    # callback - Callback to fire on dependency load. Receives as arguments
    #   the libraries given in dependencies.
    # delay - The number of milliseconds to throttle mousemove events within.
    # dependencies - An array of dependency strings, e.g. 'compiled/views/MyView'
    # threshold - The number of pixels around the target to watch.
    #
    defaultOptions:
      callback: $.noop
      delay: 200
      dependencies: []
      threshold: 150

    constructor: (el, options = {}) ->
      @options = _.extend({}, @defaultOptions, options)
      @_cacheElements(el)
      @deferred = $.Deferred().then(@_loadScript)
      # fail if the given element doesn't exist
      return unless @$el.length
      @_attachEvents()

    # Internal: Store element references for later use.
    #
    # el - Target element to cache as @$el.
    #
    # Returns nothing.
    _cacheElements: (el) ->
      @$el   = $(el)
      @$body = $('body')

    # Internal: Listen for mousemove events on <body />.
    #
    # Returns nothing.
    _attachEvents: ->
      @$body.on(@_eventName(), _.throttle(@_onMove, @options.delay))

    # Internal: Convenience method for creating unique event names.
    #
    # Returns an event name string.
    _eventName: ->
      "mousemove.proximity.#{@$el.guid}"

    # Internal: Calculate/cache dimensions of target + threshold.
    #
    # Returns a dimensions object.
    _dimensions: ->
      @__dimensions or=
        bottom: @$el.offset().top + @$el.height() + @options.threshold
        left: @$el.offset().left - @options.threshold
        right: @$el.offset().left + @$el.width() + @options.threshold
        top: @$el.offset().top - @options.threshold
        centerX: @$el.offset().left + (@$el.width() / 2)
        centerY: @$el.offset().top + (@$el.height() / 2)

    # Internal: Check position on mouse move and store last mouse position..
    #
    # e - Event object.
    #
    # Returns nothing.
    _onMove: (e) =>
      if @_isBounded(e.pageX, e.pageY) and @_hasVelocity(e.pageX, e.pageY)
        @deferred.resolve()
      {@pageX, @pageY} = e

    # Internal: Load dependencies and assign callback.
    #
    # Returns nothing.
    _loadScript: =>
      @$body.off(@_eventName())
      require(@options.dependencies, @options.callback)

    # Internal: Determine if current event is within el + threshold dimensions.
    #
    # x - X coordinate of the mouse event.
    # y - Y coordinate of the mouse event.
    #
    # Returns boolean.
    _isBounded: (x, y) ->
      @_dimensions().left < x and @_dimensions().right > x and
        @_dimensions().top < y and @_dimensions().bottom > y

    # Internal: Determine if the mouse is moving towards or away from @$el.
    #
    # x - X coordinate of the mouse event.
    # y - Y coordinate of the mouse event.
    #
    # Returns boolean.
    _hasVelocity: (x, y) ->
      Math.abs(@pageX - @_dimensions().centerX) > Math.abs(x - @_dimensions().centerX) and
        Math.abs(@pageY - @_dimensions().centerY) > Math.abs(y - @_dimensions().centerY)
