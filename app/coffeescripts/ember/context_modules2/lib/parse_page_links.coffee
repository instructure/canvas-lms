# Based on https://raw.github.com/ebryn/ember-model/master/packages/ember-model/lib/rest_adapter.js

define [
  'underscore'
], (_) ->
  # Source: https://github.com/instructure/canvas-lms/blob/stable/app/coffeescripts/collections/PaginatedCollection.coffee
  (xhr) ->
    nameRegex = /rel="([a-z]+)/
    linkRegex = /^<([^>]+)/ # Matches the full link, e.g. "/api/v1/accounts/1/users?page=1&per_page=15"
    pageRegex = /\Wpage=(\d+)/
    perPageRegex = /\per_page=(\d+)/

    linkHeader = xhr.getResponseHeader('link')?.split(',')
    linkHeader ?= []
    _.reduce linkHeader, reduceFn = (links, link) ->
      key = link.match(nameRegex)[1]
      val = link.match(linkRegex)[1]
      links[key] = val
      links
    , {}