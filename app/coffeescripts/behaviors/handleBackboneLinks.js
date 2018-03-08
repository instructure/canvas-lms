//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// listens to clicks on links that would send you to a url that is handled by a loaded backbone router
// and bypasses doing a real load to that new page.
import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'

const routeStripper = /^[#\/]/
const matchesBackboneRoute = url =>
  _.any(Backbone.history.handlers, handler => handler.route.test(url.replace(routeStripper, '')))

$(document).on('click', 'a[href]', function(event) {
  const url = $(this).attr('href')
  if (matchesBackboneRoute(url)) {
    Backbone.history.navigate(url, {trigger: true})
    event.preventDefault()
  }
})
