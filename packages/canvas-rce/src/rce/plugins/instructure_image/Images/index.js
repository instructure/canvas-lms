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
import {arrayOf, bool, func, shape} from 'prop-types'
import {Flex} from '@instructure/ui-layout'

import {
  LoadMoreButton,
  LoadingIndicator,
  LoadingStatus,
  useIncrementalLoading
} from '../../../../common/incremental-loading'
import Image from '../ImageList/Image'
import ImageList from '../ImageList'

export default function Images(props) {
  const {fetchImages, images} = props
  const {hasMore, isLoading, records} = images
  const lastItemRef = useRef(null)

  const loader = useIncrementalLoading({
    hasMore,
    isLoading,
    lastItemRef,

    onLoadInitial() {
      fetchImages({calledFromRender: true})
    },

    onLoadMore() {
      fetchImages({calledFromRender: false})
    },

    records
  })

  return (
    <>
      <Flex alignItems="center" direction="column" justifyItems="space-between" height="100%">
        <Flex.Item overflowY="visible" width="100%">
          <ImageList images={records} lastItemRef={lastItemRef} onImageClick={props.onImageEmbed} />
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
    </>
  )
}

Images.propTypes = {
  fetchImages: func.isRequired,
  images: shape({
    hasMore: bool.isRequired,
    isLoading: bool.isRequired,
    records: arrayOf(Image.propTypes.image).isRequired
  }),
  onImageEmbed: func.isRequired
}
