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
import store from '../../external_apps/lib/AppCenterStore'
import extStore from '../../external_apps/lib/ExternalAppsStore'
import AppTile from '../../external_apps/components/AppTile'
import Header from '../../external_apps/components/Header'
import AppFilters from '../../external_apps/components/AppFilters'
import ManageAppListButton from '../../external_apps/components/ManageAppListButton'
import Lti13Apps from './Lti13Apps'
import splitAssetString from 'compiled/str/splitAssetString'

export default class AppList extends React.Component {
  state = store.getState()

  onChange = () => {
    this.setState(store.getState())
  }

  componentDidMount() {
    store.addChangeListener(this.onChange)
    store.fetch()
    if (this.props.alreadyRendered) {
      this.appFilters.focus()
    }
  }

  componentWillUnmount() {
    store.removeChangeListener(this.onChange)
  }

  get contextType() {
    return splitAssetString(ENV.context_asset_string, false)[0]
  }

  refreshAppList = () => {
    store.reset()
    store.fetch()
  }

  manageAppListButton = () => {
    if (this.contextType === 'account') {
      return (
        <ManageAppListButton onUpdateAccessToken={this.refreshAppList} extAppStore={extStore} />
      )
    } else {
      return null
    }
  }

  apps = () => {
    if (store.getState().isLoading) {
      return <div ref="loadingIndicator" className="loadingIndicator" />
    } else if (store.getState().filter === 'lti_1_3_tools' && window.ENV.LTI_13_TOOLS_FEATURE_FLAG_ENABLED) {
      return <Lti13Apps store={store} contextType={this.contextType} />
    } else {
      return store
        .filteredApps()
        .map((app) => <AppTile key={app.app_id} app={app} pathname={this.props.pathname} />)
    }
  }

  setAppFiltersRef = (node) => this.appFilters = node

  render() {
    return (
      <div className="AppList">
        <Header>
          {this.manageAppListButton()}
          <a
            href={`${this.props.pathname}/configurations`}
            className="btn view_tools_link lm pull-right"
          >
            {I18n.t('View App Configurations')}
          </a>
        </Header>
        <AppFilters
          ref={this.setAppFiltersRef}
        />
        <div className="app_center">
          <div className="app_list">
            <div className="collectionViewItems clearfix">{this.apps()}</div>
          </div>
        </div>
      </div>
    )
  }
}
