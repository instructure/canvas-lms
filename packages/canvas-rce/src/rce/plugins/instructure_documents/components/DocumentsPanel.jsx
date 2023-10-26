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
import {func, shape, string, oneOf} from 'prop-types'
import {contentTrayDocumentShape} from '../../shared/fileShape'
import formatMessage from '../../../../format-message'

import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import Link from './Link'
import {
  LoadMoreButton,
  LoadingIndicator,
  LoadingStatus,
  useIncrementalLoading,
} from '../../../../common/incremental-loading'

function hasFiles(documents) {
  return documents.files.length > 0
}

function isEmpty(documents) {
  return !hasFiles(documents) && !documents.hasMore && !documents.isLoading
}

function renderLinks(files, handleClick, lastItemRef) {
  return files.map((f, index) => {
    let focusRef = null
    if (index === files.length - 1) {
      focusRef = lastItemRef
    }
    return <Link key={f.id} {...f} onClick={handleClick} focusRef={focusRef} />
  })
}

function renderLoadingError(_error) {
  return (
    <View as="div" role="alert" margin="medium">
      <Text color="danger">{formatMessage('Loading failed.')}</Text>
    </View>
  )
}

export default function DocumentsPanel(props) {
  const {fetchInitialDocs, fetchNextDocs, contextType, sortBy, searchString} = props
  const documents = props.documents[contextType]
  const {hasMore, isLoading, error, files} = documents
  const lastItemRef = useRef(null)

  const loader = useIncrementalLoading({
    hasMore,
    isLoading,
    lastItemRef,
    onLoadInitial: fetchInitialDocs,
    onLoadMore: fetchNextDocs,
    records: files,
    contextType,
    sortBy,
    searchString,
  })

  const handleDocClick = file => {
    props.onLinkClick(file)
  }

  return (
    <View as="div" data-testid="instructure_links-DocumentsPanel">
      {renderLinks(files, handleDocClick, lastItemRef)}

      {loader.isLoading && <LoadingIndicator loader={loader} />}

      {!loader.isLoading && loader.hasMore && <LoadMoreButton loader={loader} />}

      <LoadingStatus loader={loader} />

      {error && renderLoadingError(error)}

      {isEmpty(documents) && (
        <View as="div" role="alert" padding="medium">
          {formatMessage('No results.')}
        </View>
      )}
    </View>
  )
}

DocumentsPanel.propTypes = {
  contextType: string.isRequired,
  fetchInitialDocs: func.isRequired,
  fetchNextDocs: func.isRequired,
  onLinkClick: func.isRequired,
  documents: contentTrayDocumentShape.isRequired,
  sortBy: shape({
    sort: oneOf(['date_added', 'alphabetical']).isRequired,
    order: oneOf(['asc', 'desc']).isRequired,
  }).isRequired,
  searchString: string,
}
