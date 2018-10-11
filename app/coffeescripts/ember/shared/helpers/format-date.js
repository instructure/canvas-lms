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

define ['jquery', 'ember', 'timezone', 'underscore'], ($, Ember, tz, _) ->

  {Handlebars} = Ember

  ##
  # Formats a parsable date with normal strftime formats
  #
  # ```html
  # {{format-date datetime '%b %d'}}
  # ```

  Handlebars.registerBoundHelper 'format-date', (datetime, format) ->
    return unless datetime?
    format = '%b %e, %Y %l:%M %P' unless typeof format is 'string'
    tz.format(tz.parse(datetime), format)

