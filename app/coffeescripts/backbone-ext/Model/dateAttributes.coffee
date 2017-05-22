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

  _parse = Backbone.Model::parse

  Backbone.Model::parse = ->
    res = _parse.apply(this, arguments)

    _.each @dateAttributes, (attr) ->
      if res[attr]
        res[attr] = Date.parse(res[attr])
    res

  Backbone.Model
