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
], (PaginatedCollection, _) ->

  class FilesCollection extends PaginatedCollection
    @optionProperty 'parentFolder'

    fetch: (options = {}) ->
      options.data = _.extend content_types: @parentFolder.contentTypes, options.data || {}
      super options

    parse: (response) ->
      if response
        previewUrl = @parentFolder.previewUrl()
        _.each response, (file) ->
          file.preview_url = if previewUrl
            previewUrl.replace('{{id}}', file.id.toString())
          else
            file.url
      super
