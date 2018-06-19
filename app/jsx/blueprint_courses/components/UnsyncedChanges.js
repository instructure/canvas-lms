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
import select from '../../shared/select'

import Alert from '@instructure/ui-core/lib/components/Alert'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Table from '@instructure/ui-core/lib/components/Table'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'

import UnsyncedChange from './UnsyncedChange'
import { ConnectedMigrationOptions as MigrationOptions } from './MigrationOptions'

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
    const heading = I18n.t('%{count} Unsynced Changes', {count: this.props.unsyncedChanges.length})

    return (
      <div className="bcs__history-item bcs__unsynced-changes">
        <header className="bcs__unsynced-item__title" aria-hidden="true" role="presentation">
          <Heading level="h3">{heading}</Heading>
        </header>
        <div className="bcs__unsynced-item__table">
          <Table caption={<ScreenReaderContent>{heading}</ScreenReaderContent>}>
            <thead className="screenreader-only">
              <tr>
                <th scope="col"><ScreenReaderContent>{I18n.t('Changed Item')}</ScreenReaderContent></th>
                <th scope="col"><ScreenReaderContent>{I18n.t('Type of Change')}</ScreenReaderContent></th>
                <th scope="col"><ScreenReaderContent>{I18n.t('Type of Item')}</ScreenReaderContent></th>
              </tr>
            </thead>
            <tbody>
              {this.props.unsyncedChanges.map(change =>
                (<UnsyncedChange key={`${change.asset_type}_${change.asset_id}`} change={change} />)
              )}
            </tbody>
          </Table>
        </div>
        <MigrationOptions />
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
