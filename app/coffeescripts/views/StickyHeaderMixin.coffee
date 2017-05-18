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
  'jquery'
  'compiled/jquery/sticky'
], ($) ->

  # Remember, you must define a toolbar with data attribute 'data-sticky'
  # for this to work. Also don't forget to create your own styles for the 
  # sticky class that gets added to the dom element

  afterRender: ->
    @stickyHeader.remove() if @stickyHeader
    @stickyHeader = @$('[data-sticky]').sticky()
