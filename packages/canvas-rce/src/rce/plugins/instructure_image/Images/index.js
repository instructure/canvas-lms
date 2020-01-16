/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {useRef} from 'react'
import {arrayOf, bool, func, objectOf, oneOf, shape, string} from 'prop-types'
import {fileShape} from '../../shared/fileShape'
import {Flex, View} from '@instructure/ui-layout'
import {Text} from '@instructure/ui-elements'

import {
  LoadMoreButton,
  LoadingIndicator,
  LoadingStatus,
  useIncrementalLoading
} from '../../../../common/incremental-loading'
import ImageList from '../ImageList'
import formatMessage from '../../../../format-message'

export default function Images(props) {
  const {fetchInitialImages, fetchNextImages, contextType, sortBy} = props
  const images = props.images[contextType]
  const {hasMore, isLoading, error, files} = images
  const lastItemRef = useRef(null)

  const loader = useIncrementalLoading({
    hasMore,
    isLoading,
    lastItemRef,
    onLoadInitial: fetchInitialImages,
    onLoadMore: fetchNextImages,
    records: files,
    contextType,
    sortBy
  })

  return (
    <View as="div" data-testid="instructure_links-ImagesPanel">
      <Flex alignItems="center" direction="column" justifyItems="space-between" height="100%">
        <Flex.Item overflowY="visible" width="100%">
          <ImageList images={files} lastItemRef={lastItemRef} onImageClick={props.onImageEmbed} />
        </Flex.Item>

        {loader.isLoading && (
          <Flex.Item as="div" grow>
            <LoadingIndicator loader={loader} />
          </Flex.Item>
        )}

        {!loader.isLoading && loader.hasMore && (
          <Flex.Item as="div" margin="small">
            <LoadMoreButton loader={loader} />
          </Flex.Item>
        )}
      </Flex>

      <LoadingStatus loader={loader} />

      {error && (
        <View as="div" role="alert" margin="medium">
          <Text color="error">{formatMessage('Loading failed.')}</Text>
        </View>
      )}
    </View>
  )
}

Images.propTypes = {
  fetchInitialImages: func.isRequired,
  fetchNextImages: func.isRequired,
  contextType: string.isRequired,
  images: objectOf(
    shape({
      files: arrayOf(shape(fileShape)).isRequired,
      bookmark: string,
      hasMore: bool.isRequired,
      isLoading: bool.isRequired,
      error: string
    })
  ).isRequired,
  sortBy: shape({
    sort: oneOf(['date_added', 'alphabetical']).isRequired,
    order: oneOf(['asc', 'desc']).isRequired
  }),
  onImageEmbed: func.isRequired
}
