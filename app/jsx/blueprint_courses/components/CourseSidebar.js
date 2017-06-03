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
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import select from 'jsx/shared/select'

import Button from 'instructure-ui/lib/components/Button'
import Typography from 'instructure-ui/lib/components/Typography'
import Spinner from 'instructure-ui/lib/components/Spinner'

import propTypes from '../propTypes'
import actions from '../actions'
import MigrationStates from '../migrationStates'

import BlueprintSidebar from './BlueprintSidebar'
import BlueprintModal from './BlueprintModal'
import { ConnectedMigrationSync as MigrationSync } from './MigrationSync'
import { ConnectedBlueprintAssociations as BlueprintAssociations } from './BlueprintAssociations'
import { ConnectedSyncHistory as SyncHistory } from './SyncHistory'
import { ConnectedEnableNotification as EnableNotification } from './EnableNotification'

let UnsynchedChanges = null

export default class CourseSidebar extends Component {
  static propTypes = {
    hasLoadedAssociations: PropTypes.bool.isRequired,
    associations: propTypes.courseList.isRequired,
    loadAssociations: PropTypes.func.isRequired,
    saveAssociations: PropTypes.func.isRequired,
    clearAssociations: PropTypes.func.isRequired,
    hasAssociationChanges: PropTypes.bool.isRequired,
    isSavingAssociations: PropTypes.bool.isRequired,
    willSendNotification: PropTypes.bool.isRequired,
    enableSendNotification: PropTypes.func.isRequired,
    loadUnsynchedChanges: PropTypes.func.isRequired,
    isLoadingUnsynchedChanges: PropTypes.bool.isRequired,
    hasLoadedUnsynchedChanges: PropTypes.bool.isRequired,
    unsynchedChanges: propTypes.unsynchedChanges,
    isLoadingBeginMigration: PropTypes.bool.isRequired,
    migrationStatus: propTypes.migrationState,
  }

  static defaultProps = {
    unsynchedChanges: [],
    migrationStatus: MigrationStates.unknown,
  }

  constructor (props) {
    super(props)
    this.state = {
      isModalOpen: false,
      modalId: null,
    }
  }

  componentWillReceiveProps (nextProps) {
    // if migration is going from a loading state to a non-loading state
    // aka a migration probably just ended and we should refresh the list
    // of unsynched changes
    if (MigrationStates.isLoadingState(this.props.migrationStatus) &&
       !MigrationStates.isLoadingState(nextProps.migrationStatus)) {
      this.props.loadUnsynchedChanges()
    }
  }

  onOpenSidebar = () => {
    if (!this.props.hasLoadedAssociations) {
      this.props.loadAssociations()
    }
    if (!this.props.hasLoadedUnsynchedChanges) {
      this.props.loadUnsynchedChanges()
    }
  }

  modals = {
    associations: () => ({
      props: {
        title: I18n.t('Associations'),
        hasChanges: this.props.hasAssociationChanges,
        isSaving: this.props.isSavingAssociations,
        onSave: this.props.saveAssociations,
        onCancel: () => this.closeModal(() => {
          this.asscBtn.focus()
          this.props.clearAssociations()
        }),
      },
      children: () => <BlueprintAssociations />,
      onCancel: () => this.closeModal(() => {
        this.asscBtn.focus()
        this.props.clearAssociations()
      }),
    }),
    syncHistory: () => ({
      props: {
        title: I18n.t('Sync History'),
        onCancel: () => this.closeModal(() => {
          this.syncHistoryBtn.focus()
        }),
      },
      children: () => <SyncHistory />,
    }),
    unsynchedChanges: () => ({
      props: {
        hasChanges: this.props.unsynchedChanges.length > 0,
        willSendNotification: this.props.willSendNotification,
        enableSendNotification: this.props.enableSendNotification,
        onCancel: () => this.closeModal(() => {
          this.unsynchedChangesBtn.focus()
        }),
        doneButton: <MigrationSync
          showProgress={false}
          onClick={() => this.closeModal(() => {
            if (this.unsynchedChangesBtn) {
              this.unsynchedChangesBtn.focus()
            } else {
              this.syncHistoryBtn.focus()
            }
          })}
        />
      },
      children: () => <UnsynchedChanges />,
    })
  }

  closeModal = (cb) => {
    this.setState({ isModalOpen: false }, cb)
  }

