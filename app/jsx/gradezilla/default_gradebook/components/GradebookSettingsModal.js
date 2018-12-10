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

import React from 'react'
import {bool, func, shape, string} from 'prop-types'
import _ from 'underscore'
import I18n from 'i18n!gradebook'

import Button from '@instructure/ui-buttons/lib/components/Button'
import Modal, {ModalBody, ModalFooter} from '@instructure/ui-overlays/lib/components/Modal'
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'

import AdvancedTabPanel from './AdvancedTabPanel'
import {
  fetchLatePolicy,
  createLatePolicy,
  updateLatePolicy
} from '../apis/GradebookSettingsModalApi'
import LatePoliciesTabPanel from './LatePoliciesTabPanel'
import {showFlashAlert} from '../../../shared/FlashAlert'

function isLatePolicySaveable({latePolicy: {changes, validationErrors}}) {
  return !_.isEmpty(changes) && _.isEmpty(validationErrors)
}

function isOverridesChanged({
  props: {
    overrides: {defaultChecked}
  },
  state: {overrides}
}) {
  return defaultChecked !== overrides
}

function onSaveSettingsFailure() {
  const message = I18n.t('An error occurred while saving your settings')
  showFlashAlert({message, type: 'error'})
  return Promise.reject(new Error(message))
}

function onUpdateSuccess({close}) {
  const message = I18n.t('Gradebook Settings updated')
  showFlashAlert({message, type: 'success'})
  close()
  return Promise.resolve()
}

class GradebookSettingsModal extends React.Component {
  static propTypes = {
    courseId: string.isRequired,
    locale: string.isRequired,
    onClose: func.isRequired,
    gradedLateSubmissionsExist: bool.isRequired,
    onLatePolicyUpdate: func.isRequired,
    overrides: shape({
      disabled: bool.isRequired,
      onChange: func.isRequired,
      defaultChecked: bool.isRequired
    })
  }

  state = {
    isOpen: false,
    latePolicy: {changes: {}, validationErrors: {}},
    overrides: this.props.overrides.defaultChecked,
    processingRequests: false
  }

  onFetchLatePolicySuccess = ({data}) => {
    this.changeLatePolicy({...this.state.latePolicy, data: data.latePolicy})
  }

  onFetchLatePolicyFailure = () => {
    const message = I18n.t('An error occurred while loading late policies')
    showFlashAlert({message, type: 'error'})
  }

  onSaveLatePolicyFailure = () => {
    const message = I18n.t('An error occurred while updating late policies')
    showFlashAlert({message, type: 'error'})
    return Promise.reject(new Error(message))
  }

  fetchLatePolicy = () => {
    fetchLatePolicy(this.props.courseId)
      .then(this.onFetchLatePolicySuccess)
      .catch(this.onFetchLatePolicyFailure)
  }

  saveLatePolicy = () => {
    const createOrUpdate = this.state.latePolicy.data.newRecord
      ? createLatePolicy
      : updateLatePolicy
    return createOrUpdate(this.props.courseId, this.state.latePolicy.changes)
      .then(() =>
        this.props.onLatePolicyUpdate({
          ...this.state.latePolicy.data,
          ...this.state.latePolicy.changes
        })
      )
      .catch(this.onSaveLatePolicyFailure)
  }

  saveSettings = () => this.props.overrides.onChange().catch(onSaveSettingsFailure)

  handleUpdateButtonClicked = () => {
    const promises = []

    this.setState({processingRequests: true}, () => {
      if (isLatePolicySaveable(this.state)) {
        promises.push(this.saveLatePolicy())
      }
      if (isOverridesChanged(this)) {
        promises.push(this.saveSettings())
      }

      // can't use finally() to remove the duplication because we need to
      // skip onUpdateSuccess if an earlier promise rejected and removing the
      // last catch will mean these rejected promises are uncaught, which
      // causes `Uncaught (in promise) Error` to be logged in the console
      Promise.all(promises)
        .then(() => onUpdateSuccess(this))
        .then(() => this.setState({processingRequests: false}))
        .catch(() => this.setState({processingRequests: false}))
    })
  }

  changeLatePolicy = latePolicy => {
    this.setState({latePolicy})
  }

  changeOverrides = ({target: {checked}}) => {
    this.setState({overrides: checked})
  }

  isUpdateButtonEnabled = () => {
    if (this.state.processingRequests) return false
    return isOverridesChanged(this) || isLatePolicySaveable(this.state)
  }

  open = () => {
    this.setState({isOpen: true})
  }

  close = () => {
    this.setState({isOpen: false}, () => {
      const latePolicy = {changes: {}, data: undefined, validationErrors: {}}
      // need to reset the latePolicy state _after_ the modal is closed, otherwise
      // the spinner will be visible for a brief moment before the modal closes.
      this.setState({latePolicy})
    })
  }

  render() {
    const overrides = {
      disabled: this.props.overrides.disabled,
      onChange: this.changeOverrides,
      defaultChecked: this.state.overrides
    }

    return (
      <Modal
        size="large"
        open={this.state.isOpen}
        label={I18n.t('Gradebook Settings')}
        onOpen={this.fetchLatePolicy}
        onDismiss={this.close}
        onExited={this.props.onClose}
      >
        <ModalBody>
          <TabList defaultSelectedIndex={0}>
            <TabPanel title={I18n.t('Late Policies')}>
              <LatePoliciesTabPanel
                latePolicy={this.state.latePolicy}
                changeLatePolicy={this.changeLatePolicy}
                locale={this.props.locale}
                showAlert={this.props.gradedLateSubmissionsExist}
              />
            </TabPanel>
            <TabPanel title={I18n.t('Advanced')}>
              <AdvancedTabPanel overrides={overrides} />
            </TabPanel>
          </TabList>
        </ModalBody>

        <ModalFooter>
          <Button id="gradebook-settings-cancel-button" onClick={this.close} margin="0 small">
            {I18n.t('Cancel')}
          </Button>

          <Button
            id="gradebook-settings-update-button"
            onClick={this.handleUpdateButtonClicked}
            disabled={!this.isUpdateButtonEnabled()}
            variant="primary"
          >
            {I18n.t('Update')}
          </Button>
        </ModalFooter>
      </Modal>
    )
  }
}

export default GradebookSettingsModal
