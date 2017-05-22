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

define ['underscore', 'node_modules-version-of-backbone'], (_, Backbone) ->

  _.extend Backbone.Model.prototype,

    # normalize (i.e. I18n) and filter errors we get from the API
    normalizeErrors: (errors, validationPolicy) ->
      result = {}
      errorMap = @errorMap ? @constructor::errorMap ? {}
      errorMap = errorMap(validationPolicy) if _.isFunction(errorMap)
      if errors
        for attr, attrErrors of errors when errorMap[attr]
          for error in attrErrors when errorMap[attr][error.type]
            result[attr] ?= []
            result[attr].push errorMap[attr][error.type]
      result

  Backbone.Model

