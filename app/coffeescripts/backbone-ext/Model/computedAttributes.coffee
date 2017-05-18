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

define ['node_modules-version-of-backbone', 'underscore'], (Backbone, _) ->

  _.extend Backbone.Model.prototype,

    initialize: ->
      @_configureComputedAttributes() if @computedAttributes?

    ##
    # Allows computed attributes. If your attribute depends on other
    # attributes in the model, pass in an object with the dependencies
    # and your computed attribute will stay up-to-date.
    #
    # ex.
    #
    #   class SomeModel extends Backbone.Model
    #
    #     defaults:
    #       first_name: 'Jon'
    #       last_name: 'Doe'
    #
    #     computedAttributes: [
    #       # can send a string for simple attributes
    #       'occupation'
    #
    #       # or an object for attributes with dependencies
    #       {
    #         name: 'fullName'
    #         deps: ['first_name', 'last_name']
    #       }
    #     ]
    #
    #     occupation: ->
    #       # some sort of computation...
    #       'programmer'
    #
    #     fullName: ->
    #       @get('first_name') + ' ' + @get('last_name')
    #
    #
    #  model = new SomeModel()
    #  model.get 'fullName' #> 'Jon Doe'
    #  model.set 'first_name', 'Jane'
    #  model.get 'fullName' #> 'Jane Doe'
    #  model.get 'occupation' #> 'programmer'
    _configureComputedAttributes: ->
      set = (methodName) => @set methodName, @[methodName]()

      _.each @computedAttributes, (methodName) =>
        if typeof methodName is 'string'
          set methodName
        else # config object
          set methodName.name
          eventName = _.map(methodName.deps, (name) -> "change:#{name}").join ' '
          @bind eventName, -> set methodName.name

  Backbone.Model

