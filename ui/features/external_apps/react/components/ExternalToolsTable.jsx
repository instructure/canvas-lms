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
import PropTypes from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconQuestionLine} from '@instructure/ui-icons'

import store from '../lib/ExternalAppsStore'
import ExternalToolsTableRow from './ExternalToolsTableRow'
import InfiniteScroll from '@canvas/infinite-scroll'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import splitAssetString from '@canvas/util/splitAssetString'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('external_tools')

export class ExternalToolsTable extends React.Component {
  static propTypes = {
    canAdd: PropTypes.bool,
    canEdit: PropTypes.bool,
    canDelete: PropTypes.bool,
    setFocusAbove: PropTypes.func.isRequired,
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

  loader = () => (
    <div className="loadingIndicator">
      <View padding="x-small" textAlign="center" as="div" display="block">
        <Spinner delay={300} size="x-small" renderTitle={() => I18n.t('Loading')} />
      </View>
    </div>
  )

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
    const t = null
    const externalTools = store.getState().externalTools
    const rceFavCount = countFavorites(externalTools)
    const topNavFavCount = externalTools.reduce(
      (accum, current) => accum + (current.is_top_nav_favorite ? 1 : 0),
      0,
    )
    return externalTools.map(tool => (
      <ExternalToolsTableRow
        key={tool.app_id}
        ref={this.setToolRowRef(tool)}
        tool={tool}
        canAdd={this.props.canAdd}
        canEdit={this.props.canEdit}
        canDelete={this.props.canDelete}
        setFocusAbove={this.setFocusAbove(t)}
        rceFavoriteCount={rceFavCount}
        topNavFavoriteCount={topNavFavCount}
        contextType={this.assetContextType}
        showLTIFavoriteToggles={show_lti_favorite_toggles}
      />
    ))
  }

  render() {
    // only in account settings (not course), but not site_admin, and with the feature on, and with permissions
    const show_lti_favorite_toggles =
      /^account_/.test(ENV.context_asset_string) &&
      !ENV.ACCOUNT?.site_admin &&
      (this.props.canAdd || this.props.canEdit || this.props.canDelete)
    const show_top_nav_toggles = !!ENV.FEATURES?.top_navigation_placement

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
            data-testid="dev-key-admin-table"
          >
            <caption className="screenreader-only">{I18n.t('External Apps')}</caption>
            <thead>
              <tr>
                <th scope="col" style={{width: '2rem'}}>
                  <ScreenReaderContent>{I18n.t('Status')}</ScreenReaderContent>
                </th>
                <th scope="col">{I18n.t('Name')}</th>
                {show_lti_favorite_toggles && show_top_nav_toggles && (
                  <th scope="col" style={{width: '12rem', whiteSpace: 'nowrap'}}>
                    {I18n.t('Pin to Top Navigation')}
                    <Tooltip
                      renderTip={I18n.t(
                        'There is a 2 app limit for pinned tools in Top Navigation.',
                      )}
                      placement="top"
                      on={['hover', 'focus']}
                    >
                      <IconButton
                        renderIcon={IconQuestionLine}
                        withBackground={false}
                        withBorder={false}
                        screenReaderLabel={I18n.t('Help')}
                        size="small"
                        margin="none none none xx-small"
                      />
                    </Tooltip>
                  </th>
                )}
                {show_lti_favorite_toggles && (
                  <th scope="col" style={{width: '12rem', whiteSpace: 'nowrap'}}>
                    {I18n.t('Add to RCE toolbar')}
                    <Tooltip
                      renderTip={I18n.t(
                        'There is a 2 app limit on the RCE toolbar. Apps which Instructure defaults to on are not included in the limit.',
                      )}
                      placement="top"
                      on={['hover', 'focus']}
                    >
                      <IconButton
                        renderIcon={IconQuestionLine}
                        withBackground={false}
                        withBorder={false}
                        screenReaderLabel={I18n.t('Help')}
                        size="small"
                        margin="none none none xx-small"
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

export function countFavorites(tools) {
  return tools.reduce(
    // On_by_default apps don't count towards the limit
    (accum, current) =>
      accum +
      (current.is_rce_favorite &&
      !INST.editorButtons?.find(b => b.id === current.app_id)?.on_by_default
        ? 1
        : 0),
    0,
  )
}
