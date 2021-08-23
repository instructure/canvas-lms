#
# Copyright (C) 2013 - present Instructure, Inc.
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

import {View} from '@canvas/backbone'

##
# Generic form element View that manages the inputs data and the model
# or collection it belongs to.

export default class InputView extends View

  tagName: 'input'

  defaults:
    modelAttribute: 'unnamed'

  initialize: ->
    super
    @setupElement()

  ##
  # When setElement is called, need to setupElement again

  setElement: ->
    super
    @setupElement()

  setupElement: ->
    @lastValue = @el?.value
    @modelAttribute = @$el.attr('name') or @options?.modelAttribute

  attach: ->
    return unless @collection
    @collection.on 'beforeFetch', => @$el.addClass 'loading'
    @collection.on 'fetch', => @$el.removeClass 'loading'
    @collection.on 'fetch:fail', => @$el.removeClass 'loading'

  updateModel: ->
    {value} = @el
    # TODO this needs to be refactored out into some validation
    # rules or something
    if value and value.length < @options.minLength and !(@options.allowSmallerNumbers && value > 0)
      return unless @options.setParamOnInvalid
      value = false
    @setParam value

  setParam: (value) ->
    @model?.set @modelAttribute, value
    if value is ''
      @collection?.deleteParam @modelAttribute
    else
      @collection?.setParam @modelAttribute, value


