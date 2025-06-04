/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('react_collaborations')

interface LoadMoreProps {
  hasMore: boolean
  loadMore: () => void
  isLoading?: boolean
  children?: React.ReactNode
}

class LoadMore extends React.Component<LoadMoreProps> {
  private parentRef = React.createRef<HTMLDivElement>()

  componentDidUpdate(oldProps: LoadMoreProps) {
    const oldCount = React.Children.count(oldProps.children)
    const newCount = React.Children.count(this.props.children)
    // not first results and not on delete
    if (oldCount > 0 && newCount > oldCount) {
      const element = this.parentRef.current?.querySelector(
        `*:nth-child(${oldCount + 1}) .lor-result a`,
      ) as HTMLElement | null
      if (element) {
        element.focus()
      }
    }
  }

  render() {
    const hasChildren = React.Children.count(this.props.children) > 0

    return (
      <div className="LoadMore" ref={this.parentRef}>
        {this.props.children}

        {this.props.hasMore && !this.props.isLoading && (
          <div className="LoadMore-button">
            <button type="button" className="Button--link" onClick={this.props.loadMore}>
              {I18n.t('Load more results')}
            </button>
          </div>
        )}

        {hasChildren && this.props.hasMore && (
          <div aria-hidden={!this.props.isLoading} className="LoadMore-loader" />
        )}
      </div>
    )
  }
}

export default LoadMore
