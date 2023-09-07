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

/*
 * NOTICE: we need to re-visit our design and implementation with a11y
 * in mind as our anchor tags would be more accessible as buttons
 */
/* eslint-disable jsx-a11y/anchor-is-valid */

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import store from '../lib/AppCenterStore'
import $ from 'jquery'
import '@canvas/rails-flash-notifications'
import {IconButton} from '@instructure/ui-buttons'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'

const I18n = useI18nScope('external_tools')

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

  handleClear = e => {
    e.stopPropagation()
    this.filterText.value = ''
    this.applyFilter()
    this.inputRef.focus()
  }

  renderClearButton = () => {
    if (!this.filterText?.value?.length) return

    return (
      <IconButton
        type="button"
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel="Clear search"
        disabled={this.state.disabled || this.state.readOnly}
        onClick={this.handleClear}
      >
        <IconTroubleLine />
      </IconButton>
    )
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
              </ul>
            </div>
            <div className="col-xs-5">
              <TextInput
                renderLabel={<ScreenReaderContent>{I18n.t('Filter by name')}</ScreenReaderContent>}
                placeholder={I18n.t('Filter by name')}
                defaultValue={this.state.filterText}
                onInput={this.applyFilter}
                inputRef={el => (this.filterText = el)}
                renderBeforeInput={<IconSearchLine inline={false} />}
                renderAfterInput={this.renderClearButton()}
              />
            </div>
          </div>
        </div>
      </div>
    )
  }
}
