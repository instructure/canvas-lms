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
import { fileShape } from "../../shared/fileShape.js";
import { Flex } from '@instructure/ui-flex';
import { View } from '@instructure/ui-view';
import { Text } from '@instructure/ui-text';
import { LoadMoreButton, LoadingIndicator, LoadingStatus, useIncrementalLoading } from "../../../../common/incremental-loading/index.js";
import ImageList from "../ImageList/index.js";
import formatMessage from "../../../../format-message.js";
export default function Images(props) {
  const fetchInitialImages = props.fetchInitialImages,
        fetchNextImages = props.fetchNextImages,
        contextType = props.contextType,
        sortBy = props.sortBy,
        searchString = props.searchString;
  const images = props.images[contextType];
  const hasMore = images.hasMore,
        isLoading = images.isLoading,
        error = images.error,
        files = images.files;
  const lastItemRef = useRef(null);
  const loader = useIncrementalLoading({
    hasMore,
    isLoading,
    lastItemRef,
    onLoadInitial: fetchInitialImages,
    onLoadMore: fetchNextImages,
    records: files,
    contextType,
    sortBy,
    searchString
  });
  return /*#__PURE__*/React.createElement(View, {
    as: "div",
    "data-testid": "instructure_links-ImagesPanel"
  }, /*#__PURE__*/React.createElement(Flex, {
    alignItems: "center",
    direction: "column",
    justifyItems: "space-between",
    height: "100%"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    overflowY: "visible",
    width: "100%"
  }, /*#__PURE__*/React.createElement(ImageList, {
    images: files,
    lastItemRef: lastItemRef,
    onImageClick: props.onImageEmbed
  })), loader.isLoading && /*#__PURE__*/React.createElement(Flex.Item, {
    as: "div",
    grow: true
  }, /*#__PURE__*/React.createElement(LoadingIndicator, {
    loader: loader
  })), !loader.isLoading && loader.hasMore && /*#__PURE__*/React.createElement(Flex.Item, {
    as: "div",
    margin: "small"
  }, /*#__PURE__*/React.createElement(LoadMoreButton, {
    loader: loader
  }))), /*#__PURE__*/React.createElement(LoadingStatus, {
    loader: loader
  }), error && /*#__PURE__*/React.createElement(View, {
    as: "div",
    role: "alert",
    margin: "medium"
  }, /*#__PURE__*/React.createElement(Text, {
    color: "danger"
  }, formatMessage('Loading failed.'))));
}
Images.propTypes = {
  fetchInitialImages: func.isRequired,
  fetchNextImages: func.isRequired,
  contextType: string.isRequired,
  images: objectOf(shape({
    files: arrayOf(shape(fileShape)).isRequired,
    bookmark: string,
    hasMore: bool.isRequired,
    isLoading: bool.isRequired,
    error: string
  })).isRequired,
  sortBy: shape({
    sort: oneOf(['date_added', 'alphabetical']).isRequired,
    order: oneOf(['asc', 'desc']).isRequired
  }),
  searchString: string,
  onImageEmbed: func.isRequired
};