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
import { arrayOf, bool, func, shape, string, objectOf, oneOf } from 'prop-types';
import { fileShape } from "../../shared/fileShape.js";
import formatMessage from "../../../../format-message.js";
import { Text } from '@instructure/ui-text';
import { View } from '@instructure/ui-view';
import Link from "./Link.js";
import { LoadMoreButton, LoadingIndicator, LoadingStatus, useIncrementalLoading } from "../../../../common/incremental-loading/index.js";

function hasFiles(documents) {
  return documents.files.length > 0;
}

function isEmpty(documents) {
  return !hasFiles(documents) && !documents.hasMore && !documents.isLoading;
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

export default function DocumentsPanel(props) {
  const fetchInitialDocs = props.fetchInitialDocs,
        fetchNextDocs = props.fetchNextDocs,
        contextType = props.contextType,
        sortBy = props.sortBy,
        searchString = props.searchString;
  const documents = props.documents[contextType];
  const hasMore = documents.hasMore,
        isLoading = documents.isLoading,
        error = documents.error,
        files = documents.files;
  const lastItemRef = useRef(null);
  const loader = useIncrementalLoading({
    hasMore,
    isLoading,
    lastItemRef,
    onLoadInitial: fetchInitialDocs,
    onLoadMore: fetchNextDocs,
    records: files,
    contextType,
    sortBy,
    searchString
  });
  return /*#__PURE__*/React.createElement(View, {
    as: "div",
    "data-testid": "instructure_links-DocumentsPanel"
  }, renderLinks(files, file => {
    props.onLinkClick(file);
  }, lastItemRef), loader.isLoading && /*#__PURE__*/React.createElement(LoadingIndicator, {
    loader: loader
  }), !loader.isLoading && loader.hasMore && /*#__PURE__*/React.createElement(LoadMoreButton, {
    loader: loader
  }), /*#__PURE__*/React.createElement(LoadingStatus, {
    loader: loader
  }), error && renderLoadingError(error), isEmpty(documents) && /*#__PURE__*/React.createElement(View, {
    as: "div",
    padding: "medium"
  }, formatMessage('No results.')));
}
DocumentsPanel.propTypes = {
  contextType: string.isRequired,
  fetchInitialDocs: func.isRequired,
  fetchNextDocs: func.isRequired,
  onLinkClick: func.isRequired,
  documents: objectOf(shape({
    files: arrayOf(shape(fileShape)).isRequired,
    bookmark: string,
    hasMore: bool,
    isLoading: bool,
    error: string
  })).isRequired,
  sortBy: shape({
    sort: oneOf(['date_added', 'alphabetical']).isRequired,
    order: oneOf(['asc', 'desc']).isRequired
  }).isRequired,
  searchString: string
};