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
  'ember'
  'ic-ajax'
  './parse_link_header'
], ({$, ArrayProxy}, ajax, parseLinkHeader) ->

  fetch = (url, options) ->
    opts = $.extend({dataType: "json"}, {data: options.data})
    records = options.records
    ajax.raw(url, opts).then (result) ->
      response = if options.process
        options.process(result.response)
      else
        result.response
      records.pushObjects response
      meta = parseLinkHeader result.jqXHR
      if meta.next
        fetch meta.next, options
      else
        records.set('isLoaded', true)
        records.set('isLoading', false)
        records

  fetchAllPages = (url, options = {}) ->
    records = options.records ||= ArrayProxy.create({content: []})
    records.set('isLoading', true)
    records.set('promise', fetch(url, options))
    records
