/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import _ from 'underscore'
import I18n from 'i18n!react_files'
import FilesCollection from '../../collections/FilesCollection'
import customPropTypes from '../modules/customPropTypes'
import updateAPIQuerySortParams from '../utils/updateAPIQuerySortParams'
import getAllPages from '../utils/getAllPages'
import 'location-origin'

export default {
  displayName: 'SearchResults',

  propTypes: {
    contextType: customPropTypes.contextType,
    contextId: customPropTypes.contextId
  },

  name: 'search',

  getInitialState() {
    return {
      collection: new FilesCollection(),
      errors: null
    }
  },

  onFetchError(jqXHR, textStatus, errorThrown) {
    let responseText
    const message = I18n.t('An unknown server error occurred.  Please try again.')

    try {
      responseText = JSON.parse(textStatus.responseText)
    } catch (e) {
      responseText = {errors: [{message}]}
    }

    const errors = _.isArray(responseText.errors)
      ? this.translateErrors(responseText.errors)
      : responseText.errors && responseText.errors.base
        ? [{message: `${responseText.errors.base}, ${responseText.status}`}]
        : [{message}]

    this.setState({errors})
    $.screenReaderFlashMessageExclusive(_.map(errors, error => error.message).join(' '))
  },

  translateErrors(errors) {
    return _.map(errors, function(error) {
      if (error.message === '3 or more characters is required') {
        return {message: I18n.t('Please enter a search term with three or more characters')}
      } else {
        return error
      }
    })
  },

  updateResults(props) {
    const oldUrl = this.state.collection.url
    this.state.collection.url = `${window.location.origin}/api/v1/${this.props.contextType}/${
      this.props.contextId
    }/files`
    updateAPIQuerySortParams(this.state.collection, this.props.query)

    if (this.state.collection.url === oldUrl && this.state.collection.models.length > 0) {
      return
    } // doesn't search for the same thing twice
    this.setState({collection: this.state.collection})

    // Refactor this when given time. Maybe even use setState instead of forceUpdate
    if (
      !this.state.collection.loadedAll ||
      !_.isEqual(this.props.query.search_term, props.query && props.query.search_term)
    ) {
      const forceUpdate = () => {
        if (this.isMounted()) {
          this.setState({errors: null})
          this.forceUpdate()
        }
        $.screenReaderFlashMessageExclusive(
          I18n.t('results_count', 'Showing %{num_results} search results', {
            num_results: this.state.collection.length
          })
        )
      }
      return (
        this.state.collection
          .fetch({data: props.query, error: this.onFetchError})
          .then(forceUpdate)
          // TODO: use scroll position to only fetch the pages we need
          .then(getAllPages.bind(null, this.state.collection, forceUpdate))
      )
    }
  },

  componentWillReceiveProps(newProps) {
    return this.updateResults(newProps)
  },

  componentDidMount() {
    this.updateResults(this.props)

    // this setTimeout is to handle a race condition with the setTimeout in the componentWillUnmount method of ShowFolder
    setTimeout(() => {
      this.props.onResolvePath({
        currentFolder: null,
        rootTillCurrentFolder: null,
        showingSearchResults: true,
        searchResultCollection: this.state.collection
      })
    })
  }
}
