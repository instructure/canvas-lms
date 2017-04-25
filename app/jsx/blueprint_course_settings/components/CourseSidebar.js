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

import propTypes from '../propTypes'
import actions from '../actions'
import BlueprintSidebar from './BlueprintSidebar'
import BlueprintModal from './BlueprintModal'
import { ConnectedMigrationSync as MigrationSync } from './MigrationSync'
import { ConnectedBlueprintAssociations as BlueprintAssociations } from './BlueprintAssociations'
import { ConnectedSyncHistory as SyncHistory } from './SyncHistory'

export default class CourseSidebar extends Component {
  static propTypes = {
    hasLoadedAssociations: PropTypes.bool.isRequired,
    associations: propTypes.courseList.isRequired,
    loadAssociations: PropTypes.func.isRequired,
    saveAssociations: PropTypes.func.isRequired,
    clearAssociations: PropTypes.func.isRequired,
    hasAssociationChanges: PropTypes.bool.isRequired,
    isSavingAssociations: PropTypes.bool.isRequired,
  }

  constructor (props) {
    super(props)
    this.state = {
      isModalOpen: false,
      modalId: null,
    }
  }

  onOpenSidebar = () => {
    if (!this.props.hasLoadedAssociations) {
      this.props.loadAssociations()
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
          <Button ref={(c) => { this.asscBtn = c }} variant="link" onClick={this.handleAssociationsClick}>
            <Typography>{I18n.t('Associations')}</Typography>
          </Button>
          <Typography><span className="bcs__row-right-content">{this.props.associations.length}</span></Typography>
        </div>
        <div className="bcs__row">
          <Button ref={(c) => { this.syncHistoryBtn = c }} variant="link" onClick={this.handleSyncHistoryClick}>
            <Typography>{I18n.t('Sync History')}</Typography>
          </Button>
        </div>
        <MigrationSync />
        {this.renderModal()}
      </BlueprintSidebar>
    )
  }
}

const connectState = state =>
  Object.assign(select(state, [
    'hasLoadedAssociations',
    'migrationStatus',
    'isLoadingBeginMigration',
    'hasCheckedMigration',
    'isSavingAssociations',
    ['existingAssociations', 'associations'],
  ]), {
    hasAssociationChanges: (state.addedAssociations.length + state.removedAssociations.length) > 0,
  })
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedCourseSidebar = connect(connectState, connectActions)(CourseSidebar)
