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
import I18n from 'i18n!image_search'
import ImageSearchActions from './actions/ImageSearchActions'
import ImageSearchStore from './stores/ImageSearchStore'
import ImageSearchItem from './ImageSearchItem'
import SVGWrapper from './SVGWrapper'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import { TextInput } from '@instructure/ui-text-input'
import { IconSearchLine, IconArrowOpenEndLine, IconArrowOpenStartLine } from '@instructure/ui-icons'
import { Link } from '@instructure/ui-elements'
import { View, Flex, FlexItem } from '@instructure/ui-layout'

export default class ImageSearch extends React.Component {
  state = ImageSearchStore.getState()

  componentWillMount() {
    this.unsubscribe = ImageSearchStore.subscribe(() => this.handleChange())
  }

  componentWillUnmount() {
    this.unsubscribe()
  }

  handleChange() {
    this.setState(ImageSearchStore.getState())
  }

  handleInput = (event) => {
    event.preventDefault()

    if (event.target.value === '') {
      this.clearResults()
    } else {
      this.search(event.target.value, 1)
    }
  }

  search(value, page) {
    ImageSearchStore.dispatch(ImageSearchActions.search(value, page))
  }

  clearResults() {
    ImageSearchStore.dispatch(ImageSearchActions.clearImageSearch())
  }

  incrementPageCount = () => {
    this.search(this.state.searchTerm, this.state.page + 1)
  }

  decrementPageCount = () => {
    this.search(this.state.searchTerm, this.state.page - 1)
  }

  renderPagination(photos) {
    if (!photos) {
      return null
    }
    const showPrevious = this.state.page > 1 && !this.state.searching
    const showNext = this.state.page < photos.pages && !this.state.searching

    return (
      <Flex as="div" width="100%" justifyItems="center" margin="small 0 small">
        {showPrevious && (
          <FlexItem margin="auto small auto small">
            <Link
              ref="imageSearchControlPrev"
              onClick={this.decrementPageCount}
              icon={IconArrowOpenStartLine}
            >
              {I18n.t('Previous Page')}
            </Link>
          </FlexItem>
        )}
        {showNext && (
          <FlexItem>
            <Link
              ref="imageSearchControlNext"
              onClick={this.incrementPageCount}
              icon={IconArrowOpenEndLine}
              iconPlacement="end"
            >
              {I18n.t('Next Page')}
            </Link>
          </FlexItem>
        )}
      </Flex>
    )
  }

  render() {
    const photos = this.state.searchResults.photos

    return (
      <div>
        <View as="div" className="Unsplash__logo" textAlign="start" margin="medium 0 small">
          <SVGWrapper url="/images/unsplash_logo.svg" />
        </View>
        <View as="div" margin="small 0 small">
          <TextInput
            placeholder={I18n.t('Search')}
            aria-label="Search"
            value={this.state.searchTerm}
            type="search"
            layout="inline"
            onChange={this.handleInput}
            renderAfterInput={<IconSearchLine />}
          />
        </View>

        {this.renderPagination(photos)}
        {!this.state.searching ? (
          <div className="FlickrSearch__images">
            {photos &&
              photos.photo.map(photo => (
                <ImageSearchItem
                  key={photo.id}
                  src={photo.url_m}
                  description={this.state.searchTerm}
                  selectImage={this.props.selectImage}
                />
              ))}
          </div>
        ) : (
          <div className="ImageSearch__loading">
            <Spinner title="Loading" />
          </div>
        )}
        {this.renderPagination(photos)}
      </div>
    )
  }
}
