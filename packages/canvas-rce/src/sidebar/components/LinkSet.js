/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React, { Component, PropTypes } from "react";
import { renderLink as renderLinkHtml } from "../../rce/contentRendering";
import dragHtml from "../dragHtml";
import formatMessage from "../../format-message";
import LoadMore from "../../common/components/LoadMore";
import ScreenReaderContent from "@instructure/ui-core/lib/components/ScreenReaderContent";
import { StyleSheet, css } from "aphrodite";

let nextId = 1;

class LinkSet extends Component {
  constructor(props) {
    super(props);
    this.handleLinkClick = this.handleLinkClick.bind(this);
    this.handleDragStart = this.handleDragStart.bind(this);
    this.handleLoadMoreClick = this.handleLoadMoreClick.bind(this);
    this.describedByID = `rce-LinkSet-describedBy-${nextId++}`;
  }

  componentWillMount() {
    if (this.props.fetchInitialPage) {
      this.props.fetchInitialPage();
    }
  }

  handleLinkClick(e, link) {
    if (this.props.onLinkClick) {
      e.preventDefault();
      this.props.onLinkClick(link);
    }
  }

  handleDragStart(ev, link) {
    dragHtml(ev, renderLinkHtml(link));
  }

  handleLoadMoreClick(e) {
    e.preventDefault();
    if (this.props.fetchNextPage) {
      this.props.fetchNextPage();
    }
  }

  hasLinks() {
    return this.props.collection.links.length > 0;
  }

  isEmpty() {
    return (
      !this.hasLinks() &&
      !this.props.collection.hasMore &&
      !this.props.collection.isLoading
    );
  }

  renderLink(link) {
    return (
      <li
        key={link.href}
        title={formatMessage("Click to insert a link to this item.")}
        className={css(styles.item)}
      >
        <a
          href={link.href}
          className={css(styles.link)}
          role="button"
          aria-describedby={this.describedByID}
          onClick={e => this.handleLinkClick(e, link)}
          onDragStart={e => this.handleDragStart(e, link)}
        >
          {link.title}
        </a>
      </li>
    );
  }

  renderLinks() {
    return (
      <div>
        <ScreenReaderContent id={this.describedByID}>
          {formatMessage("Click to insert a link into the editor.")}
        </ScreenReaderContent>
        <ul className={css(styles.list)}>
          {this.props.collection.links.map(this.renderLink, this)}
        </ul>
      </div>
    );
  }

  renderEmptyIndicator() {
    return (
      <span className="rcs-LinkSet-Empty">{formatMessage("No results.")}</span>
    );
  }

  renderLoadingError() {
    if (this.props.collection.lastError) {
      return (
        <span className="rcs-LinkSet-LoadFailed" role="alert">
          {formatMessage("Loading failed...")}
        </span>
      );
    }
    return null;
  }

  render() {
    if (this.props.fetchNextPage) {
      let hasMore = this.props.collection.hasMore || false;
      let isLoading = this.props.collection.isLoading || false;
      return (
        <div>
          <LoadMore
            hasMore={hasMore}
            isLoading={isLoading}
            loadMore={this.props.fetchNextPage}
            focusSelector="li>a"
          >
            {this.hasLinks() && this.renderLinks()}
            {this.renderLoadingError()}
          </LoadMore>
          {this.isEmpty() &&
            !(this.props.suppressRenderEmpty || false) &&
            this.renderEmptyIndicator()}
        </div>
      );
    } else {
      return (
        <div>
          {this.hasLinks() ? this.renderLinks() : this.renderEmptyIndicator()}
        </div>
      );
    }
  }
}

LinkSet.propTypes = {
  collection: PropTypes.shape({
    links: PropTypes.array.isRequired,
    isLoading: PropTypes.bool,
    hasMore: PropTypes.bool,
    lastError: PropTypes.object
  }).isRequired,
  fetchInitialPage: PropTypes.func,
  fetchNextPage: PropTypes.func,
  onLinkClick: PropTypes.func,
  suppressRenderEmpty: PropTypes.bool
};

const styles = StyleSheet.create({
  list: {
    margin: 0,
    padding: 0,
    listStyle: "none"
  },
  item: {
    margin: 0,
    padding: 0,
    display: "block",
    backgroundPosition: "left center",
    backgroundRepeat: "no-repeat",
    width: "100%",
    ":hover": {
      backgroundColor: "#eee"
    }
  },
  link: {
    display: "block",
    padding: "3px 5px",
    textAlign: "left"
  }
});

export default LinkSet;
