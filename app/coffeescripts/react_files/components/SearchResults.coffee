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
  'i18n!react_files'
  'react',
  '../../collections/FilesCollection'
  '../modules/customPropTypes'
  '../utils/updateAPIQuerySortParams'
  '../utils/getAllPages'
  'location-origin'
], (_, I18n, React, FilesCollection, customPropTypes, updateAPIQuerySortParams, getAllPages) ->

  SearchResults =
    displayName: 'SearchResults'

    propTypes:
      contextType: customPropTypes.contextType
      contextId: customPropTypes.contextId

    name: 'search'

    getInitialState: ->
      return {
        collection: new FilesCollection
        errors: null
      }

    onFetchError: (jqXHR, textStatus, errorThrown) ->
      message = I18n.t('An unknown server error occurred.  Please try again.')

      try
        responseText = JSON.parse(textStatus.responseText)
      catch e
        responseText =
          errors: [{message}]

      errors = if _.isArray(responseText.errors)
                 @translateErrors(responseText.errors)
               else if responseText.errors?.base?
                 [{message: "#{responseText.errors.base}, #{responseText.status}"}]
               else
                 [{message}]
      @setState errors: errors
      $.screenReaderFlashMessageExclusive (_.map errors, (error) -> error.message).join ' '

    translateErrors: (errors) ->
      _.map errors, (error) ->
        if error.message is "3 or more characters is required"
          { message: I18n.t('Please enter a search term with three or more characters') }
        else
          error

    updateResults: (props) ->
      oldUrl = @state.collection.url
      @state.collection.url = "#{window.location.origin}/api/v1/#{@props.contextType}/#{@props.contextId}/files"
      updateAPIQuerySortParams(@state.collection, @props.query)

      return if @state.collection.url is oldUrl and @state.collection.models.length > 0 # doesn't search for the same thing twice
      @setState({collection: @state.collection})

      # Refactor this when given time. Maybe even use setState instead of forceUpdate
      unless @state.collection.loadedAll and _.isEqual(@props.query.search_term, props.query?.search_term?)
        forceUpdate = =>
          if @isMounted()
            @setState({errors: null})
            @forceUpdate()
          $.screenReaderFlashMessageExclusive I18n.t('results_count', "Showing %{num_results} search results", {num_results: @state.collection.length})
        @state.collection.fetch({data: props.query, error: @onFetchError}).then(forceUpdate)
          # TODO: use scroll position to only fetch the pages we need
          .then getAllPages.bind(null, @state.collection, forceUpdate)

    componentWillReceiveProps: (newProps) ->
      @updateResults(newProps)

    componentDidMount: ->
      @updateResults(@props)

      # this setTimeout is to handle a race condition with the setTimeout in the componentWillUnmount method of ShowFolder
      setTimeout =>
        @props.onResolvePath({currentFolder: null, rootTillCurrentFolder: null, showingSearchResults: true, searchResultCollection: @state.collection})
