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

import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import createReactClass from 'create-react-class'
import InfiniteScroll from '@canvas/infinite-scroll'
import {Spinner} from '@instructure/ui-spinner'
import Group from './Group'

const I18n = createI18nScope('student_groups')

const PaginatedGroupList = createReactClass({
  displayName: 'PaginatedGroupList',

  loader() {
    return (
      <div className="spinner-container">
        <Spinner renderTitle="Loading" size="large" margin="0 0 0 medium" />
      </div>
    )
  },

  loadMore() {
    this.props.loadMore()
  },

  render() {
    const groups = this.props.groups.map(g => (
      <Group
        key={g.id}
        group={g}
        onLeave={() => this.props.onLeave(g)}
        onJoin={() => this.props.onJoin(g)}
        onManage={() => this.props.onManage(g)}
      />
    ))
    return (
      <InfiniteScroll
        pageStart={0}
        loadMore={this.loadMore()}
        hasMore={this.props.hasMore}
        loader={this.loader()}
      >
        <div role="list" aria-label={I18n.t('Groups')}>
          {groups}
        </div>
      </InfiniteScroll>
    )
  },
})

export default PaginatedGroupList
