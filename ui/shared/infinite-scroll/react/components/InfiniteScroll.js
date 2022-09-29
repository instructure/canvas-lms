/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import React from 'react'

function topPosition(domElt) {
  if (!domElt) return 0
  return domElt.offsetTop + topPosition(domElt.offsetParent)
}

export default class InfiniteScroll extends React.Component {
  static defaultProps = {
    pageStart: 0,
    hasMore: false,
    loadMore() {},
    threshold: 250,
  }

  componentDidMount() {
    this.pageLoaded = this.props.pageStart
    if (this.props.scrollContainer) {
      this.scrollContainer = this.props.scrollContainer
    }
    this.attachScrollListener()
  }

  componentDidUpdate(prevProps) {
    if (prevProps.scrollContainer !== this.props.scrollContainer) {
      this.detachScrollListener()
      this.scrollContainer = this.props.scrollContainer
    }
    this.attachScrollListener()
  }

  render() {
    return (
      <div ref={el => (this.node = el)}>
        {this.props.children}
        {this.props.hasMore ? this.props.loader : null}
      </div>
    )
  }

  handleWindowScroll = () => {
    const scrollTop =
      window.pageYOffset !== undefined
        ? window.pageYOffset
        : (document.documentElement || document.body.parentNode || document.body).scrollTop
    if (
      topPosition(this.node) + this.node.offsetHeight - scrollTop - window.innerHeight <
      Number(this.props.threshold)
    ) {
      this.loadMore()
    }
  }

  handleElementScroll = () => {
    const {scrollTop, scrollHeight, clientHeight} = this.scrollContainer

    if (scrollTop + clientHeight >= scrollHeight - Number(this.props.threshold)) {
      this.loadMore()
    }
  }

  loadMore = () => {
    this.detachScrollListener()
    // call loadMore after detachScrollListener to allow
    // for non-async loadMore functions
    this.props.loadMore((this.pageLoaded += 1))
  }

  attachScrollListener() {
    if (!this.props.hasMore) return

    if (this.scrollContainer) {
      this.scrollContainer.addEventListener('scroll', this.handleElementScroll)
      window.addEventListener('resize', this.handleElementScroll)
      this.handleElementScroll()
    } else {
      window.addEventListener('scroll', this.handleWindowScroll)
      window.addEventListener('resize', this.handleWindowScroll)
      this.handleWindowScroll()
    }
  }

  detachScrollListener() {
    if (this.scrollContainer) {
      window.removeEventListener('resize', this.handleElementScroll)
      this.scrollContainer.removeEventListener('scroll', this.handleElementScroll)
    } else {
      window.removeEventListener('resize', this.handleWindowScroll)
      window.removeEventListener('scroll', this.handleWindowScroll)
    }
  }

  componentWillUnmount() {
    this.detachScrollListener()
  }
}
