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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Component, lazy, Suspense} from 'react'
import PropTypes from 'prop-types'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import select from '@canvas/obj-select'

import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'
import {PresentationContent} from '@instructure/ui-a11y-content'

import propTypes from '@canvas/blueprint-courses/react/propTypes'
import actions from '@canvas/blueprint-courses/react/actions'
import MigrationStates from '@canvas/blueprint-courses/react/migrationStates'

import BlueprintSidebar from './BlueprintSidebar'
import BlueprintModal from '@canvas/blueprint-courses/react/components/BlueprintModal'
import {ConnectedMigrationSync as MigrationSync} from './MigrationSync'
import {ConnectedMigrationOptions as MigrationOptions} from './MigrationOptions'

const I18n = useI18nScope('blueprint_course_sidebar')

const BlueprintAssociations = lazy(() => import('./ConnectedBlueprintAssociations'))
const SyncHistory = lazy(() => import('./ConnectedSyncHistory'))
const UnsyncedChanges = lazy(() => import('./ConnectedUnsyncedChanges'))

export default class CourseSidebar extends Component {
  static propTypes = {
    realRef: PropTypes.func,
    routeTo: PropTypes.func.isRequired,
    unsyncedChanges: propTypes.unsyncedChanges,
    associations: propTypes.courseList.isRequired,
    migrationStatus: propTypes.migrationState,
    canManageCourse: PropTypes.bool.isRequired,
    canAutoPublishCourses: PropTypes.bool.isRequired,
    hasLoadedAssociations: PropTypes.bool.isRequired,
    hasAssociationChanges: PropTypes.bool.isRequired,
    willAddAssociations: PropTypes.bool.isRequired,
    willPublishCourses: PropTypes.bool.isRequired,
    enablePublishCourses: PropTypes.func.isRequired,
    isSavingAssociations: PropTypes.bool.isRequired,
    isLoadingUnsyncedChanges: PropTypes.bool.isRequired,
    hasLoadedUnsyncedChanges: PropTypes.bool.isRequired,
    isLoadingBeginMigration: PropTypes.bool.isRequired,
    selectChangeLog: PropTypes.func.isRequired,
    loadAssociations: PropTypes.func.isRequired,
    saveAssociations: PropTypes.func.isRequired,
    clearAssociations: PropTypes.func.isRequired,
    enableSendNotification: PropTypes.func.isRequired,
    loadUnsyncedChanges: PropTypes.func.isRequired,
    contentRef: PropTypes.func, // to get reference to the content of the Tray facilitates unit testing
  }

  static defaultProps = {
    unsyncedChanges: [],
    contentRef: null,
    migrationStatus: MigrationStates.states.unknown,
    realRef: () => {},
  }

  state = {
    isModalOpen: false,
    modalId: null,
  }

  componentDidMount() {
    this.props.realRef(this)
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    // if migration is going from a loading state to a non-loading state
    // aka a migration probably just ended and we should refresh the list
    // of unsynced changes
    if (
      MigrationStates.isLoadingState(this.props.migrationStatus) &&
      !MigrationStates.isLoadingState(nextProps.migrationStatus)
    ) {
      this.props.loadUnsyncedChanges()
    }
  }

  onOpenSidebar = () => {
    if (!this.props.hasLoadedAssociations) {
      this.props.loadAssociations()
    }
    if (!this.props.hasLoadedUnsyncedChanges) {
      this.props.loadUnsyncedChanges()
    }
  }

