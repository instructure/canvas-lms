/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import I18n from 'i18n!flickr_search'
import FlickrActions from './actions/FlickrActions'
import FlickrStore from './stores/FlickrStore'
import FlickrImage from './FlickrImage'
import SVGWrapper from './SVGWrapper'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import Text from '@instructure/ui-elements/lib/components/Text'

export default class FlickrSearch extends React.Component {
  state = FlickrStore.getState()

  componentWillMount() {
    this.unsubscribe = FlickrStore.subscribe(() => this.handleChange())
  }

  componentWillUnmount() {
    this.unsubscribe()
  }

  handleChange() {
    this.setState(FlickrStore.getState())
  }

  handleInput = event => {
    event.preventDefault()
    const value = event.target.value

    if (value === '') {
      this.clearFlickrResults()
    } else {
      this.searchFlickr(value, 1)
    }
  }

  searchFlickr(value, page) {
    FlickrStore.dispatch(FlickrActions.searchFlickr(value, page))
  }

  clearFlickrResults() {
    FlickrStore.dispatch(FlickrActions.clearFlickrSearch())
  }

  incrementPageCount = () => {
    this.searchFlickr(this.state.searchTerm, this.state.page + 1)
  }

  decrementPageCount = () => {
    this.searchFlickr(this.state.searchTerm, this.state.page - 1)
  }

  render() {
    const photos = this.state.searchResults.photos
    const safetyMessage = I18n.t(`Flickr displays SafeSearch images within the Creative Commons Public Domain.
              However, safe search results are not guaranteed, as some images may not include a
              specified safety level by their owners.`)

    return (
      <div>
        <div className="FlickrSearch__logo">
          <SVGWrapper url="/images/flickr_logo.svg" />
        </div>
        <Text color="secondary">{safetyMessage}</Text>
        <div className="ic-Input-group">
          <div
            className="ic-Input-group__add-on"
            role="presentation"
            aria-hidden="true"
            tabIndex="-1"
          >
            <i className="icon-search" />
          </div>
          <input
            className="ic-Input"
            placeholder={I18n.t('Search flickr')}
            aria-label="Search widgets"
            value={this.state.searchTerm}
            type="search"
            onChange={this.handleInput}
          />
        </div>

        {!this.state.searching ? (
          <div className="FlickrSearch__images">
            {photos &&
              photos.photo.map(photo => (
                <FlickrImage
                  key={photo.id}
                  url={photo.url_m}
                  searchTerm={this.state.searchTerm}
                  selectImage={this.props.selectImage}
                />
              ))}
          </div>
        ) : (
          <div className="FlickrSearch__loading">
            <Spinner title="Loading" />
          </div>
        )}

        {photos && (
          <span className="FlickrSearch__pageNavigation">
            {this.state.page > 1 &&
              !this.state.searching && (
                <a
                  className="FlickrSearch__control"
                  ref="flickrSearchControlPrev"
                  href="#"
                  onClick={this.decrementPageCount}
                >
                  <i className="icon-arrow-open-left" /> {I18n.t('Previous')}
                </a>
              )}
            {this.state.page < photos.pages &&
              !this.state.searching && (
                <a
                  className="FlickrSearch__control"
                  ref="flickrSearchControlNext"
                  href="#"
                  onClick={this.incrementPageCount}
                >
                  {I18n.t('Next')} <i className="icon-arrow-open-right" />
                </a>
              )}
          </span>
        )}
      </div>
    )
  }
}
