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
import store from '../lib/AppCenterStore'
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'

export default class AppFilters extends React.Component {
  state = store.getState()

  componentDidMount() {
    store.addChangeListener(this.onChange)
  }

  componentWillUnmount() {
    store.removeChangeListener(this.onChange)
  }

  onChange = () => {
    this.setState(store.getState())
  }

  handleFilterClick = (filter, e) => {
    e.preventDefault()
    store.setState({filter})
    this.announceFilterResults()
  }

  applyFilter = () => {
    const filterText = this.filterText.value
    store.setState({filterText})
    this.announceFilterResults()
  }

  announceFilterResults = () => {
    const apps = store.filteredApps()
    $.screenReaderFlashMessageExclusive(I18n.t('%{count} apps found', {count: apps.length}))
  }

  focus () {
    this.filterText.focus()
  }

  render() {
    const activeFilter = store.getState().filter || 'all'
    return (
      <div className="AppFilters">
        <div className="content-box">
          <div className="grid-row">
            <div className="col-xs-7">
              <ul className="nav nav-pills" role="tablist">
                <li className={activeFilter === 'all' ? 'active' : ''}>
                  <a
                    ref={c => (this.tabAll = c)}
                    onClick={this.handleFilterClick.bind(this, 'all')}
                    href="#"
                    role="tab"
                    aria-selected={activeFilter === 'all' ? 'true' : 'false'}
                  >
                    {I18n.t('All')}
                  </a>
                </li>
                <li className={activeFilter === 'not_installed' ? 'active' : ''}>
                  <a
                    ref={c => (this.tabNotInstalled = c)}
                    onClick={this.handleFilterClick.bind(this, 'not_installed')}
                    href="#"
                    role="tab"
                    aria-selected={activeFilter === 'not_installed' ? 'true' : 'false'}
                  >
                    {I18n.t('Not Installed')}
                  </a>
                </li>
                <li className={activeFilter === 'installed' ? 'active' : ''}>
                  <a
                    ref={c => (this.tabInstalled = c)}
                    onClick={this.handleFilterClick.bind(this, 'installed')}
                    href="#"
                    role="tab"
                    aria-selected={activeFilter === 'installed' ? 'true' : 'false'}
                  >
                    {I18n.t('Installed')}
                  </a>
                </li>
                {
                  window.ENV.LTI_13_TOOLS_FEATURE_FLAG_ENABLED &&
                  <li className={activeFilter === 'lti_1_3_tools' ? 'active' : ''}>
                    <a
                      ref={c => (this.tabLti13Tools = c)}
                      onClick={this.handleFilterClick.bind(this, 'lti_1_3_tools')}
                      href="#"
                      role="tab"
                      aria-selected={activeFilter === 'lti_1_3_tools' ? 'true' : 'false'}
                    >
                      {I18n.t('LTI 1.3')}
                    </a>
                  </li>
                }
              </ul>
            </div>
            <div className="col-xs-5">
              <label htmlFor="filterText" className="screenreader-only">
                {I18n.t('Filter by name')}
              </label>
              <input
                type="text"
                id="filterText"
                ref={c => {
                  this.filterText = c
                }}
                defaultValue={this.state.filterText}
                className="input-block-level search-query"
                placeholder={I18n.t('Filter by name')}
                onKeyUp={this.applyFilter}
              />
            </div>
          </div>
        </div>
      </div>
    )
  }
}
