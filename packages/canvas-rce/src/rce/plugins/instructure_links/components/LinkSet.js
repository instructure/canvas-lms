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

import React, {Component, useRef} from 'react'
import {bool, func, string} from 'prop-types'
import {linksShape, linkType} from './propTypes'
import formatMessage from '../../../../format-message'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {List} from '@instructure/ui-list'
import {View} from '@instructure/ui-view'
import uid from '@instructure/uid'

import {
  LoadMoreButton,
  LoadingIndicator,
  LoadingStatus,
  useIncrementalLoading,
} from '../../../../common/incremental-loading'
import Link from './Link'

/*
 * This is needed only as long as `LinkSet` is a class component.
 */
function IncrementalLoader(props) {
  const {children, collection, fetchInitialPage, fetchNextPage, contextType, searchString} = props
  const {hasMore, isLoading, links} = collection
  const lastItemRef = useRef(null)

  const loader = useIncrementalLoading({
    hasMore: hasMore && fetchNextPage != null,
    isLoading,
    lastItemRef,
    contextType,
    sortBy: {sort: 'alphabetical', order: 'asc'}, // not actually used in the query, but a required param
    searchString,

    onLoadInitial() {
      if (fetchInitialPage) {
        fetchInitialPage()
      }
    },

    onLoadMore() {
      fetchNextPage()
    },

    records: links,
  })

  return children({loader, lastItemRef})
}

class LinkSet extends Component {
  constructor(props) {
    super(props)
    this.describedByID = `rce-LinkSet-describedBy-${uid()}`
    this.loadMoreButtonRef = null
  }

  hasLinks(props) {
    return props.collection.links.length > 0
  }

  isEmpty(props) {
    return !this.hasLinks(props) && !props.collection.hasMore && !props.collection.isLoading
  }

  renderLinks(lastItemRef) {
    function refFor(index, array) {
      if (!lastItemRef || index !== array.length - 1) {
        return null
      }

      // Return a compatible callback ref for InstUI
      return ref => {
        lastItemRef.current = ref
      }
    }

    return (
      <>
        <ScreenReaderContent id={this.describedByID}>
          {formatMessage('Click to insert a link into the editor.')}
        </ScreenReaderContent>

        <List variant="unstyled" as="ul" margin="0">
          {this.props.collection.links.map((link, index, array) => (
            <List.Item key={link.href} spacing="none" padding="0">
              <Link
                link={link}
                type={this.props.type}
                onClick={this.props.onLinkClick}
                describedByID={this.describedByID}
                elementRef={refFor(index, array)}
                editing={this.props.editing}
                onEditClick={this.props.onEditClick}
              />
            </List.Item>
          ))}
        </List>
      </>
    )
  }

  renderEmptyIndicator() {
    return (
      <View as="div" role="alert" padding="medium">
        {formatMessage('No results.')}
      </View>
    )
  }

  renderLoadingError() {
    if (this.props.collection.lastError) {
      return (
        <span className="rcs-LinkSet-LoadFailed" role="alert">
          {formatMessage('Loading failed...')}
        </span>
      )
    }
    return null
  }

  render() {
    return (
      <IncrementalLoader {...this.props}>
        {({loader, lastItemRef}) => (
          <>
            <div data-testid="instructure_links-LinkSet">
              {this.hasLinks(this.props) && this.renderLinks(lastItemRef)}
              {this.renderLoadingError()}

              {loader.isLoading && <LoadingIndicator loader={loader} />}

              {!loader.isLoading && loader.hasMore && <LoadMoreButton loader={loader} />}

              {this.isEmpty(this.props) &&
                !this.props.suppressRenderEmpty &&
                this.renderEmptyIndicator()}
            </div>

            <LoadingStatus loader={loader} />
          </>
        )}
      </IncrementalLoader>
    )
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
  searchString: string,
  editing: bool,
  onEditClick: func,
}

export default LinkSet