  modals = {
    associations: () => ({
      props: {
        title: I18n.t('Associations'),
        hasChanges: this.props.hasAssociationChanges,
        isSaving: this.props.isSavingAssociations,
        onSave: this.props.saveAssociations,
        canAutoPublishCourses: this.props.canAutoPublishCourses,
        willAddAssociations: this.props.willAddAssociations,
        willPublishCourses: this.props.willPublishCourses,
        enablePublishCourses: this.props.enablePublishCourses,
        onCancel: () =>
          this.closeModal(() => {
            this.asscBtn.focus()
            this.props.clearAssociations()
          }),
      },
      children: (
        <Suspense fallback={<div>{I18n.t('Loading associations...')}</div>}>
          <BlueprintAssociations />
        </Suspense>
      ),
      onCancel: () =>
        this.closeModal(() => {
          this.asscBtn.focus()
          this.props.clearAssociations()
        }),
    }),
    syncHistory: () => ({
      props: {
        title: I18n.t('Sync History'),
        onCancel: () =>
          this.closeModal(() => {
            if (this.syncHistoryBtn) this.syncHistoryBtn.focus()
          }),
      },
      children: (
        <Suspense fallback={<div>{I18n.t('Loading sync history...')}</div>}>
          <SyncHistory />
        </Suspense>
      ),
    }),
    unsyncedChanges: () => ({
      props: {
        title: I18n.t('Unsynced Changes'),
        hasChanges: this.props.unsyncedChanges.length > 0,
        onCancel: () =>
          this.closeModal(() => {
            this.unsyncedChangesBtn.focus()
          }),
        saveButton: (
          <MigrationSync
            id="unsynced_changes_modal_sync"
            showProgress={false}
            onClick={() =>
              this.closeModal(() => {
                if (this.unsyncedChangesBtn) {
                  this.unsyncedChangesBtn.focus()
                } else {
                  this.syncHistoryBtn.focus()
                }
              })
            }
          />
        ),
      },
      children: (
        <Suspense fallback={<div>{I18n.t('Loading unsynced changes...')}</div>}>
          <UnsyncedChanges />
        </Suspense>
      ),
    }),
  }

  closeModal = cb => {
    this.clearRoutes()
    this.setState({isModalOpen: false}, cb)
  }

  handleAssociationsClick = () => {
    this.setState({
      isModalOpen: true,
      modalId: 'associations',
    })
  }

  handleSyncHistoryClick = () => {
    this.openHistoryModal()
  }

  handleUnsyncedChangesClick = () => {
    this.setState({
      isModalOpen: true,
      modalId: 'unsyncedChanges',
    })
  }

  handleSendNotificationClick = event => {
    const enabled = event.target.checked
    this.props.enableSendNotification(enabled)
  }

  clearRoutes = () => {
    this.props.routeTo('#!/blueprint')
  }

  openHistoryModal() {
    this.setState({
      isModalOpen: true,
      modalId: 'syncHistory',
    })
  }

  showChangeLog(params) {
    this.props.selectChangeLog(params)
    this.openHistoryModal()
  }

  hideChangeLog() {
    this.props.selectChangeLog(null)
  }

  maybeRenderSyncButton() {
    const hasAssociations = this.props.associations.length > 0
    const syncIsActive = MigrationStates.isLoadingState(this.props.migrationStatus)
    const hasUnsyncedChanges =
      this.props.hasLoadedUnsyncedChanges && this.props.unsyncedChanges.length > 0

    if (hasAssociations && (syncIsActive || hasUnsyncedChanges)) {
      return (
        <div className="bcs__row bcs__row-sync-holder">
          <MigrationSync />
        </div>
      )
    }
    return null
  }

