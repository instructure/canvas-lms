#
# Copyright (C) 2017 - present Instructure, Inc.
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

define [], ->

  class SisValidationHelper

    constructor: (params) ->
      @postToSIS = params['postToSIS']
      @dueDateRequired = params['dueDateRequired']
      @maxNameLengthRequired = params['maxNameLengthRequired']
      @dueDate = params['dueDate']
      @modelName = params['name']
      @maxNameLength = params['maxNameLength']

    nameTooLong: ->
      return false unless @postToSIS
      if @maxNameLengthRequired
        @nameLengthComparison()
      else if !@maxNameLengthRequired && @maxNameLength == 256
        @nameLengthComparison()

    nameLengthComparison: ->
      @modelName.length > @maxNameLength

    dueDateMissing: ->
      return false unless @postToSIS
      @dueDateRequired && (@dueDate == null || @dueDate == undefined)