  handleAssociationsClick = () => {
    this.setState({
      isModalOpen: true,
      modalId: 'associations',
    })
  }

  handleSyncHistoryClick = () => {
    this.setState({
      isModalOpen: true,
      modalId: 'syncHistory',
    })
  }

  handleUnsynchedChangesClick = () => {
    require.ensure([], (require) => {
      // lazy load UnsynchedChanges component
      const UnsynchedChangesModule = require('./UnsynchedChanges')
      if (UnsynchedChanges === null) {
        UnsynchedChanges = UnsynchedChangesModule.ConnectedUnsynchedChanges
      }

      this.setState({
        isModalOpen: true,
        modalId: 'unsynchedChanges',
      })
    })
  }

  handleSendNotificationClick = (event) => {
    const enabled = event.target.checked
    this.props.enableSendNotification(enabled)
  }

  // if we have unsynched changes, show the sync button
  maybeRenderSyncButton () {
    if (this.props.hasLoadedUnsynchedChanges && this.props.unsynchedChanges.length > 0) {
      return (
        <div className="bcs__row bcs__row-sync-holder">
          <MigrationSync />
        </div>
      )
    }
    return null
  }

  // if we have unsynched changes, show the button
  maybeRenderUnsynchedChanges () {
    // if loading changes, show spinner
    if (!this.props.hasLoadedUnsynchedChanges || this.props.isLoadingUnsynchedChanges) {
      return this.renderSpinner(I18n.t('Loading Unsynched Changes'))
    }
    // if syncing, hide
    const isSyncing = MigrationStates.isLoadingState(this.props.migrationStatus) || this.props.isLoadingBeginMigration
    if (isSyncing) {
      return null
    }
    // if changes are loaded, show me
    if (this.props.hasLoadedUnsynchedChanges && this.props.unsynchedChanges.length > 0) {
      return (
        <div className="bcs__row">
          <Button
            id="mcUnsynchedChangesBtn"
            ref={(c) => { this.unsynchedChangesBtn = c }}
            variant="link"
            onClick={this.handleUnsynchedChangesClick}
          >
            <Typography>{I18n.t('Unsynched Changes')}</Typography>
          </Button>
          <Typography><span className="bcs__row-right-content">{this.props.unsynchedChanges.length}</span></Typography>
          <EnableNotification />
        </div>
      )
    }
    return null
  }

  renderSpinner (title) {
    return (
      <div style={{textAlign: 'center'}}>
        <Spinner size="small" title={title} />
        <Typography size="small" as="p">{title}</Typography>
      </div>
    )
  }

  renderModal () {
    if (this.modals[this.state.modalId]) {
      const modal = this.modals[this.state.modalId]()
      return <BlueprintModal {...modal.props} isOpen={this.state.isModalOpen}>{modal.children}</BlueprintModal>
    } else {
      return null
    }
  }

  render () {
    return (
      <BlueprintSidebar onOpen={this.onOpenSidebar}>
        <div className="bcs__row">
          <Button id="mcSidebarAsscBtn" ref={(c) => { this.asscBtn = c }} variant="link" onClick={this.handleAssociationsClick}>
            <Typography>{I18n.t('Associations')}</Typography>
          </Button>
          <Typography><span className="bcs__row-right-content">{this.props.associations.length}</span></Typography>
        </div>
        <div className="bcs__row">
          <Button id="mcSyncHistoryBtn" ref={(c) => { this.syncHistoryBtn = c }} variant="link" onClick={this.handleSyncHistoryClick}>
            <Typography>{I18n.t('Sync History')}</Typography>
          </Button>
        </div>
        {this.maybeRenderUnsynchedChanges()}
        {this.maybeRenderSyncButton()}
        {this.renderModal()}
      </BlueprintSidebar>
    )
  }
}

const connectState = state =>
  Object.assign(select(state, [
    'hasLoadedAssociations',
    'isLoadingBeginMigration',
    'hasCheckedMigration',
    'isSavingAssociations',
    ['existingAssociations', 'associations'],
    'willSendNotification',
    'unsynchedChanges',
    'isLoadingUnsynchedChanges',
    'hasLoadedUnsynchedChanges',
    'migrationStatus'
  ]), {
    hasAssociationChanges: (state.addedAssociations.length + state.removedAssociations.length) > 0,
  })
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedCourseSidebar = connect(connectState, connectActions)(CourseSidebar)
