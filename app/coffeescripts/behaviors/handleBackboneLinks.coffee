# listens to clicks on links that would send you to a url that is handled by a loaded backbone router
# and bypasses doing a real load to that new page.
require [
  'jquery'
  'underscore'
  'Backbone'
], ($, _, Backbone) ->

  routeStripper = /^[#\/]/
  matchesBackboneRoute = (url) ->
    _.any Backbone.history.handlers, (handler) ->
      handler.route.test url.replace(routeStripper, '')

  $(document).on 'click', 'a[href]', (event) ->
    url = $(this).attr('href')
    if matchesBackboneRoute(url)
      Backbone.history.navigate url, trigger: true
      event.preventDefault()