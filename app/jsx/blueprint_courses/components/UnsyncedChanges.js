/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React, { Component } from 'react'
import I18n from 'i18n!blueprint_settings'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import select from 'jsx/shared/select'

import Alert from 'instructure-ui/lib/components/Alert'
import Heading from 'instructure-ui/lib/components/Heading'

import UnsyncedChange from './UnsyncedChange'
import { ConnectedEnableNotification as EnableNotification } from './EnableNotification'

import actions from '../actions'
import propTypes from '../propTypes'

export default class UnsyncedChanges extends Component {
  static propTypes = {
    unsyncedChanges: propTypes.unsyncedChanges,
  }

  static defaultProps = {
    unsyncedChanges: [],
  }

  maybeRenderChanges () {
    return (
      this.props.unsyncedChanges.length === 0
      ?
        <Alert variant="info">{I18n.t('There are no unsynced changes')}</Alert>
      :
        this.renderChanges()
    )
  }

  renderChanges () {
    return (
      <div className="bcs__history-item bcs__unsynced-changes">
        <header className="bcs__history-item__title">
          <Heading level="h3">
            {I18n.t('%{count} Unsynced Changes', {count: this.props.unsyncedChanges.length})}
          </Heading>
        </header>
        {this.props.unsyncedChanges.map(change =>
          (<UnsyncedChange key={change.asset_id} change={change} />)
        )}
        <EnableNotification />
      </div>
    )
  }

  render () {
    return (
      <div className="bcs__history">
        {this.maybeRenderChanges()}
      </div>
    )
  }
}

const connectState = state =>
  select(state, [
    'unsyncedChanges',
  ])
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedUnsyncedChanges = connect(connectState, connectActions)(UnsyncedChanges)
