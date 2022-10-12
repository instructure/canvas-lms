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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tabs} from '@instructure/ui-tabs'
import {Tray} from '@instructure/ui-tray'
import {useScope as useI18nScope} from '@canvas/i18n'

import AdvancedTabPanel from './AdvancedTabPanel'
import {
  fetchLatePolicy,
  createLatePolicy,
  updateCourseSettings,
  updateLatePolicy,
} from '../apis/GradebookSettingsModalApi'
import {getAssignmentPostPolicies, setCoursePostPolicy} from '../PostPolicies/PostPolicyApi'
import LatePoliciesTabPanel from './LatePoliciesTabPanel'
import GradePostingPolicyTabPanel from './GradePostingPolicyTabPanel'
import ViewOptionsTabPanel from './ViewOptionsTabPanel'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {confirmViewUngradedAsZero} from '../Gradebook.utils'

const I18n = useI18nScope('gradebook')

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

function haveViewOptionsChanged({state: {viewOptions, viewOptionsLastSaved}}) {
  return viewOptions != null && !_.isEqual(viewOptions, viewOptionsLastSaved)
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

function onSaveViewOptionsFailure(_error) {
  const message = I18n.t('An error occurred while updating view options')
  showFlashAlert({message, type: 'error'})
  return Promise.reject(new Error(message))
}

function onUpdateSuccess({close}) {
  const message = I18n.t('Gradebook Settings updated')
  showFlashAlert({message, type: 'success'})
  close()
  return Promise.resolve()
}

export default class GradebookSettingsModal extends React.Component {
  static propTypes = {
    allowSortingByModules: bool,
    allowViewUngradedAsZero: bool,
    allowShowSeparateFirstLastNames: bool,
    anonymousAssignmentsPresent: bool,
    courseFeatures: shape({
      finalGradeOverrideEnabled: bool.isRequired,
    }).isRequired,
    courseId: string.isRequired,
    courseSettings: shape({
      allowFinalGradeOverride: bool.isRequired,
    }).isRequired,
    locale: string.isRequired,
    onClose: func.isRequired,
    onEntered: func,
    gradebookIsEditable: bool.isRequired,
    gradedLateSubmissionsExist: bool.isRequired,
    loadCurrentViewOptions: func,
    onCourseSettingsUpdated: func.isRequired,
    onLatePolicyUpdate: func.isRequired,
    onViewOptionsUpdated: func.isRequired,
    postPolicies: shape({
      coursePostPolicy: shape({
        postManually: bool.isRequired,
      }),
      setAssignmentPostPolicies: func.isRequired,
      setCoursePostPolicy: func.isRequired,
    }),
  }

  static defaultProps = {
    onEntered() {},
  }

  state = {
    courseSettings: {
      allowFinalGradeOverride: this.props.courseSettings.allowFinalGradeOverride,
    },
    isOpen: false,
    latePolicy: {changes: {}, validationErrors: {}},
    coursePostPolicy: {
      postManually:
        this.props.postPolicies && this.props.postPolicies.coursePostPolicy.postManually,
    },
    processingRequests: false,
    selectedTab: 'tab-panel-late',
    viewOptions: this.props.loadCurrentViewOptions?.(),
    viewOptionsLastSaved: this.props.loadCurrentViewOptions?.(),
  }

  onFetchLatePolicySuccess = ({data}) => {
    this.changeLatePolicy({...this.state.latePolicy, data: data.latePolicy})
  }

  onFetchLatePolicyFailure = () => {
    const message = I18n.t('An error occurred while loading late policies')
    showFlashAlert({message, type: 'error', err: null})
  }

  onSaveLatePolicyFailure = () => {
    const message = I18n.t('An error occurred while updating late policies')
    showFlashAlert({message, type: 'error', err: null})
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
          ...this.state.latePolicy.changes,
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
      postManually: this.state.coursePostPolicy.postManually,
    })
      .then(_response => getAssignmentPostPolicies({courseId: this.props.courseId}))
      .then(response => {
        const {postManually} = this.state.coursePostPolicy
        this.props.postPolicies.setCoursePostPolicy({postManually})

        const {assignmentPostPoliciesById} = response
        this.props.postPolicies.setAssignmentPostPolicies({assignmentPostPoliciesById})
      })
      .catch(onSavePostPolicyFailure)

  saveViewOptions = () => {
    const savedOptions = _.cloneDeep(this.state.viewOptions)
    return this.props
      .onViewOptionsUpdated(savedOptions)
      .then(() => {
        this.setState({viewOptionsLastSaved: savedOptions})
      })
      .catch(onSaveViewOptionsFailure)
  }

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

      if (haveViewOptionsChanged(this)) {
        promises.push(this.saveViewOptions())
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
    this.setState(state => ({courseSettings: {...state, ...courseSettings}}))
  }

  isUpdateButtonEnabled = () => {
    if (this.state.processingRequests) return false
    return (
      haveCourseSettingsChanged(this) ||
      isLatePolicySaveable(this.state) ||
      isPostPolicyChanged(this) ||
      haveViewOptionsChanged(this)
    )
  }

  open = () => {
    this.setState(_state => ({
      isOpen: true,
      // We reset the View Options settings to their last-saved state here,
      // instead of on close, because doing the latter causes the reverted
      // settings to be briefly visible.
      viewOptions: this.props.loadCurrentViewOptions?.(),
      viewOptionsLastSaved: this.props.loadCurrentViewOptions?.(),
    }))
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

  setViewOption = (key, value) => {
    this.setState(state => ({viewOptions: {...state.viewOptions, [key]: value}}))
  }

  changeTab = (_ev, {id}) => {
    this.setState({selectedTab: id})
  }

  render() {
    const includeAdvancedTab = this.props.courseFeatures.finalGradeOverrideEnabled
    const tab = this.state.selectedTab

    return (
      <Tray
        label={I18n.t('Gradebook Settings')}
        onDismiss={this.close}
        onEntered={this.props.onEntered}
        onExited={this.props.onClose}
        onOpen={this.fetchLatePolicy}
        open={this.state.isOpen}
        placement="end"
        size="medium"
      >
        <Flex direction="column" height="100vh">
          <Flex.Item as="header" padding="medium">
            <Flex direction="row">
              <Flex.Item shouldGrow={true} shouldShrink={true}>
                <Heading level="h3">{I18n.t('Gradebook Settings')}</Heading>
              </Flex.Item>

              <Flex.Item>
                <CloseButton
                  placement="static"
                  onClick={this.close}
                  screenReaderLabel={I18n.t('Close')}
                />
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item shouldGrow={true} shouldShrink={true} overflowX="hidden">
            <Tabs onRequestTabChange={this.changeTab}>
              <Tabs.Panel
                renderTitle={I18n.t('Late Policies')}
                id="tab-panel-late"
                isSelected={tab === 'tab-panel-late'}
              >
                <LatePoliciesTabPanel
                  latePolicy={this.state.latePolicy}
                  changeLatePolicy={this.changeLatePolicy}
                  locale={this.props.locale}
                  showAlert={this.props.gradedLateSubmissionsExist}
                  gradebookIsEditable={this.props.gradebookIsEditable}
                />
              </Tabs.Panel>

              {this.props.postPolicies != null && (
                <Tabs.Panel
                  renderTitle={I18n.t('Grade Posting Policy')}
                  id="tab-panel-post"
                  isSelected={tab === 'tab-panel-post'}
                >
                  <GradePostingPolicyTabPanel
                    anonymousAssignmentsPresent={this.props.anonymousAssignmentsPresent}
                    onChange={this.changePostPolicy}
                    settings={this.state.coursePostPolicy}
                    gradebookIsEditable={this.props.gradebookIsEditable}
                  />
                </Tabs.Panel>
              )}

              {includeAdvancedTab && (
                <Tabs.Panel
                  renderTitle={I18n.t('Advanced')}
                  id="tab-panel-advanced"
                  isSelected={tab === 'tab-panel-advanced'}
                >
                  <AdvancedTabPanel
                    courseSettings={this.state.courseSettings}
                    onCourseSettingsChange={this.handleCourseSettingsChange}
                  />
                </Tabs.Panel>
              )}

              {this.props.loadCurrentViewOptions && (
                <Tabs.Panel
                  renderTitle={I18n.t('View Options')}
                  id="tab-panel-view-options"
                  isSelected={tab === 'tab-panel-view-options'}
                >
                  <ViewOptionsTabPanel
                    columnSort={{
                      currentValue: this.state.viewOptions.columnSortSettings,
                      modulesEnabled: this.props.allowSortingByModules,
                      onChange: ({criterion, direction}) => {
                        this.setViewOption('columnSortSettings', {criterion, direction})
                      },
                    }}
                    statusColors={{
                      currentValues: this.state.viewOptions.statusColors,
                      onChange: colors => {
                        this.setViewOption('statusColors', colors)
                      },
                    }}
                    showNotes={{
                      checked: this.state.viewOptions.showNotes,
                      onChange: value => {
                        this.setViewOption('showNotes', value)
                      },
                    }}
                    showUnpublishedAssignments={{
                      checked: this.state.viewOptions.showUnpublishedAssignments,
                      onChange: value => {
                        this.setViewOption('showUnpublishedAssignments', value)
                      },
                    }}
                    showSeparateFirstLastNames={{
                      allowed: this.props.allowShowSeparateFirstLastNames,
                      checked: this.state.viewOptions.showSeparateFirstLastNames,
                      onChange: value => {
                        this.setViewOption('showSeparateFirstLastNames', value)
                      },
                    }}
                    hideAssignmentGroupTotals={{
                      checked: this.state.viewOptions.hideAssignmentGroupTotals,
                      onChange: value => {
                        this.setViewOption('hideAssignmentGroupTotals', value)
                      },
                    }}
                    hideTotal={{
                      checked: this.state.viewOptions.hideTotal,
                      onChange: value => {
                        this.setViewOption('hideTotal', value)
                      },
                    }}
                    viewUngradedAsZero={{
                      allowed: this.props.allowViewUngradedAsZero,
                      checked: this.state.viewOptions.viewUngradedAsZero,
                      onChange: newValue => {
                        confirmViewUngradedAsZero({
                          currentValue: this.state.viewOptions.viewUngradedAsZero,
                          onAccepted: () => {
                            this.setViewOption('viewUngradedAsZero', newValue)
                          },
                        })
                      },
                    }}
                  />
                </Tabs.Panel>
              )}
            </Tabs>
          </Flex.Item>
          <Flex.Item
            id="gradebook-settings-modal-footer"
            align="end"
            as="footer"
            overflowY="hidden"
          >
            <Button id="gradebook-settings-cancel-button" onClick={this.close} margin="0 small">
              {I18n.t('Cancel')}
            </Button>

            <Button
              id="gradebook-settings-update-button"
              onClick={this.handleUpdateButtonClicked}
              disabled={!this.isUpdateButtonEnabled()}
              color="primary"
            >
              {I18n.t('Apply Settings')}
            </Button>
          </Flex.Item>
        </Flex>
      </Tray>
    )
  }
}
