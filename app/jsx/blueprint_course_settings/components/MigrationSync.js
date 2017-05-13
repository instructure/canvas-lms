import I18n from 'i18n!blueprint_settings'
import $ from 'jquery'
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import cx from 'classnames'
import 'compiled/jquery.rails_flash_notifications'

import Progress from 'instructure-ui/lib/components/Progress'
import Button from 'instructure-ui/lib/components/Button'
import Typography from 'instructure-ui/lib/components/Typography'
import IconRefreshLine from 'instructure-icons/react/Line/IconRefreshLine'

import MigrationStates from '../migrationStates'
import actions from '../actions'

export default class MigrationSync extends Component {
  static propTypes = {
    migrationStatus: PropTypes.oneOf(MigrationStates.states).isRequired,
    hasCheckedMigration: PropTypes.bool.isRequired,
    isLoadingBeginMigration: PropTypes.bool.isRequired,
    checkMigration: PropTypes.func.isRequired,
    beginMigration: PropTypes.func.isRequired,
    intervalDuration: PropTypes.number,
  }

  static defaultProps = {
    intervalDuration: 3000,
  }

  constructor (props) {
    super(props)
    this.intId = null
  }

  componentWillMount () {
    if (!this.props.hasCheckedMigration) {
      this.props.checkMigration()
    }
  }

  componentDidUpdate (prevProps) {
    // if migration is going from a non-loading state to a loading state
    // aka a migration was started or we just realized a migration is in progres on page load..
    if (MigrationStates.isLoadingState(this.props.migrationStatus) &&
        !MigrationStates.isLoadingState(prevProps.migrationStatus)) {
      // then start an interval to check for updates in the migration state
      this.clearMigrationInterval()
      this.intId = setInterval(() => {
        this.props.checkMigration()
      }, this.props.intervalDuration)
      $.screenReaderFlashMessage(I18n.t('Blueprint course sync in progress'))
    }

    // if migration is going from a loading state to a non-loading state
    // aka a migration probably just ended..
    if (!MigrationStates.isLoadingState(this.props.migrationStatus) &&
        MigrationStates.isLoadingState(prevProps.migrationStatus)) {
      // then we can stop checking for updates
      this.clearMigrationInterval()
      $.screenReaderFlashMessage(I18n.t('Blueprint course sync finished'))
    }
  }

  clearMigrationInterval () {
    if (this.intId !== null) {
      clearInterval(this.intId)
      this.intId = null
    }
  }

  handleSyncClick = () => {
    this.props.beginMigration()
  }

  render () {
    const { migrationStatus } = this.props
    const isSyncing = MigrationStates.isLoadingState(migrationStatus) || this.props.isLoadingBeginMigration
    const iconClasses = cx({
      'bcs__sync-btn-icon': true,
      'bcs__sync-btn-icon__active': isSyncing,
    })
    return (
      <div className="bcs__migration-sync">
        { isSyncing && (
          <span className="bcs__migration-sync__loading">
            <Typography as="p">{I18n.t('Processing')}</Typography>
            <Typography as="p" size="small">{I18n.t('This may take a bit...')}</Typography>
            <Progress
              label={I18n.t('Sync in progress')}
              size="x-small"
              valueNow={MigrationStates.getLoadingValue(migrationStatus)}
              valueMax={MigrationStates.maxLoadingValue}
            />
            <Typography as="p" size="small">
              {I18n.t('You can leave the page and you will get a notification when the sync process is complete.')}
            </Typography>
          </span>
        )}
        <span style={{float: 'right'}}>
          <Button
            variant="primary"
            onClick={this.handleSyncClick}
            ref={(c) => { this.syncBtn = c }}
            disabled={isSyncing}
          >
            <span className={iconClasses}>
              <Typography size="large">
                <IconRefreshLine />
              </Typography>
            </span>
            <span className="bcs__sync-btn-text">
              {isSyncing ? I18n.t('Syncing...') : I18n.t('Sync')}
            </span>
          </Button>
        </span>
      </div>
    )
  }
}

const connectState = ({
  migrationStatus,
  isLoadingBeginMigration,
  hasCheckedMigration,
}) => ({
  migrationStatus,
  isLoadingBeginMigration,
  hasCheckedMigration,
})
const connectActions = dispatch => bindActionCreators(actions, dispatch)

export const ConnectedMigrationSync = connect(connectState, connectActions)(MigrationSync)
