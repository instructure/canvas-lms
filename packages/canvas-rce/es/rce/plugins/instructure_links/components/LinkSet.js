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
import React, { Component, useRef } from 'react';
import { bool, func, string } from 'prop-types';
import { linksShape, linkType } from "./propTypes.js";
import formatMessage from "../../../../format-message.js";
import { ScreenReaderContent } from '@instructure/ui-a11y-content';
import { List } from '@instructure/ui-list';
import { View } from '@instructure/ui-view';
import uid from '@instructure/uid';
import { LoadMoreButton, LoadingIndicator, LoadingStatus, useIncrementalLoading } from "../../../../common/incremental-loading/index.js";
import Link from "./Link.js";
/*
 * This is needed only as long as `LinkSet` is a class component.
 */

function IncrementalLoader(props) {
  const children = props.children,
        collection = props.collection,
        fetchInitialPage = props.fetchInitialPage,
        fetchNextPage = props.fetchNextPage,
        contextType = props.contextType,
        searchString = props.searchString;
  const hasMore = collection.hasMore,
        isLoading = collection.isLoading,
        links = collection.links;
  const lastItemRef = useRef(null);
  const loader = useIncrementalLoading({
    hasMore: hasMore && fetchNextPage != null,
    isLoading,
    lastItemRef,
    contextType,
    sortBy: {
      sort: 'alphabetical',
      order: 'asc'
    },
    // not actually used in the query, but a required param
    searchString,

    onLoadInitial() {
      if (fetchInitialPage) {
        fetchInitialPage();
      }
    },

    onLoadMore() {
      fetchNextPage();
    },

    records: links
  });
  return children({
    loader,
    lastItemRef
  });
}

class LinkSet extends Component {
  constructor(props) {
    super(props);
    this.describedByID = `rce-LinkSet-describedBy-${uid()}`;
    this.loadMoreButtonRef = null;
  }

  hasLinks(props) {
    return props.collection.links.length > 0;
  }

  isEmpty(props) {
    return !this.hasLinks(props) && !props.collection.hasMore && !props.collection.isLoading;
  }

  renderLinks(lastItemRef) {
    function refFor(index, array) {
      if (!lastItemRef || index !== array.length - 1) {
        return null;
      } // Return a compatible callback ref for InstUI


      return ref => {
        lastItemRef.current = ref;
      };
    }

    return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(ScreenReaderContent, {
      id: this.describedByID
    }, formatMessage('Click to insert a link into the editor.')), /*#__PURE__*/React.createElement(List, {
      variant: "unstyled",
      as: "ul",
      margin: "0"
    }, this.props.collection.links.map((link, index, array) => /*#__PURE__*/React.createElement(List.Item, {
      key: link.href,
      spacing: "none",
      padding: "0"
    }, /*#__PURE__*/React.createElement(Link, {
      link: link,
      type: this.props.type,
      onClick: this.props.onLinkClick,
      describedByID: this.describedByID,
      elementRef: refFor(index, array)
    })))));
  }

  renderEmptyIndicator() {
    return /*#__PURE__*/React.createElement(View, {
      as: "div",
      padding: "medium"
    }, formatMessage('No results.'));
  }

  renderLoadingError() {
    if (this.props.collection.lastError) {
      return /*#__PURE__*/React.createElement("span", {
        className: "rcs-LinkSet-LoadFailed",
        role: "alert"
      }, formatMessage('Loading failed...'));
    }

    return null;
  }

  render() {
    return /*#__PURE__*/React.createElement(IncrementalLoader, this.props, ({
      loader,
      lastItemRef
    }) => /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
      "data-testid": "instructure_links-LinkSet"
    }, this.hasLinks(this.props) && this.renderLinks(lastItemRef), this.renderLoadingError(), loader.isLoading && /*#__PURE__*/React.createElement(LoadingIndicator, {
      loader: loader
    }), !loader.isLoading && loader.hasMore && /*#__PURE__*/React.createElement(LoadMoreButton, {
      loader: loader
    }), this.isEmpty(this.props) && !this.props.suppressRenderEmpty && this.renderEmptyIndicator()), /*#__PURE__*/React.createElement(LoadingStatus, {
      loader: loader
    })));
  }

}

LinkSet.propTypes = {
  type: linkType.isRequired,
  collection: linksShape.isRequired,
  onLinkClick: func.isRequired,
  contextType: string.isRequired,
  fetchInitialPage: func,
  fetchNextPage: func,
  suppressRenderEmpty: bool,
  searchString: string
};
export default LinkSet;