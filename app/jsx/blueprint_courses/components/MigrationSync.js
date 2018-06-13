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

import I18n from 'i18n!blueprint_settings'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import select from '../../shared/select'
import cx from 'classnames'
import 'compiled/jquery.rails_flash_notifications'

import Progress from '@instructure/ui-elements/lib/components/Progress'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Text from '@instructure/ui-elements/lib/components/Text'
import IconRefreshLine from '@instructure/ui-icons/lib/Line/IconRefresh'

import MigrationStates from '../migrationStates'
import propTypes from '../propTypes'
import actions from '../actions'

export default class MigrationSync extends Component {
  static propTypes = {
    id: PropTypes.string,
    migrationStatus: propTypes.migrationState.isRequired,
    hasCheckedMigration: PropTypes.bool.isRequired,
    isLoadingBeginMigration: PropTypes.bool.isRequired,
    checkMigration: PropTypes.func.isRequired,
    beginMigration: PropTypes.func.isRequired,
    stopMigrationStatusPoll: PropTypes.func.isRequired,
    showProgress: PropTypes.bool,
    willSendNotification: PropTypes.bool,
    onClick: PropTypes.func
  }

  static defaultProps = {
    id: 'migration_sync',
    showProgress: true,
    willSendNotification: false,
    onClick: null
  }

  constructor (props) {
    super(props)
    this.intId = null
  }

  componentWillMount () {
    if (!this.props.hasCheckedMigration) {
      this.props.checkMigration(true)
    }
  }

  componentWillUnmount () {
    this.props.stopMigrationStatusPoll()
  }

  handleSyncClick = () => {
    this.props.beginMigration()
    if (this.props.onClick) {
      this.props.onClick()
    }
  }

  render () {
    const { migrationStatus } = this.props
    const isSyncing = MigrationStates.isLoadingState(migrationStatus) || this.props.isLoadingBeginMigration
    const iconClasses = cx({
      'bcs__sync-btn-icon': true,
      'bcs__sync-btn-icon__active': isSyncing,
    })
    return (
      <div id={this.props.id} className="bcs__migration-sync">
        { this.props.showProgress && isSyncing && (
          <div className="bcs__migration-sync__loading">
            <Text as="p">{I18n.t('Processing')}</Text>
            <Text as="p" size="small">{I18n.t('This may take a bit...')}</Text>
            <Progress
              label={I18n.t('Sync in progress')}
              size="x-small"
              valueNow={MigrationStates.getLoadingValue(migrationStatus)}
              valueMax={MigrationStates.maxLoadingValue}
            />
            {this.props.willSendNotification &&
              <Text as="p" size="small">
                {I18n.t('You can leave the page and you will get a notification when the sync process is complete.')}
              </Text>}
          </div>
        )}
        <div className="bcs__migration-sync__button">
          <Button
            variant="primary"
            onClick={this.handleSyncClick}
            ref={(c) => { this.syncBtn = c }}
            disabled={isSyncing}
          >
            <span className={iconClasses}>
              <Text size="large">
                <IconRefreshLine />
              </Text>
            </span>
            <span className="bcs__sync-btn-text">
              {isSyncing ? I18n.t('Syncing...') : I18n.t('Sync')}
            </span>
          </Button>
        </div>
      </div>
    )
  }
}

const connectState = state =>
  select(state, [
    'migrationStatus',
    'isLoadingBeginMigration',
    'hasCheckedMigration',
    'willSendNotification',
  ])
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedMigrationSync = connect(connectState, connectActions)(MigrationSync)
