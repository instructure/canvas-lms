/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import I18n from 'i18n!new_nav'
import React from 'react'
import PropTypes from 'prop-types'
import SVGWrapper from '../../shared/SVGWrapper'
import Spinner from 'instructure-ui/lib/components/Spinner'

var AccountsTray = React.createClass({
  propTypes: {
    accounts: PropTypes.array.isRequired,
    closeTray: PropTypes.func.isRequired,
    hasLoaded: PropTypes.bool.isRequired
  },

  getDefaultProps() {
    return {
      accounts: []
    }
  },

  renderAccounts() {
    if (!this.props.hasLoaded) {
      return (
        <li className="ic-NavMenu-list-item ic-NavMenu-list-item--loading-message">
          <Spinner size="small" title={I18n.t('Loading')} />
        </li>
      )
    }
    var accounts = this.props.accounts.map(account => {
      return (
        <li key={account.id} className="ic-NavMenu-list-item">
          <a href={`/accounts/${account.id}`} className="ic-NavMenu-list-item__link">
            {account.name}
          </a>
        </li>
      )
    })
    accounts.push(
      <li key="allAccountLink" className="ic-NavMenu-list-item ic-NavMenu-list-item--feature-item">
        <a href="/accounts" className="ic-NavMenu-list-item__link">
          {I18n.t('All Accounts')}
        </a>
      </li>
    )
    return accounts
  },

  render() {
    return (
      <div>
        <div className="ic-NavMenu__header">
          <h1 className="ic-NavMenu__headline">{I18n.t('Admin')}</h1>
          <button
            className="Button Button--icon-action ic-NavMenu__closeButton"
            type="button"
            onClick={this.props.closeTray}
          >
            <i className="icon-x" />
            <span className="screenreader-only">{I18n.t('Close')}</span>
          </button>
        </div>
        <ul className="ic-NavMenu__link-list">{this.renderAccounts()}</ul>
      </div>
    )
  }
})

export default AccountsTray
