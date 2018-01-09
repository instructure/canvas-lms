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
  'i18n!course_users'
  'jquery'
  '../util/mixin'
  './ValidatedMixin'
  'jquery.instructure_forms'
], (I18n, $, mixin, ValidatedMixin) ->

  mixin {}, ValidatedMixin,

    defaults:

      ##
      # Name of the parameter to add to the query string

      paramName: 'search_term'

    initialize: ->
      @collection = @collectionView.collection

    attach: ->
      @inputFilterView.on 'input', @fetchResults, this

    fetchResults: (query) ->
      if query is ''
        @collection.deleteParam @options.paramName
      # this might not be general :\
      else if query.length < 3
        return
      else
        @collection.setParam @options.paramName, query
      @lastRequest?.abort()
      @lastRequest = @collection.fetch().fail => @onFail()

    onFail: (xhr) ->
      return if xhr.statusText is 'abort'
      parsed = $.parseJSON xhr.responseText
      message = if parsed?.errors?[0].message is "3 or more characters is required"
        I18n.t('greater_than_three', 'Please enter a search term with three or more characters')
      else
        I18n.t('unknown_error', 'Something went wrong with your search, please try again.')
      @showErrors inputFilter: [{message}]