  maybeRenderUnsyncedChanges() {
    // if has no associations or sync in progress, hide
    const hasAssociations = this.props.associations.length > 0
    const isSyncing =
      MigrationStates.isLoadingState(this.props.migrationStatus) ||
      this.props.isLoadingBeginMigration

    if (!hasAssociations || isSyncing) {
      return null
    }

    // if loading changes, show spinner
    if (!this.props.hasLoadedUnsyncedChanges || this.props.isLoadingUnsyncedChanges) {
      return this.renderSpinner(I18n.t('Loading Unsynced Changes'))
    }

    // if changes are loaded, show me
    if (this.props.hasLoadedUnsyncedChanges && this.props.unsyncedChanges.length > 0) {
      return (
        <div className="bcs__row">
          <Link
            aria-label={I18n.t(
              {one: 'There is 1 Unsynced Change', other: 'There are %{count} Unsynced Changes'},
              {count: this.props.unsyncedChanges.length}
            )}
            id="mcUnsyncedChangesBtn"
            ref={c => {
              this.unsyncedChangesBtn = c
            }}
            onClick={this.handleUnsyncedChangesClick}
            isWithinText={false}
            margin="x-small 0"
          >
            <Text>{I18n.t('Unsynced Changes')}</Text>
          </Link>
          <PresentationContent>
            <Text>
              <span className="bcs__row-right-content">{this.props.unsyncedChanges.length}</span>
            </Text>
          </PresentationContent>
          <MigrationOptions />
        </div>
      )
    }

    return null
  }

  maybeRenderAssociations() {
    if (!this.props.canManageCourse) return null
    const isSyncing =
      MigrationStates.isLoadingState(this.props.migrationStatus) ||
      this.props.isLoadingBeginMigration
    const length = this.props.associations.length
    const button = (
      <div className="bcs__row bcs__row__associations">
        <Link
          aria-label={I18n.t(
            {one: 'There is 1 Association', other: 'There are %{count} Associations'},
            {count: length}
          )}
          disabled={isSyncing}
          id="mcSidebarAsscBtn"
          ref={c => {
            this.asscBtn = c
          }}
          onClick={this.handleAssociationsClick}
          isWithinText={false}
          margin="x-small 0"
        >
          <Text>{I18n.t('Associations')}</Text>
        </Link>
        <PresentationContent>
          <Text>
            <span className="bcs__row-right-content">{length}</span>
          </Text>
        </PresentationContent>
      </div>
    )

    if (isSyncing) {
      return (
        <Tooltip color="primary" renderTip={I18n.t('Not available during sync')} placement="bottom">
          {button}
        </Tooltip>
      )
    } else {
      return button
    }
  }

  renderSpinner(title) {
    return (
      <div style={{textAlign: 'center'}}>
        <Spinner size="small" renderTitle={title} />
        <Text size="small" as="p">
          {title}
        </Text>
      </div>
    )
  }

  renderModal() {
    if (this.modals[this.state.modalId]) {
      const modal = this.modals[this.state.modalId]()
      return (
        <BlueprintModal {...modal.props} isOpen={this.state.isModalOpen}>
          {modal.children}
        </BlueprintModal>
      )
    } else {
      return null
    }
  }

  render() {
    return (
      <BlueprintSidebar
        onOpen={this.onOpenSidebar}
        contentRef={this.props.contentRef}
        detachedChildren={this.renderModal()}
      >
        <div>
          {this.maybeRenderAssociations()}
          <div className="bcs__row">
            <Link
              id="mcSyncHistoryBtn"
              ref={c => {
                this.syncHistoryBtn = c
              }}
              onClick={this.handleSyncHistoryClick}
              isWithinText={false}
              margin="x-small 0"
            >
              <Text>{I18n.t('Sync History')}</Text>
            </Link>
          </div>
          {this.maybeRenderUnsyncedChanges()}
          {this.maybeRenderSyncButton()}
        </div>
      </BlueprintSidebar>
    )
  }
}

const connectState = state =>
  Object.assign(
    select(state, [
      'canManageCourse',
      'canAutoPublishCourses',
      'willPublishCourses',
      'hasLoadedAssociations',
      'isLoadingBeginMigration',
      'isSavingAssociations',
      ['existingAssociations', 'associations'],
      'unsyncedChanges',
      'isLoadingUnsyncedChanges',
      'hasLoadedUnsyncedChanges',
      'migrationStatus',
    ]),
    {
      hasAssociationChanges: state.addedAssociations.length + state.removedAssociations.length > 0,
      willAddAssociations: state.addedAssociations.length > 0,
    }
  )
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedCourseSidebar = connect(connectState, connectActions)(CourseSidebar)
