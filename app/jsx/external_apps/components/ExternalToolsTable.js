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

import I18n from 'i18n!external_tools'
import React from 'react'
import PropTypes from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconQuestionLine} from '@instructure/ui-icons'

import store from '../lib/ExternalAppsStore'
import ExternalToolsTableRow from './ExternalToolsTableRow'
import InfiniteScroll from './InfiniteScroll'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import splitAssetString from 'compiled/str/splitAssetString'

export default class ExternalToolsTable extends React.Component {
  static propTypes = {
    canAddEdit: PropTypes.bool.isRequired,
    setFocusAbove: PropTypes.func.isRequired
  }

  state = store.getState()

  get assetContextType() {
    return splitAssetString(ENV.context_asset_string, false)[0]
  }

  onChange = () => {
    this.setState(store.getState())
  }

  componentDidMount() {
    store.addChangeListener(this.onChange)
    if (!store.getState().isLoaded) {
      store.fetch()
    }
  }

  componentWillUnmount() {
    store.removeChangeListener(this.onChange)
  }

  loadMore = _page => {
    if (store.getState().hasMore && !store.getState().isLoading) {
      store.fetch()
    }
  }

  loader = () => <div className="loadingIndicator" />

  setFocusAbove = tool => () => {
    const toolRow = tool && this[`externalTool${tool.app_id}`]
    if (toolRow && toolRow.button) {
      toolRow.focus()
    } else {
      this.props.setFocusAbove()
    }
  }

  setToolRowRef = tool => node => {
    this[`externalTool${tool.app_id}`] = node
  }

  trs = show_lti_favorite_toggles => {
    if (store.getState().externalTools.length === 0) {
      return null
    }
    let t = null
    const externalTools = store.getState().externalTools
    const rceFavCount = externalTools.reduce(
      (accum, current) => accum + (current.is_rce_favorite ? 1 : 0),
      0
    )
    return externalTools.map(tool => {
      t = (
        <ExternalToolsTableRow
          key={tool.app_id}
          ref={this.setToolRowRef(tool)}
          tool={tool}
          canAddEdit={this.props.canAddEdit}
          setFocusAbove={this.setFocusAbove(t)}
          favoriteCount={rceFavCount}
          contextType={this.assetContextType}
          showLTIFavoriteToggles={show_lti_favorite_toggles}
        />
      )
      return t
    })
  }

  // Don't forget to change the tooltip text when the rce_enhancements flag goes away
  render() {
    // only in account settings (not course), but not site_admin, and with the feature on, and with permissions
    const show_lti_favorite_toggles =
      /^account_/.test(ENV.context_asset_string) &&
      !ENV.ACCOUNT?.site_admin &&
      ENV.FEATURES?.rce_lti_favorites &&
      this.props.canAddEdit

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
                <th scope="col" style={{width: '2rem'}}>
                  <ScreenReaderContent>{I18n.t('Status')}</ScreenReaderContent>
                </th>
                <th scope="col">{I18n.t('Name')}</th>
                {show_lti_favorite_toggles && (
                  <th scope="col" style={{width: '12rem', whiteSpace: 'nowrap'}}>
                    {I18n.t('Add to RCE toolbar')}
                    <Tooltip
                      renderTip={I18n.t(
                        'There is a 2 app limit for placement within the RCE toolbar. This setting only applies to the enhanced RCE.'
                      )}
                      placement="top"
                      on={['click', 'focus']}
                    >
                      <IconButton
                        renderIcon={IconQuestionLine}
                        withBackground={false}
                        withBorder={false}
                        screenReaderLabel={I18n.t('Help')}
                        size="small"
                      />
                    </Tooltip>
                  </th>
                )}
                <th scope="col" style={{width: '4rem'}}>
                  <ScreenReaderContent>{I18n.t('Actions')}</ScreenReaderContent>
                </th>
              </tr>
            </thead>
            <tbody className="collectionViewItems">{this.trs(show_lti_favorite_toggles)}</tbody>
          </table>
        </InfiniteScroll>
      </div>
    )
  }
}
