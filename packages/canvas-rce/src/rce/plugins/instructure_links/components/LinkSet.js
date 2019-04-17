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


import React, { Component } from "react";
import {bool, func} from "prop-types";
import {linksShape, linkType} from './propTypes'
import formatMessage from "../../../../format-message";
import LoadMoreButton from '../../../../common/components/LoadMoreButton'
import ScreenReaderContent from "@instructure/ui-a11y/lib/components/ScreenReaderContent";
import {List, ListItem, Spinner} from '@instructure/ui-elements'
import {View} from '@instructure/ui-layout'
import uid from '@instructure/uid'

import Link from './Link'

class LinkSet extends Component {
  constructor(props) {
    super(props);
    this.describedByID = `rce-LinkSet-describedBy-${uid()}`;
    this.loadMoreButtonRef = null
    this.lastLinkRef = null
    this.listRef = null
  }

  componentWillMount() {
    if (this.props.fetchInitialPage) {
      this.props.fetchInitialPage();
    }
  }

  componentDidUpdate(prevProps) {
    if (!this.props.collection.isLoading) {
      if (this.hasLinks(prevProps) && !this.hasFocus()) {
        this.lastLinkRef && this.lastLinkRef.focus()
      }
    }
  }

  handleLoadMoreClick = e => {
    e.preventDefault();
    if (this.props.fetchNextPage) {
      this.props.fetchNextPage();
    }
  }

  hasFocus() {
    return this.listRef.contains(document.activeElemnt)
  }
  hasLinks(props) {
    return props.collection.links.length > 0
  }

  isEmpty(props) {
    return (
      !this.hasLinks(props) &&
      !props.collection.hasMore &&
      !props.collection.isLoading
    );
  }

  renderLink(link, index, allLinks) {
    const linkRef = index === allLinks.length-1 ? el => this.lastLinkRef = el : null

    return (
      <ListItem key={link.href} spacing="none" padding="0">
        <Link
          link={link}
          type={this.props.type}
          onClick={this.props.onLinkClick}
          describedByID={this.describedByID}
          elementRef={linkRef}
        />
      </ListItem>
    );
  }

  renderLinks() {
    return (
      <>
        <ScreenReaderContent id={this.describedByID}>
          {formatMessage("Click to insert a link into the editor.")}
        </ScreenReaderContent>
        <List variant="unstyled" as="ul" margin="0" elementRef={el => this.listRef = el}>
          {this.props.collection.links.map(this.renderLink, this)}
        </List>
      </>
    );
  }

  renderEmptyIndicator() {
    return (
      <View as="div" padding="medium">{formatMessage("No results.")}</View>
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
      const showInitialLoadingIndicator = !this.hasLinks(this.props) && isLoading
      const showLoadMoreButton = this.hasLinks(this.props) && hasMore

      return (
        <div data-testid="instructure_links-LinkSet">
          {showInitialLoadingIndicator && (
            <View as="div" margin="medium" textAlign="center">
              <Spinner size="small" title={formatMessage('Loading...')} />
            </View>
          )}

          {this.hasLinks(this.props) && this.renderLinks()}
          {this.renderLoadingError()}

          {showLoadMoreButton && (
            <View margin="x-small medium medium medium">
              <LoadMoreButton
                isLoading={isLoading}
                onLoadMore={this.props.fetchNextPage}
              />
            </View>
          )}

          {this.isEmpty(this.props) &&
            !this.props.suppressRenderEmpty &&
            this.renderEmptyIndicator()}
        </div>
      );
    }
    return this.hasLinks(this.props) ? this.renderLinks() : this.renderEmptyIndicator()
  }
}

LinkSet.propTypes = {
  type: linkType.isRequired,
  collection: linksShape.isRequired,
  onLinkClick: func.isRequired,
  fetchInitialPage: func,
  fetchNextPage: func,
  suppressRenderEmpty: bool
}

export default LinkSet;
