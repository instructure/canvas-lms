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

define [
  'underscore'
  'jquery'
  '../../util/deparam'
], (_, {param}, deparam) ->

  # if you change which column to order by or wheather to to sort asc or desc,
  # use this to change the api url of the collection
  updateAPIQuerySortParams = (collection, queryParams) ->
    newParams =
      include: ['user', 'usage_rights', 'enhanced_preview_url', 'context_asset_string']
      per_page: 20
      sort: queryParams.sort || ''
      order: queryParams.order || ''

    oldUrl = collection.url
    [baseUrl, search] = oldUrl.split('?')
    params = _.extend(deparam(search), newParams)
    newUrl = baseUrl + '?' + param(params)
    collection.url = newUrl
    collection.reset() if newUrl isnt oldUrl and !collection.loadedAll