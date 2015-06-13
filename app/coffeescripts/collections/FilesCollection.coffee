#
# Copyright (C) 2013 Instructure, Inc.
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
#

define [
  'compiled/collections/PaginatedCollection'
  'underscore'
  'compiled/models/File'
], (PaginatedCollection, _, File) ->

  class FilesCollection extends PaginatedCollection
    @optionProperty 'parentFolder'

    model: File

    initialize: ->
      @on 'change:sort change:order', @setQueryStringParams
      super

    fetch: (options = {}) ->
      options.data = _.extend content_types: @parentFolder?.contentTypes, options.data || {}
      options.data.use_verifiers = 1 if @parentFolder?.useVerifiers
      res = super options

    parse: (response) ->
      if response and @parentFolder
        previewUrl = @parentFolder.previewUrl()
        _.each response, (file) ->
          file.rce_preview_url = if previewUrl
            previewUrl.replace('{{id}}', file.id.toString())
          else
            file.url
      super

    # TODO: This is duplicate code from Folder.coffee, can we DRY?
    setQueryStringParams: ->
      newParams =
        include: ['user']
        per_page: 20
        sort: @get('sort')
        order: @get('order')

      return if @loadedAll
      url = new URL(@url)
      params = deparam(url.search)
      url.search = $.param _.extend(params, newParams)
      @url = url.toString()
      @reset()



