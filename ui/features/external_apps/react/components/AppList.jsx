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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import store from '../lib/AppCenterStore'
import page from 'page'
import extStore from '../lib/ExternalAppsStore'
import AppTile from './AppTile'
import Header from './Header'
import AppFilters from './AppFilters'
import ManageAppListButton from './ManageAppListButton'
import splitAssetString from '@canvas/util/splitAssetString'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('external_tools')

export default class AppList extends React.Component {
  static propTypes = {
    baseUrl: PropTypes.string.isRequired,
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

  refreshAppList = () => {
    store.reset()
    store.fetch()
  }

  isAccountContext() {
    return splitAssetString(ENV.context_asset_string, false)[0] === 'account'
  }

  manageAppListButton = () => {
    if (this.isAccountContext()) {
      return (
        <ManageAppListButton onUpdateAccessToken={this.refreshAppList} extAppStore={extStore} />
      )
    } else {
      return null
    }
  }

  viewConfigurationsButton = () => (
    <View>
      <Button
        margin="none x-small"
        onClick={() => {
          page.redirect('/configurations')
        }}
      >
        {I18n.t('View App Configurations')}
      </Button>
    </View>
  )

  apps = () => {
    if (store.getState().isLoading) {
      return <div ref={this.loadingIndicator} className="loadingIndicator" data-testid="spinner" />
    } else {
      return store
        .filteredApps()
        .map(app => <AppTile key={app.id} app={app} baseUrl={this.props.baseUrl} />)
    }
  }

  setAppFiltersRef = node => (this.appFilters = node)

  render() {
    return (
      <div className="AppList">
        <Header>
          {this.manageAppListButton()}
          {this.viewConfigurationsButton()}
        </Header>
        <AppFilters ref={this.setAppFiltersRef} />
        <div className="app_center">
          <div className="app_list">
            <div className="collectionViewItems clearfix">{this.apps()}</div>
          </div>
        </div>
      </div>
    )
  }
}
