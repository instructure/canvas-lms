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
import {Button} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {TabList} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'
import I18n from 'i18n!gradebook'

import AdvancedTabPanel from './AdvancedTabPanel'
import {
  fetchLatePolicy,
  createLatePolicy,
  updateCourseSettings,
  updateLatePolicy
} from '../apis/GradebookSettingsModalApi'
import {getAssignmentPostPolicies, setCoursePostPolicy} from '../PostPolicies/PostPolicyApi'
import LatePoliciesTabPanel from './LatePoliciesTabPanel'
import GradePostingPolicyTabPanel from './GradePostingPolicyTabPanel'
import {showFlashAlert} from '../../../shared/FlashAlert'

function isLatePolicySaveable({latePolicy: {changes, validationErrors}}) {
  return !_.isEmpty(changes) && _.isEmpty(validationErrors)
}

function haveCourseSettingsChanged({props, state}) {
  return Object.keys(state.courseSettings).some(
    key => props.courseSettings[key] !== state.courseSettings[key]
  )
}

function isPostPolicyChanged({props, state}) {
  if (props.postPolicies == null) {
    return false
  }

  const {postManually: oldPostManually} = props.postPolicies.coursePostPolicy
  const {postManually: newPostManually} = state.coursePostPolicy

  return oldPostManually !== newPostManually
}

function onSaveSettingsFailure() {
  const message = I18n.t('An error occurred while saving your settings')
  showFlashAlert({message, type: 'error'})
  return Promise.reject(new Error(message))
}

function onSavePostPolicyFailure(_error) {
  const message = I18n.t('An error occurred while saving the course post policy')
  showFlashAlert({message, type: 'error'})
  return Promise.reject(new Error(message))
}

function onUpdateSuccess({close}) {
  const message = I18n.t('Gradebook Settings updated')
  showFlashAlert({message, type: 'success'})
  close()
  return Promise.resolve()
}

const MODAL_CONTENTS_HEIGHT = 550

export default class GradebookSettingsModal extends React.Component {
  static propTypes = {
    anonymousAssignmentsPresent: bool,
    courseFeatures: shape({
      finalGradeOverrideEnabled: bool.isRequired
    }).isRequired,
    courseId: string.isRequired,
    courseSettings: shape({
      allowFinalGradeOverride: bool.isRequired
    }).isRequired,
    locale: string.isRequired,
    onClose: func.isRequired,
    onEntered: func,
    gradedLateSubmissionsExist: bool.isRequired,
    onCourseSettingsUpdated: func.isRequired,
    onLatePolicyUpdate: func.isRequired,
    postPolicies: shape({
      coursePostPolicy: shape({
        postManually: bool.isRequired
      }),
      setAssignmentPostPolicies: func.isRequired,
      setCoursePostPolicy: func.isRequired
    })
  }

  static defaultProps = {
    onEntered() {}
  }

  state = {
    courseSettings: {
      allowFinalGradeOverride: this.props.courseSettings.allowFinalGradeOverride
    },
    isOpen: false,
    latePolicy: {changes: {}, validationErrors: {}},
    coursePostPolicy: {
      postManually: this.props.postPolicies && this.props.postPolicies.coursePostPolicy.postManually
    },
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

  saveCourseSettings = () =>
    updateCourseSettings(this.props.courseId, this.state.courseSettings)
      .then(response => {
        this.props.onCourseSettingsUpdated(response.data)
      })
      .catch(onSaveSettingsFailure)

  savePostPolicy = () =>
    setCoursePostPolicy({
      courseId: this.props.courseId,
      postManually: this.state.coursePostPolicy.postManually
    })
      .then(_response => getAssignmentPostPolicies({courseId: this.props.courseId}))
      .then(response => {
        const {postManually} = this.state.coursePostPolicy
        this.props.postPolicies.setCoursePostPolicy({postManually})

        const {assignmentPostPoliciesById} = response
        this.props.postPolicies.setAssignmentPostPolicies({assignmentPostPoliciesById})
      })
      .catch(onSavePostPolicyFailure)

  handleUpdateButtonClicked = () => {
    const promises = []

    this.setState({processingRequests: true}, () => {
      if (isLatePolicySaveable(this.state)) {
        promises.push(this.saveLatePolicy())
      }

      if (haveCourseSettingsChanged(this)) {
        promises.push(this.saveCourseSettings())
      }

      if (isPostPolicyChanged(this)) {
        promises.push(this.savePostPolicy())
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

  changePostPolicy = coursePostPolicy => {
    this.setState({coursePostPolicy})
  }

  handleCourseSettingsChange = courseSettings => {
    this.setState({
      courseSettings: {...this.state.courseSettings, ...courseSettings}
    })
  }

  isUpdateButtonEnabled = () => {
    if (this.state.processingRequests) return false
    return (
      haveCourseSettingsChanged(this) ||
      isLatePolicySaveable(this.state) ||
      isPostPolicyChanged(this)
    )
  }

  open = () => {
    this.setState({isOpen: true})
  }

  close = () => {
    const state = {isOpen: false}

    if (this.props.postPolicies) {
      state.coursePostPolicy = this.props.postPolicies.coursePostPolicy
    }

    this.setState(state, () => {
      const latePolicy = {changes: {}, data: undefined, validationErrors: {}}
      // need to reset the latePolicy state _after_ the modal is closed, otherwise
      // the spinner will be visible for a brief moment before the modal closes.
      this.setState({latePolicy})
    })
  }

  render() {
    const includeAdvancedTab = this.props.courseFeatures.finalGradeOverrideEnabled

    return (
      <Modal
        label={I18n.t('Gradebook Settings')}
        onDismiss={this.close}
        onEntered={this.props.onEntered}
        onExited={this.props.onClose}
        onOpen={this.fetchLatePolicy}
        open={this.state.isOpen}
        size="large"
      >
        <Modal.Body>
          <View as="div" height={MODAL_CONTENTS_HEIGHT}>
            <TabList defaultSelectedIndex={0}>
              <TabList.Panel title={I18n.t('Late Policies')}>
                <LatePoliciesTabPanel
                  latePolicy={this.state.latePolicy}
                  changeLatePolicy={this.changeLatePolicy}
                  locale={this.props.locale}
                  showAlert={this.props.gradedLateSubmissionsExist}
                />
              </TabList.Panel>

              {this.props.postPolicies != null && (
                <TabList.Panel title={I18n.t('Grade Posting Policy')}>
                  <GradePostingPolicyTabPanel
                    anonymousAssignmentsPresent={this.props.anonymousAssignmentsPresent}
                    onChange={this.changePostPolicy}
                    settings={this.state.coursePostPolicy}
                  />
                </TabList.Panel>
              )}

              {includeAdvancedTab && (
                <TabList.Panel title={I18n.t('Advanced')}>
                  <AdvancedTabPanel
                    courseSettings={this.state.courseSettings}
                    onCourseSettingsChange={this.handleCourseSettingsChange}
                  />
                </TabList.Panel>
              )}
            </TabList>
          </View>
        </Modal.Body>

        <Modal.Footer>
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
        </Modal.Footer>
      </Modal>
    )
  }
}
