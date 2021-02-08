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
import PropTypes from 'prop-types'
import qs from 'qs'
import I18n from 'i18n!image_search'
import ImageSearchActions from './actions/ImageSearchActions'
import ImageSearchStore from './stores/ImageSearchStore'
import ImageSearchItem from './ImageSearchItem'
import SVGWrapper from './SVGWrapper'
import {Text} from '@instructure/ui-elements'
import {Spinner} from '@instructure/ui-spinner'
import {TextInput} from '@instructure/ui-text-input'
import {Button} from '@instructure/ui-buttons'
import {IconSearchLine, IconArrowOpenEndLine, IconArrowOpenStartLine} from '@instructure/ui-icons'
import {View, Flex} from '@instructure/ui-layout'
import {Alert} from '@instructure/ui-alerts'
import {ScreenReaderContent} from '@instructure/ui-a11y'

const unsplashParams = {
  w: 262,
  h: 146,
  crop: 'faces,entropy',
  fit: 'crop',
  fm: 'jpg',
  cs: 'tinysrgb',
  q: 80
}

export default class ImageSearch extends React.Component {
  static propTypes = {
    selectImage: PropTypes.func
  }

  state = ImageSearchStore.getState()

  componentWillMount() {
    this.unsubscribe = ImageSearchStore.subscribe(() => this.handleChange())
  }

  componentWillUnmount() {
    this.unsubscribe()
  }

  componentDidUpdate() {
    let toFocus
    if (this.state.pageDirection === 'prev') {
      toFocus =
        this._imageSearchControlPrev || this._imageSearchControlNext || this._imageSearchInput
    } else if (this.state.pageDirection === 'next') {
      toFocus =
        this._imageSearchControlNext || this._imageSearchControlPrev || this._imageSearchInput
    }
    if (toFocus) {
      setTimeout(() => {
        toFocus.focus()
      }, 0)
    }
  }

  handleChange() {
    this.setState(ImageSearchStore.getState())
  }

  handleInput = event => {
    event.preventDefault()

    if (event.target.value === '') {
      this.clearResults()
    } else {
      this.search(event.target.value)
    }
  }

  search(value) {
    ImageSearchStore.dispatch(ImageSearchActions.search(value))
  }

  clearResults() {
    ImageSearchStore.dispatch(ImageSearchActions.clearImageSearch())
  }

  loadNextPage = () => {
    ImageSearchStore.dispatch(ImageSearchActions.loadMore(this.state.nextUrl, 'next'))
  }

  loadPreviousPage = () => {
    ImageSearchStore.dispatch(ImageSearchActions.loadMore(this.state.prevUrl, 'prev'))
  }

  renderAlert() {
    if (!this.state.alert) return null
    const alert = (
      <Alert
        screenReaderOnly
        liveRegion={() => document.getElementById('flash_screenreader_holder')}
      >
        {I18n.t('%{count} images found for %{term}', {
          count: this.state.searchResults.length,
          term: this.state.searchTerm
        })}
      </Alert>
    )
    return alert
  }

  renderResults() {
    if (this.state.searching) {
      return (
        <div className="ImageSearch__loading">
          <Spinner renderTitle="Loading" />
        </div>
      )
    } else if (!this.state.searching && this.state.searchResults.length) {
      return (
        <div className="ImageSearch__images">
          {this.state.searchResults.map(photo => {
            const photo_url =
              photo.raw_url +
              (photo.raw_url.includes('?') ? '&' : '?') +
              qs.stringify(unsplashParams)
            return (
              <ImageSearchItem
                key={photo.id}
                confirmationId={photo.id}
                src={photo_url}
                description={photo.alt || photo.description || this.state.searchTerm}
                selectImage={this.props.selectImage}
                userUrl={photo.user_url}
                userName={photo.user}
              />
            )
          })}
        </div>
      )
    } else if (
      !this.state.searching &&
      this.state.searchTerm &&
      !this.state.searchResults.length &&
      this.state.alert
    ) {
      return (
        <div className="ImageSearch__images">
          <Text>
            {I18n.t('No results found for %{searchTerm}', {searchTerm: this.state.searchTerm})}
          </Text>
        </div>
      )
    }
  }

  renderPagination(photos) {
    if (!photos || photos.length === 0) {
      return null
    }

    return (
      <Flex as="div" width="100%" justifyItems="space-between" margin="small 0 small">
        <Flex.Item>
          {this.state.prevUrl && (
            <Button
              variant="link"
              buttonRef={e => (this._imageSearchControlPrev = e)}
              onClick={this.loadPreviousPage}
              icon={IconArrowOpenStartLine}
            >
              {I18n.t('Previous Page')}
            </Button>
          )}
        </Flex.Item>
        <Flex.Item>
          {this.state.nextUrl && (
            <Button
              variant="link"
              buttonRef={e => (this._imageSearchControlNext = e)}
              onClick={this.loadNextPage}
              iconPlacement="end"
            >
              {I18n.t('Next Page')}
              <View padding="0 0 0 x-small">
                <IconArrowOpenEndLine />
              </View>
            </Button>
          )}
        </Flex.Item>
      </Flex>
    )
  }

  render() {
    return (
      <div>
        {this.renderAlert()}
        <View as="div" className="Unsplash__logo" textAlign="start" margin="medium 0 small">
          <SVGWrapper url="/images/unsplash_logo.svg" />
        </View>
        <View as="div" margin="small 0 small">
          <TextInput
            inputRef={e => (this._imageSearchInput = e)}
            placeholder={I18n.t('Search')}
            renderLabel={<ScreenReaderContent>{I18n.t('Search')}</ScreenReaderContent>}
            value={this.state.searchTerm}
            type="search"
            layout="inline"
            onChange={this.handleInput}
            renderAfterInput={<IconSearchLine />}
          />
        </View>
        {this.renderResults()}
        {this.renderPagination(this.state.searchResults)}
      </div>
    )
  }
}
