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
import React, { useRef } from 'react';
import { arrayOf, bool, func, objectOf, oneOf, shape, string } from 'prop-types';
import { mediaObjectShape } from "../../shared/fileShape.js";
import formatMessage from "../../../../format-message.js";
import { Text } from '@instructure/ui-text';
import { View } from '@instructure/ui-view';
import Link from "../../instructure_documents/components/Link.js";
import { LoadMoreButton, LoadingIndicator, LoadingStatus, useIncrementalLoading } from "../../../../common/incremental-loading/index.js";

function hasFiles(media) {
  return media.files.length > 0;
}

function isEmpty(media) {
  return !hasFiles(media) && !media.hasMore && !media.isLoading;
}

function renderLinks(files, handleClick, lastItemRef) {
  return files.map((f, index) => {
    let focusRef = null;

    if (index === files.length - 1) {
      focusRef = lastItemRef;
    }

    return /*#__PURE__*/React.createElement(Link, Object.assign({
      key: f.id
    }, f, {
      onClick: handleClick,
      focusRef: focusRef
    }));
  });
}

function renderLoadingError() {
  return /*#__PURE__*/React.createElement(View, {
    as: "div",
    role: "alert",
    margin: "medium"
  }, /*#__PURE__*/React.createElement(Text, {
    color: "danger"
  }, formatMessage('Loading failed.')));
}

export default function MediaPanel(props) {
  const fetchInitialMedia = props.fetchInitialMedia,
        fetchNextMedia = props.fetchNextMedia,
        contextType = props.contextType,
        sortBy = props.sortBy,
        searchString = props.searchString;
  const media = props.media[contextType];
  const hasMore = media.hasMore,
        isLoading = media.isLoading,
        error = media.error,
        files = media.files;
  const lastItemRef = useRef(null);
  const loader = useIncrementalLoading({
    hasMore,
    isLoading,
    lastItemRef,
    onLoadInitial: fetchInitialMedia,
    onLoadMore: fetchNextMedia,
    records: files,
    contextType,
    sortBy,
    searchString
  });
  return /*#__PURE__*/React.createElement(View, {
    as: "div",
    "data-testid": "instructure_links-MediaPanel"
  }, renderLinks(files, file => {
    props.onMediaEmbed(file);
  }, lastItemRef), loader.isLoading && /*#__PURE__*/React.createElement(LoadingIndicator, {
    loader: loader
  }), !loader.isLoading && loader.hasMore && /*#__PURE__*/React.createElement(LoadMoreButton, {
    loader: loader
  }), /*#__PURE__*/React.createElement(LoadingStatus, {
    loader: loader
  }), error && renderLoadingError(error), isEmpty(media) && /*#__PURE__*/React.createElement(View, {
    as: "div",
    padding: "medium"
  }, formatMessage('No results.')));
}
MediaPanel.propTypes = {
  contextType: string.isRequired,
  fetchInitialMedia: func.isRequired,
  fetchNextMedia: func.isRequired,
  onMediaEmbed: func.isRequired,
  media: objectOf(shape({
    files: arrayOf(shape(mediaObjectShape)).isRequired,
    bookmark: string,
    hasMore: bool,
    isLoading: bool,
    error: string
  })).isRequired,
  sortBy: shape({
    sort: oneOf(['date_added', 'alphabetical']).isRequired,
    order: oneOf(['asc', 'desc']).isRequired
  }),
  searchString: string
};