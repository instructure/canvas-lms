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

define [
  'underscore'
  'Backbone'
  '../models/DaySubstitution'
], (_, Backbone, DaySubstitution) ->

  class DaySubstitutionCollection extends Backbone.Collection
    model: DaySubstitution

    # This rips out the day sub days from their respective models as well as
    # eliminates any duplicated days. For instance, a daySub might have
    # the following attributes: 
    #    "0" : "5"
    #  Another subDay might have
    #    "3" : "4"
    # This will take all of those attributes and put them in one object. The 
    # result will look like this. 
    #   {"0" : "5", "3" : "4"}
    #
    # @api public backbone override 
    toJSON: -> 
     @reduce(
        (memo, daySub) => _.extend(memo, daySub.attributes)
      , {})
