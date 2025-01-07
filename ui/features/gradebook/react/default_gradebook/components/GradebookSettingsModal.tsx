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

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tabs} from '@instructure/ui-tabs'
import {Tray} from '@instructure/ui-tray'
import {cloneDeep, isEmpty, isEqual} from 'lodash'
import React, {useState} from 'react'
import {confirmViewUngradedAsZero} from '../Gradebook.utils'
import {setCoursePostPolicy as apiSetCoursePostPolicy} from '../PostPolicies/PostPolicyApi'
import type {StatusColors} from '../constants/colors'
import {
  createLatePolicy,
  fetchLatePolicy,
  updateCourseSettings,
  updateLatePolicy,
} from '../apis/GradebookSettingsModalApi'
import type {
  GradebookViewOptions,
  LatePolicyCamelized,
  LatePolicyValidationErrors,
  SortDirection,
} from '../gradebook.d'
import AdvancedTabPanel from './AdvancedTabPanel'
import GradePostingPolicyTabPanel from './GradePostingPolicyTabPanel'
import LatePoliciesTabPanel from './LatePoliciesTabPanel'
import ViewOptionsTabPanel from './ViewOptionsTabPanel'

const I18n = createI18nScope('gradebook')

type CourseSettings = {
  allowFinalGradeOverride: boolean
}

type CoursePostPolicy = {
  postManually: boolean
}

type ViewOptionsColumnSort = {
  criterion: string
  direction: SortDirection
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
  courseSettings: CourseSettings
  locale: string
  onRequestClose: () => void
  onAfterClose: () => void
  onEntered?: () => void
  gradebookIsEditable: boolean
  gradedLateSubmissionsExist: boolean
  loadCurrentViewOptions?: () => GradebookViewOptions
  onCourseSettingsUpdated: (courseSettings: {allowFinalGradeOverride: boolean}) => void
  onLatePolicyUpdate: (latePolicy: LatePolicyCamelized) => void
  onViewOptionsUpdated?: (viewOptions: GradebookViewOptions) => Promise<void>
  open: boolean
  postPolicies: {
    coursePostPolicy: CoursePostPolicy
    setAssignmentPostPolicies: (postManually: boolean) => void
    setCoursePostPolicy: (coursePostPolicy: {courseId?: string; postManually: boolean}) => void
  }
}

type LatePolicy = {
  changes: Partial<LatePolicyCamelized>
  data?: LatePolicyCamelized
  validationErrors: LatePolicyValidationErrors
}

function isLatePolicySaveable(latePolicy: LatePolicy) {
  return !isEmpty(latePolicy.changes) && isEmpty(latePolicy.validationErrors)
}

