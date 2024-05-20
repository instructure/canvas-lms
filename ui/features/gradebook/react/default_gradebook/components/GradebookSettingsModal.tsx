// @ts-nocheck
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
import {isEqual, isEmpty, cloneDeep} from 'lodash'
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
import type {
  GradebookViewOptions,
  LatePolicyCamelized,
  LatePolicyValidationErrors,
} from '../gradebook.d'

const I18n = useI18nScope('gradebook')

function isLatePolicySaveable({latePolicy: {changes, validationErrors}}): boolean {
  return !isEmpty(changes) && isEmpty(validationErrors)
}

function haveCourseSettingsChanged({props, state}): boolean {
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

function haveViewOptionsChanged({state: {viewOptions, viewOptionsLastSaved}}): boolean {
  return viewOptions != null && !isEqual(viewOptions, viewOptionsLastSaved)
}

function onSaveSettingsFailure() {
  const message = I18n.t('An error occurred while saving your settings')
  showFlashAlert({err: null, message, type: 'error'})
  return Promise.reject(new Error(message))
}

function onSavePostPolicyFailure(_error: Error) {
  const message = I18n.t('An error occurred while saving the course post policy')
  showFlashAlert({err: null, message, type: 'error'})
  return Promise.reject(new Error(message))
}

function onSaveViewOptionsFailure(_error: Error) {
  const message = I18n.t('An error occurred while updating view options')
  showFlashAlert({err: null, message, type: 'error'})
  return Promise.reject(new Error(message))
}

function onUpdateSuccess({close}) {
  const message = I18n.t('Gradebook Settings updated')
  showFlashAlert({err: null, message, type: 'success'})
  close()
  return Promise.resolve()
}

export type GradebookSettingsModalProps = {
  allowSortingByModules?: boolean
  allowViewUngradedAsZero?: boolean
  allowShowSeparateFirstLastNames?: boolean
  anonymousAssignmentsPresent: boolean
  courseFeatures: {
    finalGradeOverrideEnabled: boolean
  }
  courseId: string
  courseSettings: {
    allowFinalGradeOverride: boolean
  }
  locale: string
  onClose: () => void
  onEntered?: () => void
  gradebookIsEditable: boolean
  gradedLateSubmissionsExist: boolean
  loadCurrentViewOptions?: () => GradebookViewOptions
  onCourseSettingsUpdated: (courseSettings: {allowFinalGradeOverride: boolean}) => void
  onLatePolicyUpdate: (latePolicy: LatePolicyCamelized) => void
  onViewOptionsUpdated?: (viewOptions: GradebookViewOptions) => Promise<void | void[]>
  postPolicies: {
    coursePostPolicy: {
      postManually: boolean
    }
    setAssignmentPostPolicies: (assignmentPostPolicies: {
      assignmentPostPoliciesById: {[assignmentId: string]: {postManually: boolean}}
    }) => void
    setCoursePostPolicy: (coursePostPolicy: {courseId?: string; postManually: boolean}) => void
  }
  // eslint-disable-next-line react/no-unused-prop-types
  ref: React.RefObject<any>
}

type State = {
  courseSettings: {
    allowFinalGradeOverride: boolean
  }
  isOpen: boolean
  latePolicy: {
    changes: Partial<LatePolicyCamelized>
    data?: LatePolicyCamelized
    validationErrors: LatePolicyValidationErrors
  }
  coursePostPolicy: {
    postManually: boolean
  }
  processingRequests: boolean
  selectedTab: string | undefined
  viewOptions: GradebookViewOptions | null
  viewOptionsLastSaved: GradebookViewOptions | null
}

export default class GradebookSettingsModal extends React.Component<
  GradebookSettingsModalProps,
  State
> {
  static defaultProps = {
    onEntered() {},
  }

  state: State = {
    courseSettings: {
      allowFinalGradeOverride: this.props.courseSettings.allowFinalGradeOverride,
    },
    isOpen: false,
    latePolicy: {changes: {}, validationErrors: {}},
    coursePostPolicy: {
      postManually: Boolean(
        this.props.postPolicies && this.props.postPolicies.coursePostPolicy.postManually
      ),
    },
    processingRequests: false,
    selectedTab: 'tab-panel-late',
    viewOptions: this.props.loadCurrentViewOptions?.() || null,
    viewOptionsLastSaved: this.props.loadCurrentViewOptions?.() || null,
  }

  onFetchLatePolicySuccess = ({
    data,
  }: {
    data: {
      latePolicy: LatePolicyCamelized
    }
  }) => {
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
    if (!this.state.latePolicy.data) {
      throw new Error('latePolicy.data is required to save late policy')
    }

    const createOrUpdate = this.state.latePolicy.data.newRecord
      ? createLatePolicy
      : updateLatePolicy
    return createOrUpdate(this.props.courseId, this.state.latePolicy.changes)
      .then(() => {
        // can be cast because state.latePolicy.data exists
        const latePolicy = {
          ...(this.state.latePolicy.data || {}),
          ...this.state.latePolicy.changes,
        } as LatePolicyCamelized
        return this.props.onLatePolicyUpdate(latePolicy)
      })
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
    const savedOptions: GradebookViewOptions = cloneDeep(this.state.viewOptions)
    if (!this.props.onViewOptionsUpdated) {
      throw new Error('onViewOptionsUpdated is required to save view options')
    }
    return this.props
      .onViewOptionsUpdated(savedOptions)
      .then(() => {
        this.setState({viewOptionsLastSaved: savedOptions})
      })
      .catch(onSaveViewOptionsFailure)
  }

  handleUpdateButtonClicked = () => {
    const promises: Promise<void>[] = []

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

  changeLatePolicy = (latePolicy: {
    changes: Partial<LatePolicyCamelized>
    data?: LatePolicyCamelized
    validationErrors: LatePolicyValidationErrors
  }) => {
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
      viewOptions: this.props.loadCurrentViewOptions?.() || null,
      viewOptionsLastSaved: this.props.loadCurrentViewOptions?.() || null,
    }))
  }

  close = () => {
    const state: Pick<State, 'isOpen' | 'coursePostPolicy'> = {
      isOpen: false,
      coursePostPolicy: this.state.coursePostPolicy,
    }

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

  setViewOption = (
    key: string,
    value:
      | boolean
      | GradebookViewOptions['columnSortSettings']
      | GradebookViewOptions['statusColors']
  ) => {
    this.setState(state => {
      if (state.viewOptions == null) {
        return {viewOptions: state.viewOptions}
      } else {
        return {viewOptions: {...state.viewOptions, [key]: value}}
      }
    })
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
            <Tabs
              onRequestTabChange={(_ev, {id}) => {
                this.setState({selectedTab: id})
              }}
            >
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

              {this.props.loadCurrentViewOptions && this.state.viewOptions && (
                <Tabs.Panel
                  renderTitle={I18n.t('View Options')}
                  id="tab-panel-view-options"
                  isSelected={tab === 'tab-panel-view-options'}
                >
                  <ViewOptionsTabPanel
                    columnSort={{
                      currentValue: this.state.viewOptions.columnSortSettings,
                      modulesEnabled: Boolean(this.props.allowSortingByModules),
                      onChange: ({
                        criterion,
                        direction,
                      }: GradebookViewOptions['columnSortSettings']) => {
                        this.setViewOption('columnSortSettings', {criterion, direction})
                      },
                    }}
                    finalGradeOverrideEnabled={this.props.courseFeatures.finalGradeOverrideEnabled}
                    statusColors={{
                      currentValues: this.state.viewOptions.statusColors,
                      onChange: (colors: GradebookViewOptions['statusColors']) => {
                        this.setViewOption('statusColors', colors)
                      },
                    }}
                    showNotes={{
                      checked: this.state.viewOptions.showNotes,
                      onChange: (value: GradebookViewOptions['showNotes']) => {
                        this.setViewOption('showNotes', value)
                      },
                    }}
                    showUnpublishedAssignments={{
                      checked: this.state.viewOptions.showUnpublishedAssignments,
                      onChange: (value: GradebookViewOptions['showUnpublishedAssignments']) => {
                        this.setViewOption('showUnpublishedAssignments', value)
                      },
                    }}
                    showSeparateFirstLastNames={{
                      allowed: Boolean(this.props.allowShowSeparateFirstLastNames),
                      checked: this.state.viewOptions.showSeparateFirstLastNames,
                      onChange: (value: GradebookViewOptions['showSeparateFirstLastNames']) => {
                        this.setViewOption('showSeparateFirstLastNames', value)
                      },
                    }}
                    hideAssignmentGroupTotals={{
                      checked: this.state.viewOptions.hideAssignmentGroupTotals,
                      onChange: (value: GradebookViewOptions['hideAssignmentGroupTotals']) => {
                        this.setViewOption('hideAssignmentGroupTotals', value)
                      },
                    }}
                    hideTotal={{
                      checked: this.state.viewOptions.hideTotal,
                      onChange: (value: GradebookViewOptions['hideTotal']) => {
                        this.setViewOption('hideTotal', value)
                      },
                    }}
                    viewUngradedAsZero={{
                      allowed: Boolean(this.props.allowViewUngradedAsZero),
                      checked: this.state.viewOptions.viewUngradedAsZero,
                      onChange: (newValue: GradebookViewOptions['viewUngradedAsZero']) => {
                        if (!this.state.viewOptions) {
                          throw new Error('viewOptions is not defined')
                        }
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
