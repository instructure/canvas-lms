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

import React, {useEffect, useRef} from 'react'
import {arrayOf, bool, func, shape} from 'prop-types'
import {Flex, FlexItem} from '@instructure/ui-layout'
import {Spinner} from '@instructure/ui-elements'

import formatMessage from '../../../../format-message'
import LoadMoreButton from '../../../../common/components/LoadMoreButton'
import Image from '../ImageList/Image'
import ImageList from '../ImageList'

export default function Images(props) {
  const {hasMore, isLoading, records} = props.images
  const lastItemRef = useRef(null)
  const loadMoreButtonRef = useRef(null)

  useEffect(() => {
    // Load images only upon mounting.
    props.fetchImages({calledFromRender: true})
  }, [])

  useEffect(() => {
    /*
     * When `isLoading` changes to false, a page of results has just completed.
     * When `lastTimeRef.current` is present, there is at least one result in
     * the list of results. When the user has just clicked the "Load more
     * results" button and has not changed focus from that button, focus should
     * move to the last result in the list.
     */
    if (!isLoading && lastItemRef.current && loadMoreButtonRef.current === document.activeElement) {
      lastItemRef.current.focus()
    }
  }, [isLoading])

  const showLoadingIndicator = records.length === 0 && isLoading
  const showLoadMoreButton = records.length > 0 && hasMore

  return (
    <Flex alignItems="center" direction="column" justifyItems="space-between" height="100%">
      {showLoadingIndicator && (
        <FlexItem display="block" padding="medium">
          <Spinner title={formatMessage('Loading...')} />
        </FlexItem>
      )}

      <FlexItem overflowY="visible" width="100%">
        <ImageList
          images={records}
          lastItemRef={lastItemRef}
          onImageClick={props.onImageEmbed}
        />
      </FlexItem>

      {showLoadMoreButton && (
        <FlexItem display="block" padding="x-small medium medium medium">
          <LoadMoreButton
            buttonRef={loadMoreButtonRef}
            isLoading={isLoading}
            onLoadMore={props.fetchImages}
          />
        </FlexItem>
      )}
    </Flex>
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