const GradebookSettingsModal = (props: GradebookSettingsModalProps) => {
  const [coursePostPolicy, setCoursePostPolicy] = useState<CoursePostPolicy>({
    postManually: !!props.postPolicies?.coursePostPolicy.postManually,
  })
  const [courseSettings, setCourseSettings] = useState<CourseSettings>({
    allowFinalGradeOverride: props.courseSettings.allowFinalGradeOverride,
  })
  const [latePolicy, setLatePolicy] = useState<LatePolicy>({changes: {}, validationErrors: {}})
  const [processingRequests, setProcessingRequests] = useState(false)
  const [selectedTab, setSelectedTab] = useState<string | undefined>('tab-panel-late')
  const [viewOptions, setViewOptions] = useState<GradebookViewOptions | null>(
    props.loadCurrentViewOptions?.() || null,
  )
  const [viewOptionsLastSaved, setViewOptionsLastSaved] = useState<GradebookViewOptions | null>(
    props.loadCurrentViewOptions?.() || null,
  )

  const includeAdvancedTab = props.courseFeatures.finalGradeOverrideEnabled

  const fetchCourseLatePolicy = () => {
    fetchLatePolicy(props.courseId)
      .then(response => setLatePolicy({...latePolicy, data: response.data.latePolicy}))
      .catch(() => {
        showFlashAlert({
          message: I18n.t('An error occurred while loading late policies'),
          type: 'error',
          err: null,
        })
      })
  }

  const resetToSavedState = () => {
    setCoursePostPolicy(props.postPolicies ? props.postPolicies.coursePostPolicy : coursePostPolicy)
    setLatePolicy({changes: {}, data: undefined, validationErrors: {}})
    setViewOptions(props.loadCurrentViewOptions?.() || null)
    setViewOptionsLastSaved(props.loadCurrentViewOptions?.() || null)
    setCourseSettings({
      allowFinalGradeOverride: props.courseSettings.allowFinalGradeOverride,
    })
  }

  const handleAfterClose = () => {
    resetToSavedState()
    props.onAfterClose()
  }

  const saveCourseLatePolicy = () => {
    if (!latePolicy.data) {
      throw new Error('latePolicy.data is required to save late policy')
    }

    const createOrUpdate = latePolicy.data.newRecord ? createLatePolicy : updateLatePolicy

    return createOrUpdate(props.courseId, latePolicy.changes)
      .then(() => {
        // can be cast because latePolicy.data exists
        const newLatePolicy = {
          ...(latePolicy.data || {}),
          ...latePolicy.changes,
        } as LatePolicyCamelized
        return props.onLatePolicyUpdate(newLatePolicy)
      })
      .catch(() => {
        const message = I18n.t('An error occurred while updating late policies')
        showFlashAlert({message, type: 'error', err: null})
        throw new Error(message)
      })
  }

  const savePostPolicy = () =>
    apiSetCoursePostPolicy({
      courseId: props.courseId,
      postManually: coursePostPolicy.postManually,
    })
      .then((postPolicy: {postManually: boolean}) => {
        props.postPolicies.setCoursePostPolicy({postManually: postPolicy.postManually})
        props.postPolicies.setAssignmentPostPolicies(postPolicy.postManually)
      })
      .catch(() => {
        const message = I18n.t('An error occurred while saving the course post policy')
        showFlashAlert({err: null, message, type: 'error'})
        throw new Error(message)
      })

  const saveViewOptions = () => {
    // This check can be removed when the "Enhanced Gradebook Filters" feature flag is removed
    if (!props.onViewOptionsUpdated || viewOptions === null) {
      throw new Error('onViewOptionsUpdated is required to save view options')
    }

    const savedOptions: GradebookViewOptions = cloneDeep(viewOptions)
    return props
      .onViewOptionsUpdated(savedOptions)
      .then(() => {
        setViewOptionsLastSaved(savedOptions)
      })
      .catch(() => {
        const message = I18n.t('An error occurred while updating view options')
        showFlashAlert({err: null, message, type: 'error'})
        throw new Error(message)
      })
  }

  const saveCourseSettings = () => {
    return updateCourseSettings(props.courseId, courseSettings)
      .then(response => {
        props.onCourseSettingsUpdated(response.data)
      })
      .catch(() => {
        const message = I18n.t('An error occurred while saving your settings')
        showFlashAlert({err: null, message, type: 'error'})
        throw new Error(message)
      })
  }

  const haveCourseSettingsChanged = () =>
    courseSettings.allowFinalGradeOverride !== props.courseSettings.allowFinalGradeOverride

  const haveViewOptionsChanged = () =>
    viewOptions != null && !isEqual(viewOptions, viewOptionsLastSaved)

  const isPostPolicyChanged = () => {
    if (props.postPolicies == null) {
      return false
    }

    const {postManually: oldPostManually} = props.postPolicies.coursePostPolicy
    const {postManually: newPostManually} = coursePostPolicy

    return oldPostManually !== newPostManually
  }

  const isUpdateButtonEnabled = () => {
    if (processingRequests) return false

    return (
      haveCourseSettingsChanged() ||
      isLatePolicySaveable(latePolicy) ||
      isPostPolicyChanged() ||
      haveViewOptionsChanged()
    )
  }

  const handleUpdateButtonClicked = () => {
    setProcessingRequests(true)

    const promises: Promise<void>[] = []
    if (isLatePolicySaveable(latePolicy)) {
      promises.push(saveCourseLatePolicy())
    }
    if (haveCourseSettingsChanged()) {
      promises.push(saveCourseSettings())
    }
    if (isPostPolicyChanged()) {
      promises.push(savePostPolicy())
    }
    if (haveViewOptionsChanged()) {
      promises.push(saveViewOptions())
    }

    // can't use finally() to remove the duplication because we need to
    // skip onUpdateSuccess if an earlier promise rejected and removing the
    // last catch will mean these rejected promises are uncaught, which
    // causes `Uncaught (in promise) Error` to be logged in the console
    Promise.all(promises)
      .then(() => {
        const message = I18n.t('Gradebook Settings updated')
        showFlashAlert({err: null, message, type: 'success'})
        props.onRequestClose()
      })
      .then(() => setProcessingRequests(false))
      .catch(() => setProcessingRequests(false))
  }

  return (
    <Tray
      label={I18n.t('Gradebook Settings')}
      onEnter={fetchCourseLatePolicy}
      onEntered={props.onEntered}
      onDismiss={props.onRequestClose}
      onExited={handleAfterClose}
      open={props.open}
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
                onClick={props.onRequestClose}
                screenReaderLabel={I18n.t('Close')}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item shouldGrow={true} shouldShrink={true} overflowX="hidden">
          <Tabs onRequestTabChange={(_ev, {id}) => setSelectedTab(id)}>
            <Tabs.Panel
              renderTitle={I18n.t('Late Policies')}
              id="tab-panel-late"
              isSelected={selectedTab === 'tab-panel-late'}
            >
              <LatePoliciesTabPanel
                latePolicy={latePolicy}
                changeLatePolicy={setLatePolicy}
                locale={props.locale}
                showAlert={props.gradedLateSubmissionsExist}
                gradebookIsEditable={props.gradebookIsEditable}
              />
            </Tabs.Panel>

            {props.postPolicies != null && (
              <Tabs.Panel
                renderTitle={I18n.t('Grade Posting Policy')}
                id="tab-panel-post"
                isSelected={selectedTab === 'tab-panel-post'}
              >
                <GradePostingPolicyTabPanel
                  anonymousAssignmentsPresent={props.anonymousAssignmentsPresent}
                  onChange={setCoursePostPolicy}
                  settings={coursePostPolicy}
                  gradebookIsEditable={props.gradebookIsEditable}
                />
              </Tabs.Panel>
            )}

            {includeAdvancedTab && (
              <Tabs.Panel
                renderTitle={I18n.t('Advanced')}
                id="tab-panel-advanced"
                isSelected={selectedTab === 'tab-panel-advanced'}
              >
                <AdvancedTabPanel
                  courseSettings={courseSettings}
                  onCourseSettingsChange={setCourseSettings}
                />
              </Tabs.Panel>
            )}

            {!!props.loadCurrentViewOptions && !!viewOptions && (
              <Tabs.Panel
                renderTitle={I18n.t('View Options')}
                id="tab-panel-view-options"
                isSelected={selectedTab === 'tab-panel-view-options'}
              >
                <ViewOptionsTabPanel
                  columnSort={{
                    currentValue: viewOptions.columnSortSettings,
                    modulesEnabled: Boolean(props.allowSortingByModules),
                    onChange: ({criterion, direction}: ViewOptionsColumnSort) => {
                      setViewOptions({...viewOptions, columnSortSettings: {criterion, direction}})
                    },
                  }}
                  finalGradeOverrideEnabled={props.courseFeatures.finalGradeOverrideEnabled}
                  statusColors={{
                    currentValues: viewOptions.statusColors as StatusColors,
                    onChange: (colors: StatusColors) => {
                      setViewOptions({...viewOptions, statusColors: colors})
                    },
                  }}
                  showNotes={{
                    checked: viewOptions.showNotes,
                    onChange: (value: GradebookViewOptions['showNotes']) => {
                      setViewOptions({...viewOptions, showNotes: value})
                    },
                  }}
                  showUnpublishedAssignments={{
                    checked: viewOptions.showUnpublishedAssignments,
                    onChange: (value: GradebookViewOptions['showUnpublishedAssignments']) => {
                      setViewOptions({...viewOptions, showUnpublishedAssignments: value})
                    },
                  }}
                  showSeparateFirstLastNames={{
                    allowed: Boolean(props.allowShowSeparateFirstLastNames),
                    checked: viewOptions.showSeparateFirstLastNames,
                    onChange: (value: GradebookViewOptions['showSeparateFirstLastNames']) => {
                      setViewOptions({...viewOptions, showSeparateFirstLastNames: value})
                    },
                  }}
                  hideAssignmentGroupTotals={{
                    checked: viewOptions.hideAssignmentGroupTotals,
                    onChange: (value: GradebookViewOptions['hideAssignmentGroupTotals']) => {
                      setViewOptions({...viewOptions, hideAssignmentGroupTotals: value})
                    },
                  }}
                  hideTotal={{
                    checked: viewOptions.hideTotal,
                    onChange: (value: GradebookViewOptions['hideTotal']) => {
                      setViewOptions({...viewOptions, hideTotal: value})
                    },
                  }}
                  viewUngradedAsZero={{
                    allowed: Boolean(props.allowViewUngradedAsZero),
                    checked: viewOptions.viewUngradedAsZero,
                    onChange: (newValue: GradebookViewOptions['viewUngradedAsZero']) => {
                      confirmViewUngradedAsZero({
                        currentValue: viewOptions.viewUngradedAsZero,
                        onAccepted: () => {
                          setViewOptions({...viewOptions, viewUngradedAsZero: newValue})
                        },
                      })
                    },
                  }}
                />
              </Tabs.Panel>
            )}
          </Tabs>
        </Flex.Item>
        <Flex.Item id="gradebook-settings-modal-footer" align="end" as="footer" overflowY="hidden">
          <Button
            id="gradebook-settings-cancel-button"
            onClick={props.onRequestClose}
            margin="0 small"
          >
            {I18n.t('Cancel')}
          </Button>

          <Button
            id="gradebook-settings-update-button"
            data-testid="gradebook-settings-update-button"
            onClick={handleUpdateButtonClicked}
            disabled={!isUpdateButtonEnabled()}
            color="primary"
          >
            {I18n.t('Apply Settings')}
          </Button>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

export default GradebookSettingsModal
