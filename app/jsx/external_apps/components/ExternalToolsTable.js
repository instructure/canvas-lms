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

import _ from 'underscore'
import I18n from 'i18n!external_tools'
import React from 'react'
import PropTypes from 'prop-types'
import store from '../../external_apps/lib/ExternalAppsStore'
import ExternalToolsTableRow from '../../external_apps/components/ExternalToolsTableRow'
import InfiniteScroll from '../../external_apps/components/InfiniteScroll'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

export default class ExternalToolsTable extends React.Component {
  static propTypes = {
    canAddEdit: PropTypes.bool.isRequired
  }

  state = store.getState()

  onChange = () => {
    this.setState(store.getState())
  }

  componentDidMount() {
    store.addChangeListener(this.onChange)
    store.fetch()
  }

  componentWillUnmount() {
    store.removeChangeListener(this.onChange)
  }

  loadMore = page => {
    if (store.getState().hasMore && !store.getState().isLoading) {
      store.fetch()
    }
  }

  loader = () => <div className="loadingIndicator" />

  trs = () => {
    if (store.getState().externalTools.length == 0) {
      return null
    }
    return store
      .getState()
      .externalTools.map((tool, idx) => (
        <ExternalToolsTableRow key={idx} tool={tool} canAddEdit={this.props.canAddEdit} />
      ))
  }

  render() {
    return (
      <div className="ExternalToolsTable">
        <InfiniteScroll
          pageStart={0}
          loadMore={this.loadMore}
          hasMore={store.getState().hasMore}
          loader={this.loader()}
        >
          <table
            className="ic-Table ic-Table--striped ic-Table--condensed"
            id="external-tools-table"
          >
            <caption className="screenreader-only">{I18n.t('External Apps')}</caption>
            <thead>
              <tr>
                <th scope="col" width="5%">
                  <ScreenReaderContent>{I18n.t('Status')}</ScreenReaderContent>
                </th>
                <th scope="col" width="65%">
                  {I18n.t('Name')}
                </th>
                <th scope="col" width="30%">
                  <ScreenReaderContent>{I18n.t('Actions')}</ScreenReaderContent>
                </th>
              </tr>
            </thead>
            <tbody className="collectionViewItems">{this.trs()}</tbody>
          </table>
        </InfiniteScroll>
      </div>
    )
  }
}
