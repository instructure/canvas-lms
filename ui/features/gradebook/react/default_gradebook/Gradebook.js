/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import $ from 'jquery'
import _ from 'underscore'
import tz from '@canvas/timezone'
import React from 'react'
import ReactDOM from 'react-dom'

import LongTextEditor from '../../jquery/slickgrid.long_text_editor'
import KeyboardNavDialog from '@canvas/keyboard-nav-dialog'
import KeyboardNavTemplate from '@canvas/keyboard-nav-dialog/jst/KeyboardNavDialog.handlebars'
import GradingPeriodSetsApi from '@canvas/grading/jquery/gradingPeriodSetsApi'
import InputFilterView from 'backbone-input-filter-view'
import I18n from 'i18n!gradebook'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import * as EffectiveDueDates from '@canvas/grading/EffectiveDueDates'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import UserSettings from '@canvas/user-settings'
import Spinner from 'spin.js'
import GradeDisplayWarningDialog from '../../jquery/GradeDisplayWarningDialog.coffee'
import PostGradesFrameDialog from '../../jquery/PostGradesFrameDialog'
import NumberCompare from '../../util/NumberCompare'
import natcompare from '@canvas/util/natcompare'
import {camelize, underscore} from 'convert-case'
import htmlEscape from 'html-escape'
import * as EnterGradesAsSetting from '../shared/EnterGradesAsSetting'
import SetDefaultGradeDialogManager from '../shared/SetDefaultGradeDialogManager'
import AsyncComponents from './AsyncComponents'
import CurveGradesDialogManager from './CurveGradesDialogManager'
import GradebookApi from './apis/GradebookApi'
import SubmissionCommentApi from './apis/SubmissionCommentApi'
import CourseSettings from './CourseSettings/index'
import DataLoader from './DataLoader/index'
import OldDataLoader from './OldDataLoader/index'
import FinalGradeOverrides from './FinalGradeOverrides/index'
import GradebookGrid from './GradebookGrid/index'
import AssignmentRowCellPropFactory from './GradebookGrid/editors/AssignmentCellEditor/AssignmentRowCellPropFactory'
import TotalGradeOverrideCellPropFactory from './GradebookGrid/editors/TotalGradeOverrideCellEditor/TotalGradeOverrideCellPropFactory'
import PerformanceControls from './PerformanceControls'
import PostPolicies from './PostPolicies/index'
import GradebookMenu from '@canvas/gradebook-menu'
import ViewOptionsMenu from './components/ViewOptionsMenu'
import ActionMenu from './components/ActionMenu'
import AssignmentGroupFilter from './components/content-filters/AssignmentGroupFilter'
import GradingPeriodFilter from './components/content-filters/GradingPeriodFilter'
import ModuleFilter from './components/content-filters/ModuleFilter'
import SectionFilter from '@canvas/gradebook-content-filters/react/SectionFilter'
import StudentGroupFilter from './components/content-filters/StudentGroupFilter'
import GridColor from './components/GridColor'
import StatusesModal from './components/StatusesModal'
import AnonymousSpeedGraderAlert from './components/AnonymousSpeedGraderAlert'
import {statusColors} from './constants/colors'
import StudentDatastore from './stores/StudentDatastore'
import PostGradesStore from '../SISGradePassback/PostGradesStore'
import SubmissionStateMap from '@canvas/grading/SubmissionStateMap'
import DownloadSubmissionsDialogManager from '../shared/DownloadSubmissionsDialogManager'
import ReuploadSubmissionsDialogManager from '../shared/ReuploadSubmissionsDialogManager'
import GradebookKeyboardNav from '../../jquery/GradebookKeyboardNav'
import assignmentHelper from '../shared/helpers/assignmentHelper'
import TextMeasure from '../shared/helpers/TextMeasure'
import * as GradeInputHelper from '@canvas/grading/GradeInputHelper'
import OutlierScoreHelper from '@canvas/grading/OutlierScoreHelper'
import {isPostable} from '@canvas/grading/SubmissionHelper'
import LatePolicyApplicator from '../LatePolicyApplicator'
import {Button} from '@instructure/ui-buttons'
import {IconSettingsSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {deferPromise} from 'defer-promise'
import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/datetime'
import 'jqueryui/dialog'
import 'jqueryui/tooltip'
import '../../../../boot/initializers/activateTooltips.js'
import '../../../../boot/initializers/activateKeyClicks.js'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import 'jquery-tinypubsub'
import 'jqueryui/position'
import '@canvas/util/jquery/fixDialogButtons'

import {
  compareAssignmentDueDates,
  ensureAssignmentVisibility,
  forEachSubmission,
  getAssignmentGroupPointsPossible,
  getCourseFeaturesFromOptions,
  getCourseFromOptions,
  getGradeAsPercent,
  getStudentGradeForColumn,
  htmlDecode,
  isAdmin,
  onGridKeyDown,
  renderComponent
} from './Gradebook.utils'

import {
  getInitialGradebookContent,
  getInitialGridDisplaySettings,
  getInitialCourseContent,
  getInitialContentLoadStates,
  getInitialActionStates,
  columnWidths
} from './initialState'

const indexOf = [].indexOf

const ASSIGNMENT_KEY_REGEX = /^assignment_(?!group)/

const HEADER_START_AND_END_WIDTHS_IN_PIXELS = 36
const testWidth = function (text, minWidth, maxWidth) {
  const padding = HEADER_START_AND_END_WIDTHS_IN_PIXELS * 2
  const width = Math.max(TextMeasure.getWidth(text) + padding, minWidth)
  return Math.min(width, maxWidth)
}
const anonymousSpeedGraderAlertMountPoint = function () {
  return document.querySelector("[data-component='AnonymousSpeedGraderAlert']")
}

class Gradebook {
  constructor(options1) {
    this.setInitialState = this.setInitialState.bind(this)
    this.bindGridEvents = this.bindGridEvents.bind(this)
    this.addOverridesToPostGradesStore = this.addOverridesToPostGradesStore.bind(this)
    this.gotCustomColumns = this.gotCustomColumns.bind(this)
    this.gotCustomColumnDataChunk = this.gotCustomColumnDataChunk.bind(this)
    // Assignment Group Data & Lifecycle Methods
    this.updateAssignmentGroups = this.updateAssignmentGroups.bind(this)
    this.gotAllAssignmentGroups = this.gotAllAssignmentGroups.bind(this)

    // Grading Period Assignment Data & Lifecycle Methods
    this.assignmentsLoadedForCurrentView = this.assignmentsLoadedForCurrentView.bind(this)
    this.updateGradingPeriodAssignments = this.updateGradingPeriodAssignments.bind(this)
    this.gotGradingPeriodAssignments = this.gotGradingPeriodAssignments.bind(this)
    this.gotSections = this.gotSections.bind(this)
    this.gotChunkOfStudents = this.gotChunkOfStudents.bind(this)

    // # Post-Data Load Initialization
    this.finishRenderingUI = this.finishRenderingUI.bind(this)
    this.setupGrading = this.setupGrading.bind(this)
    this.resetGrading = this.resetGrading.bind(this)
    this.getSubmission = this.getSubmission.bind(this)
    this.updateEffectiveDueDatesFromSubmissions = this.updateEffectiveDueDatesFromSubmissions.bind(
      this
    )

    // Student Data & Lifecycle Methods
    this.updateStudentIds = this.updateStudentIds.bind(this)
    this.updateStudentsLoaded = this.updateStudentsLoaded.bind(this)
    this.isInvalidSort = this.isInvalidSort.bind(this)
    this.isDefaultSortOrder = this.isDefaultSortOrder.bind(this)
    this.getColumnOrder = this.getColumnOrder.bind(this)
    this.saveCustomColumnOrder = this.saveCustomColumnOrder.bind(this)
    this.arrangeColumnsBy = this.arrangeColumnsBy.bind(this)
    this.makeColumnSortFn = this.makeColumnSortFn.bind(this)
    this.compareAssignmentModulePositions = this.compareAssignmentModulePositions.bind(this)
    this.compareAssignmentNames = this.compareAssignmentNames.bind(this)
    this.makeCompareAssignmentCustomOrderFn = this.makeCompareAssignmentCustomOrderFn.bind(this)

    // # Filtering
    this.rowFilter = this.rowFilter.bind(this)
    this.filterAssignments = this.filterAssignments.bind(this)
    this.filterAssignmentBySubmissionTypes = this.filterAssignmentBySubmissionTypes.bind(this)
    this.filterAssignmentByPublishedStatus = this.filterAssignmentByPublishedStatus.bind(this)
    this.filterAssignmentByAssignmentGroup = this.filterAssignmentByAssignmentGroup.bind(this)
    this.filterAssignmentByGradingPeriod = this.filterAssignmentByGradingPeriod.bind(this)
    this.filterAssignmentByModule = this.filterAssignmentByModule.bind(this)

    // # Course Content Event Handlers
    this.handleSubmissionPostedChange = this.handleSubmissionPostedChange.bind(this)
    this.handleSubmissionsDownloading = this.handleSubmissionsDownloading.bind(this)

    // filter, sort, and build the dataset for slickgrid to read from, then
    // force a full redraw
    this.buildRows = this.buildRows.bind(this)
    this.buildRow = this.buildRow.bind(this)

    // Submission Data & Lifecycle Methods
    this.updateSubmissionsLoaded = this.updateSubmissionsLoaded.bind(this)
    this.gotSubmissionsChunk = this.gotSubmissionsChunk.bind(this)
    this.student = this.student.bind(this)
    this.updateSubmission = this.updateSubmission.bind(this)
    // this is used after the CurveGradesDialog submit xhr comes back.  it does not use the api
    // because there is no *bulk* submissions#update endpoint in the api.
    // It is different from gotSubmissionsChunk in that gotSubmissionsChunk expects an array of students
    // where each student has an array of submissions.  This one just expects an array of submissions,
    // they are not grouped by student.
    this.updateSubmissionsFromExternal = this.updateSubmissionsFromExternal.bind(this)
    this.submissionsForStudent = this.submissionsForStudent.bind(this)
    this.calculateStudentGrade = this.calculateStudentGrade.bind(this)
    this.getStudentGrades = this.getStudentGrades.bind(this)
    // SlickGrid doesn't have a blur event for the grid, so this mimics it in
    // conjunction with a click listener on <body />. When we 'blur' the grid
    // by clicking outside of it, save the current field.
    this.onGridBlur = this.onGridBlur.bind(this)
    this.updateCurrentSection = this.updateCurrentSection.bind(this)
    this.getStudentGroupToShow = this.getStudentGroupToShow.bind(this)
    this.updateCurrentStudentGroup = this.updateCurrentStudentGroup.bind(this)
    this.updateCurrentAssignmentGroup = this.updateCurrentAssignmentGroup.bind(this)
    this.updateCurrentGradingPeriod = this.updateCurrentGradingPeriod.bind(this)
    this.updateCurrentModule = this.updateCurrentModule.bind(this)
    this.initSubmissionStateMap = this.initSubmissionStateMap.bind(this)
    this.delayedCall = this.delayedCall.bind(this)
    this.initPostGradesLtis = this.initPostGradesLtis.bind(this)
    this.updatePostGradesFeatureButton = this.updatePostGradesFeatureButton.bind(this)
    this.initHeader = this.initHeader.bind(this)
    this.renderGradebookMenus = this.renderGradebookMenus.bind(this)
    this.renderGradebookMenu = this.renderGradebookMenu.bind(this)
    this.getFilterSettingsViewOptionsMenuProps = this.getFilterSettingsViewOptionsMenuProps.bind(
      this
    )
    this.updateFilterSettings = this.updateFilterSettings.bind(this)
    this.renderViewOptionsMenu = this.renderViewOptionsMenu.bind(this)
    this.getActionMenuProps = this.getActionMenuProps.bind(this)
    this.renderActionMenu = this.renderActionMenu.bind(this)
    this.renderFilters = this.renderFilters.bind(this)
    this.renderGridColor = this.renderGridColor.bind(this)
    this.renderGradebookSettingsModal = this.renderGradebookSettingsModal.bind(this)
    this.renderSettingsButton = this.renderSettingsButton.bind(this)
    this.renderStatusesModal = this.renderStatusesModal.bind(this)
    this.weightedGroups = this.weightedGroups.bind(this)
    this.weightedGrades = this.weightedGrades.bind(this)
    this.switchTotalDisplay = this.switchTotalDisplay.bind(this)
    this.togglePointsOrPercentTotals = this.togglePointsOrPercentTotals.bind(this)
    this.onUserFilterInput = this.onUserFilterInput.bind(this)
    this.renderSearchFilter = this.renderSearchFilter.bind(this)
    // Custom Column
    this.buildCustomColumn = this.buildCustomColumn.bind(this)
    this.initGrid = this.initGrid.bind(this)
    this.createGrid = this.createGrid.bind(this)
    // # Grid Body Event Handlers

    // The target cell will enter editing mode
    this.onBeforeEditCell = this.onBeforeEditCell.bind(this)
    // The current cell editor has been changed and is valid
    this.onCellChange = this.onCellChange.bind(this)
    this.saveSettings = this.saveSettings.bind(this)
    this.getColumnTypeForColumnId = this.getColumnTypeForColumnId.bind(this)
    this.secondaryAndTertiarySort = this.secondaryAndTertiarySort.bind(this)
    this.gradeSort = this.gradeSort.bind(this)
    this.missingSort = this.missingSort.bind(this)
    this.lateSort = this.lateSort.bind(this)
    this.setCurrentGradingPeriod = this.setCurrentGradingPeriod.bind(this)
    this.sortByStudentColumn = this.sortByStudentColumn.bind(this)
    this.sortByCustomColumn = this.sortByCustomColumn.bind(this)
    this.sortByAssignmentColumn = this.sortByAssignmentColumn.bind(this)
    // when 'unposted' # TODO: in a future milestone, unposted will be added
    this.sortByAssignmentGroupColumn = this.sortByAssignmentGroupColumn.bind(this)
    this.sortByTotalGradeColumn = this.sortByTotalGradeColumn.bind(this)
    this.sortGridRows = this.sortGridRows.bind(this)
    // Grid Update Methods
    this.updateStudentRow = this.updateStudentRow.bind(this)
    // Filtered Content Information Methods
    this.updateFilteredContentInfo = this.updateFilteredContentInfo.bind(this)
    this.listInvalidAssignmentGroups = this.listInvalidAssignmentGroups.bind(this)
    this.listHiddenAssignments = this.listHiddenAssignments.bind(this)
    this.getTotalPointsPossible = this.getTotalPointsPossible.bind(this)
    this.handleColumnHeaderMenuClose = this.handleColumnHeaderMenuClose.bind(this)
    this.toggleNotesColumn = this.toggleNotesColumn.bind(this)
    this.showNotesColumn = this.showNotesColumn.bind(this)
    this.hideNotesColumn = this.hideNotesColumn.bind(this)
    // # Grid DOM Access/Reference Methods
    this.addAssignmentColumnDefinition = this.addAssignmentColumnDefinition.bind(this)
    this.getCustomColumnId = this.getCustomColumnId.bind(this)
    this.getAssignmentColumnId = this.getAssignmentColumnId.bind(this)
    this.getAssignmentGroupColumnId = this.getAssignmentGroupColumnId.bind(this)
    // # SlickGrid Data Access Methods
    this.listRows = this.listRows.bind(this)
    this.listRowIndicesForStudentIds = this.listRowIndicesForStudentIds.bind(this)
    // # SlickGrid Update Methods
    this.updateRowCellsForStudentIds = this.updateRowCellsForStudentIds.bind(this)
    this.invalidateRowsForStudentIds = this.invalidateRowsForStudentIds.bind(this)
    this.updateTotalGradeColumn = this.updateTotalGradeColumn.bind(this)
    this.updateAllTotalColumns = this.updateAllTotalColumns.bind(this)
    this.updateColumnWithId = this.updateColumnWithId.bind(this)

    // # Gradebook Bulk UI Update Methods
    this.updateColumns = this.updateColumns.bind(this)
    this.updateColumnsAndRenderViewOptionsMenu = this.updateColumnsAndRenderViewOptionsMenu.bind(
      this
    )
    this.updateColumnsAndRenderGradebookSettingsModal = this.updateColumnsAndRenderGradebookSettingsModal.bind(
      this
    )
    // # React Header Component Ref Methods
    this.setHeaderComponentRef = this.setHeaderComponentRef.bind(this)
    this.getHeaderComponentRef = this.getHeaderComponentRef.bind(this)
    this.removeHeaderComponentRef = this.removeHeaderComponentRef.bind(this)
    // # React Grid Component Rendering Methods
    this.updateColumnHeaders = this.updateColumnHeaders.bind(this)
    // Column Header Helpers
    this.handleHeaderKeyDown = this.handleHeaderKeyDown.bind(this)
    // Total Grade Column Header
    this.freezeTotalGradeColumn = this.freezeTotalGradeColumn.bind(this)
    this.moveTotalGradeColumnToEnd = this.moveTotalGradeColumnToEnd.bind(this)
    // Submission Tray
    this.assignmentColumns = this.assignmentColumns.bind(this)
    this.navigateAssignment = this.navigateAssignment.bind(this)
    this.loadTrayStudent = this.loadTrayStudent.bind(this)
    this.loadTrayAssignment = this.loadTrayAssignment.bind(this)
    this.getSubmissionTrayProps = this.getSubmissionTrayProps.bind(this)
    this.renderSubmissionTray = this.renderSubmissionTray.bind(this)
    this.loadSubmissionComments = this.loadSubmissionComments.bind(this)
    this.updateRowAndRenderSubmissionTray = this.updateRowAndRenderSubmissionTray.bind(this)
    this.toggleSubmissionTrayOpen = this.toggleSubmissionTrayOpen.bind(this)
    this.openSubmissionTray = this.openSubmissionTray.bind(this)
    this.closeSubmissionTray = this.closeSubmissionTray.bind(this)
    this.getSubmissionTrayState = this.getSubmissionTrayState.bind(this)
    this.setSubmissionTrayState = this.setSubmissionTrayState.bind(this)
    this.setCommentsUpdating = this.setCommentsUpdating.bind(this)
    this.getCommentsUpdating = this.getCommentsUpdating.bind(this)
    this.setSubmissionComments = this.setSubmissionComments.bind(this)
    this.updateSubmissionComments = this.updateSubmissionComments.bind(this)
    this.unloadSubmissionComments = this.unloadSubmissionComments.bind(this)
    this.apiCreateSubmissionComment = this.apiCreateSubmissionComment.bind(this)
    this.apiUpdateSubmissionComment = this.apiUpdateSubmissionComment.bind(this)
    this.apiDeleteSubmissionComment = this.apiDeleteSubmissionComment.bind(this)
    this.editSubmissionComment = this.editSubmissionComment.bind(this)
    this.setEditedCommentId = this.setEditedCommentId.bind(this)
    this.getSubmissionComments = this.getSubmissionComments.bind(this)
    this.removeSubmissionComment = this.removeSubmissionComment.bind(this)
    this.setSubmissionCommentsLoaded = this.setSubmissionCommentsLoaded.bind(this)
    this.getSubmissionCommentsLoaded = this.getSubmissionCommentsLoaded.bind(this)
    // # Gradebook Application State Methods
    this.initShowUnpublishedAssignments = this.initShowUnpublishedAssignments.bind(this)
    this.toggleUnpublishedAssignments = this.toggleUnpublishedAssignments.bind(this)
    this.toggleViewUngradedAsZero = this.toggleViewUngradedAsZero.bind(this)
    this.confirmViewUngradedAsZero = this.confirmViewUngradedAsZero.bind(this)
    this.setAssignmentsLoaded = this.setAssignmentsLoaded.bind(this)
    this.setAssignmentGroupsLoaded = this.setAssignmentGroupsLoaded.bind(this)
    this.setContextModulesLoaded = this.setContextModulesLoaded.bind(this)
    this.setCustomColumnsLoaded = this.setCustomColumnsLoaded.bind(this)
    this.setGradingPeriodAssignmentsLoaded = this.setGradingPeriodAssignmentsLoaded.bind(this)
    this.setStudentIdsLoaded = this.setStudentIdsLoaded.bind(this)
    this.setStudentsLoaded = this.setStudentsLoaded.bind(this)
    this.setSubmissionsLoaded = this.setSubmissionsLoaded.bind(this)
    this.isGradeEditable = this.isGradeEditable.bind(this)
    this.isGradeVisible = this.isGradeVisible.bind(this)
    this.isStudentGradeable = this.isStudentGradeable.bind(this)
    this.studentCanReceiveGradeOverride = this.studentCanReceiveGradeOverride.bind(this)
    this.studentHasGradedSubmission = this.studentHasGradedSubmission.bind(this)
    this.addPendingGradeInfo = this.addPendingGradeInfo.bind(this)
    this.removePendingGradeInfo = this.removePendingGradeInfo.bind(this)
    this.getPendingGradeInfo = this.getPendingGradeInfo.bind(this)
    this.setTeacherNotesColumnUpdating = this.setTeacherNotesColumnUpdating.bind(this)
    this.setOverridesColumnUpdating = this.setOverridesColumnUpdating.bind(this)
    // # Grid Display Settings Access Methods
    this.getFilterColumnsBySetting = this.getFilterColumnsBySetting.bind(this)
    this.setFilterColumnsBySetting = this.setFilterColumnsBySetting.bind(this)
    this.getFilterRowsBySetting = this.getFilterRowsBySetting.bind(this)
    this.setFilterRowsBySetting = this.setFilterRowsBySetting.bind(this)
    this.isFilteringColumnsByAssignmentGroup = this.isFilteringColumnsByAssignmentGroup.bind(this)
    this.getAssignmentGroupToShow = this.getAssignmentGroupToShow.bind(this)
    this.getModuleToShow = this.getModuleToShow.bind(this)
    this.isFilteringColumnsByGradingPeriod = this.isFilteringColumnsByGradingPeriod.bind(this)
    this.isFilteringRowsBySearchTerm = this.isFilteringRowsBySearchTerm.bind(this)
    this.getGradingPeriodAssignments = this.getGradingPeriodAssignments.bind(this)
    this.getGradingPeriod = this.getGradingPeriod.bind(this)
    this.setSelectedPrimaryInfo = this.setSelectedPrimaryInfo.bind(this)
    this.toggleDefaultSort = this.toggleDefaultSort.bind(this)
    this.getDefaultSettingKeyForColumnType = this.getDefaultSettingKeyForColumnType.bind(this)
    this.getSelectedPrimaryInfo = this.getSelectedPrimaryInfo.bind(this)
    this.setSelectedSecondaryInfo = this.setSelectedSecondaryInfo.bind(this)
    this.getSelectedSecondaryInfo = this.getSelectedSecondaryInfo.bind(this)
    this.setSortRowsBySetting = this.setSortRowsBySetting.bind(this)
    this.getSortRowsBySetting = this.getSortRowsBySetting.bind(this)
    this.updateGridColors = this.updateGridColors.bind(this)
    this.setGridColors = this.setGridColors.bind(this)
    this.getGridColors = this.getGridColors.bind(this)
    this.listAvailableViewOptionsFilters = this.listAvailableViewOptionsFilters.bind(this)
    this.setSelectedViewOptionsFilters = this.setSelectedViewOptionsFilters.bind(this)
    this.listSelectedViewOptionsFilters = this.listSelectedViewOptionsFilters.bind(this)
    this.toggleEnrollmentFilter = this.toggleEnrollmentFilter.bind(this)
    this.updateStudentHeadersAndReloadData = this.updateStudentHeadersAndReloadData.bind(this)
    this.applyEnrollmentFilter = this.applyEnrollmentFilter.bind(this)
    this.getEnrollmentFilters = this.getEnrollmentFilters.bind(this)
    this.getSelectedEnrollmentFilters = this.getSelectedEnrollmentFilters.bind(this)
    this.setEnterGradesAsSetting = this.setEnterGradesAsSetting.bind(this)
    this.getEnterGradesAsSetting = this.getEnterGradesAsSetting.bind(this)
    this.updateEnterGradesAsSetting = this.updateEnterGradesAsSetting.bind(this)
    this.postAssignmentGradesTrayOpenChanged = this.postAssignmentGradesTrayOpenChanged.bind(this)
    // # Gradebook Content Access Methods
    this.getSections = this.getSections.bind(this)
    this.setSections = this.setSections.bind(this)
    this.setStudentGroups = this.setStudentGroups.bind(this)
    this.setAssignments = this.setAssignments.bind(this)
    this.setAssignmentGroups = this.setAssignmentGroups.bind(this)
    this.getAssignment = this.getAssignment.bind(this)
    this.getAssignmentGroup = this.getAssignmentGroup.bind(this)
    this.getCustomColumn = this.getCustomColumn.bind(this)
    this.getTeacherNotesColumn = this.getTeacherNotesColumn.bind(this)
    // Context Module Data & Lifecycle Methods
    this.updateContextModules = this.updateContextModules.bind(this)
    this.setContextModules = this.setContextModules.bind(this)
    this.onLatePolicyUpdate = this.onLatePolicyUpdate.bind(this)
    this.setLatePolicy = this.setLatePolicy.bind(this)
    this.applyLatePolicy = this.applyLatePolicy.bind(this)
    this.getContextModule = this.getContextModule.bind(this)
    this.listContextModules = this.listContextModules.bind(this)
    // # Assignment UI Action Methods
    this.getDownloadSubmissionsAction = this.getDownloadSubmissionsAction.bind(this)
    this.getReuploadSubmissionsAction = this.getReuploadSubmissionsAction.bind(this)
    this.getSetDefaultGradeAction = this.getSetDefaultGradeAction.bind(this)
    this.getCurveGradesAction = this.getCurveGradesAction.bind(this)
    // # Gradebook Content Api Methods
    this.createTeacherNotes = this.createTeacherNotes.bind(this)
    this.setTeacherNotesHidden = this.setTeacherNotesHidden.bind(this)
    this.apiUpdateSubmission = this.apiUpdateSubmission.bind(this)
    this.gradeSubmission = this.gradeSubmission.bind(this)
    this.updateSubmissionAndRenderSubmissionTray = this.updateSubmissionAndRenderSubmissionTray.bind(
      this
    )
    this.renderAnonymousSpeedGraderAlert = this.renderAnonymousSpeedGraderAlert.bind(this)
    this.showAnonymousSpeedGraderAlertForURL = this.showAnonymousSpeedGraderAlertForURL.bind(this)
    this.hideAnonymousSpeedGraderAlert = this.hideAnonymousSpeedGraderAlert.bind(this)
    this.requireStudentGroupForSpeedGrader = this.requireStudentGroupForSpeedGrader.bind(this)
    this.showSimilarityScore = this.showSimilarityScore.bind(this)
    this.viewUngradedAsZero = this.viewUngradedAsZero.bind(this)
    this.destroy = this.destroy.bind(this)
    // # "PRIVILEGED" methods

    // The methods here are intended to support specs, but not intended to be a
    // permanent part of the API for this class. The existence of these methods
    // suggests that the behavior they provide does not yet have a more suitable
    // home elsewhere in the code. They are prefixed with '_' to suggest this
    // aspect of their presence here.
    this._gridHasRendered = this._gridHasRendered.bind(this)
    this._updateEssentialDataLoaded = this._updateEssentialDataLoaded.bind(this)
    this.options = options1
    this.course = getCourseFromOptions(this.options)
    this.courseFeatures = getCourseFeaturesFromOptions(this.options)
    this.courseSettings = new CourseSettings(this, {
      allowFinalGradeOverride: this.options.course_settings.allow_final_grade_override
    })
    this.dataLoader = new DataLoader({
      gradebook: this,
      performanceControls: new PerformanceControls(camelize(this.options.performance_controls)),
      loadAssignmentsByGradingPeriod: this.options.load_assignments_by_grading_period_enabled
    })
    this.gridData = {
      columns: {
        definitions: {},
        frozen: [],
        scrollable: []
      },
      rows: []
    }
    this.gradebookGrid = new GradebookGrid({
      $container: document.getElementById('gradebook_grid'),
      activeBorderColor: '#1790DF', // $active-border-color
      data: this.gridData,
      editable: this.options.gradebook_is_editable,
      gradebook: this
    })
    if (this.courseFeatures.finalGradeOverrideEnabled) {
      this.finalGradeOverrides = new FinalGradeOverrides(this)
    } else {
      this.finalGradeOverrides = null
    }
    this.postPolicies = new PostPolicies(this)
    $.subscribe('assignment_muting_toggled', this.handleSubmissionPostedChange)
    $.subscribe('submissions_updated', this.updateSubmissionsFromExternal)
    // emitted by SectionMenuView; also subscribed in OutcomeGradebookView
    $.subscribe('currentSection/change', this.updateCurrentSection)
    // emitted by GradingPeriodMenuView
    $.subscribe('currentGradingPeriod/change', this.updateCurrentGradingPeriod)
    this.gridReady = $.Deferred()
    this._essentialDataLoaded = deferPromise()
    this.setInitialState()
    this.loadSettings()
    this.bindGridEvents()
  }

  setInitialState() {
    this.courseContent = getInitialCourseContent(this.options)
    this.gradebookContent = getInitialGradebookContent(this.options)
    this.gridDisplaySettings = getInitialGridDisplaySettings(
      this.options.settings,
      this.options.colors
    )
    this.contentLoadStates = getInitialContentLoadStates(this.options)
    this.actionStates = getInitialActionStates()
    this.headerComponentRefs = {}
    this.filteredContentInfo = {
      invalidAssignmentGroups: [],
      totalPointsPossible: 0
    }
    this.setAssignments({})
    this.setAssignmentGroups({})
    this.effectiveDueDates = {}
    this.students = {}
    this.studentViewStudents = {}
    this.courseContent.students = new StudentDatastore(this.students, this.studentViewStudents)
    this.calculatedGradesByStudentId = {}
    this.initPostGradesStore()
    this.initPostGradesLtis()
    return this.checkForUploadComplete()
  }

  loadSettings() {
    let ref1
    if (this.options.grading_period_set) {
      this.gradingPeriodSet = GradingPeriodSetsApi.deserializeSet(this.options.grading_period_set)
    } else {
      this.gradingPeriodSet = null
    }
    this.setCurrentGradingPeriod()
    this.show_attendance = !!UserSettings.contextGet('show_attendance')
    // preferences serialization causes these to always come
    // from the database as strings
    if (
      this.options.course_is_concluded ||
      this.options.settings.show_concluded_enrollments === 'true'
    ) {
      this.toggleEnrollmentFilter('concluded', true)
    }
    if (this.options.settings.show_inactive_enrollments === 'true') {
      this.toggleEnrollmentFilter('inactive', true)
    }
    this.initShowUnpublishedAssignments(this.options.settings.show_unpublished_assignments)
    this.initSubmissionStateMap()
    this.gradebookColumnSizeSettings = this.options.gradebook_column_size_settings
    this.setColumnOrder({
      ...this.options.gradebook_column_order_settings,
      freezeTotalGrade:
        ((ref1 = this.options.gradebook_column_order_settings) != null
          ? ref1.freezeTotalGrade
          : undefined) === 'true'
    })
    this.teacherNotesNotYetLoaded =
      this.getTeacherNotesColumn() == null || this.getTeacherNotesColumn().hidden
    this.gotSections(this.options.sections)
    this.hasSections.then(() => {
      if (!this.getSelectedSecondaryInfo()) {
        if (this.sections_enabled) {
          return (this.gridDisplaySettings.selectedSecondaryInfo = 'section')
        } else {
          return (this.gridDisplaySettings.selectedSecondaryInfo = 'none')
        }
      }
    })
    return this.setStudentGroups(this.options.student_groups)
  }

  bindGridEvents() {
    this.gradebookGrid.events.onColumnsReordered.subscribe((_event, columns) => {
      let column, currentCustomColumnIds, currentFrozenColumns, updatedCustomColumnIds
      // determine if assignment columns or custom columns were reordered
      // (this works because frozen columns and non-frozen columns are can't be
      // swapped)
      const currentFrozenIds = this.gridData.columns.frozen
      const updatedFrozenIds = columns.frozen.map(column => {
        return column.id
      })
      this.gridData.columns.frozen = updatedFrozenIds
      this.gridData.columns.scrollable = columns.scrollable.map(function (column) {
        return column.id
      })
      if (!_.isEqual(currentFrozenIds, updatedFrozenIds)) {
        currentFrozenColumns = currentFrozenIds.map(columnId => {
          return this.gridData.columns.definitions[columnId]
        })
        currentCustomColumnIds = (function () {
          let j, len
          const results = []
          for (j = 0, len = currentFrozenColumns.length; j < len; j++) {
            column = currentFrozenColumns[j]
            if (column.type === 'custom_column') {
              results.push(column.customColumnId)
            }
          }
          return results
        })()
        updatedCustomColumnIds = (function () {
          let j, len
          const ref1 = columns.frozen
          const results = []
          for (j = 0, len = ref1.length; j < len; j++) {
            column = ref1[j]
            if (column.type === 'custom_column') {
              results.push(column.customColumnId)
            }
          }
          return results
        })()
        if (!_.isEqual(currentCustomColumnIds, updatedCustomColumnIds)) {
          this.reorderCustomColumns(updatedCustomColumnIds).then(() => {
            const colsById = _(this.gradebookContent.customColumns).indexBy(function (c) {
              return c.id
            })
            return (this.gradebookContent.customColumns = _(updatedCustomColumnIds).map(function (
              id
            ) {
              return colsById[id]
            }))
          })
        }
      } else {
        this.saveCustomColumnOrder()
      }
      this.renderViewOptionsMenu()
      return this.updateColumnHeaders()
    })
    return this.gradebookGrid.events.onColumnsResized.subscribe((_event, columns) => {
      return columns.forEach(column => {
        return this.saveColumnWidthPreference(column.id, column.width)
      })
    })
  }

  initialize() {
    this.dataLoader.loadInitialData()
    // Until GradebookGrid is rendered reactively, it will need to be rendered
    // once and only once. It depends on all essential data from the initial
    // data load. When all of that data has loaded, this deferred promise will
    // resolve and render the grid. As a promise, it only resolves once.
    this._essentialDataLoaded.promise.then(() => {
      return this.finishRenderingUI()
    })
    return this.gridReady.then(() => {
      // Preload the Grade Detail Tray
      AsyncComponents.loadGradeDetailTray()
      this.renderViewOptionsMenu()
      return this.renderGradebookSettingsModal()
    })
  }

  // called from ui/bundles/gradebook.js
  onShow() {
    $('.post-grades-button-placeholder').show()
    if (this.startedInitializing) {
      return
    }
    this.startedInitializing = true
    if (this.gridReady.state() !== 'resolved') {
      if (!this.spinner) {
        this.spinner = new Spinner()
      }
      $(this.spinner.spin().el)
        .css({
          opacity: 0.5,
          top: '55px',
          left: '50%'
        })
        .addClass('use-css-transitions-for-show-hide')
        .appendTo('#main')
      return $('#gradebook-grid-wrapper').hide()
    } else {
      return $('#gradebook_grid').trigger('resize.fillWindowWithMe')
    }
  }

  loadOverridesForSIS() {
    if (this.options.post_grades_feature) {
      return this.dataLoader.loadOverridesForSIS()
    }
  }

  addOverridesToPostGradesStore(assignmentGroups) {
    let assignment, group, j, k, len, len1, ref1
    for (j = 0, len = assignmentGroups.length; j < len; j++) {
      group = assignmentGroups[j]
      ref1 = group.assignments
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        assignment = ref1[k]
        if (this.assignments[assignment.id]) {
          this.assignments[assignment.id].overrides = assignment.overrides
        }
      }
    }
    return this.postGradesStore.setGradeBookAssignments(this.assignments)
  }

  // dependencies - gridReady
  setAssignmentVisibility(studentIds) {
    let a, assignmentId, hiddenStudentIds, j, k, len, len1, student, studentId
    const studentsWithHiddenAssignments = []
    const ref1 = this.assignments
    for (assignmentId in ref1) {
      a = ref1[assignmentId]
      if (a.only_visible_to_overrides) {
        hiddenStudentIds = this.hiddenStudentIdsForAssignment(studentIds, a)
        for (j = 0, len = hiddenStudentIds.length; j < len; j++) {
          studentId = hiddenStudentIds[j]
          studentsWithHiddenAssignments.push(studentId)
          this.updateSubmission({
            assignment_id: assignmentId,
            user_id: studentId,
            hidden: true
          })
        }
      }
    }
    const ref2 = _.uniq(studentsWithHiddenAssignments)
    const results = []
    for (k = 0, len1 = ref2.length; k < len1; k++) {
      studentId = ref2[k]
      student = this.student(studentId)
      results.push(this.calculateStudentGrade(student))
    }
    return results
  }

  hiddenStudentIdsForAssignment(studentIds, assignment) {
    // TODO: _.difference is ridic expensive.  may need to do something else
    // for large courses with DA (does that happen?)
    return _.difference(studentIds, assignment.assignment_visibility)
  }

  updateAssignmentVisibilities(hiddenSub) {
    const assignment = this.assignments[hiddenSub.assignment_id]
    const filteredVisibility = assignment.assignment_visibility.filter(function (id) {
      return id !== hiddenSub.user_id
    })
    return (assignment.assignment_visibility = filteredVisibility)
  }

  gotCustomColumns(columns) {
    this.gradebookContent.customColumns = columns
    columns.forEach(column => {
      const customColumn = this.buildCustomColumn(column)
      return (this.gridData.columns.definitions[customColumn.id] = customColumn)
    })
    this.setCustomColumnsLoaded(true)
    return this._updateEssentialDataLoaded()
  }

  gotCustomColumnDataChunk(customColumnId, columnData) {
    let datum, j, len, student
    const studentIds = []
    for (j = 0, len = columnData.length; j < len; j++) {
      datum = columnData[j]
      student = this.student(datum.user_id)
      if (student != null) {
        student[`custom_col_${customColumnId}`] = datum.content
        studentIds.push(student.id) // ignore filtered students
      }
    }
    return this.invalidateRowsForStudentIds(_.uniq(studentIds))
  }

  updateAssignmentGroups(assignmentGroups, gradingPeriodIds) {
    this.gotAllAssignmentGroups(assignmentGroups)
    this.setAssignmentsLoaded(gradingPeriodIds)
    this.renderViewOptionsMenu()
    this.renderFilters()
    this.updateColumnHeaders()
    return this._updateEssentialDataLoaded()
  }

  gotAllAssignmentGroups(assignmentGroups) {
    this.setAssignmentGroupsLoaded(true)
    assignmentGroups.forEach(assignmentGroup => {
      let group = this.assignmentGroups[assignmentGroup.id]

      if (!group) {
        group = assignmentGroup
        this.assignmentGroups[group.id] = group
      }

      group.assignments = group.assignments || []
      assignmentGroup.assignments.forEach(assignment => {
        assignment.assignment_group = group
        assignment.due_at = tz.parse(assignment.due_at)
        this.updateAssignmentEffectiveDueDates(assignment)
        this.addAssignmentColumnDefinition(assignment)
        this.assignments[assignment.id] = assignment
        if (!group.assignments.some(a => a.id === assignment.id)) {
          group.assignments.push(assignment)
        }
      })
    })
  }

  updateGradingPeriodAssignments(gradingPeriodAssignments) {
    this.gotGradingPeriodAssignments({
      grading_period_assignments: gradingPeriodAssignments
    })

    Object.keys(gradingPeriodAssignments).forEach(periodId => {
      this.contentLoadStates.assignmentsLoaded.gradingPeriod[
        periodId
      ] = this.contentLoadStates.assignmentsLoaded.all
    })

    this.setGradingPeriodAssignmentsLoaded(true)
    if (this._gridHasRendered()) {
      this.updateColumns()
    }
    return this._updateEssentialDataLoaded()
  }

  getGradingPeriodAssignments(gradingPeriodId) {
    return this.courseContent.gradingPeriodAssignments[gradingPeriodId] || []
  }

  gotGradingPeriodAssignments({grading_period_assignments: gradingPeriodAssignments}) {
    return (this.courseContent.gradingPeriodAssignments = gradingPeriodAssignments)
  }

  gotSections(sections) {
    this.setSections(sections.map(htmlEscape))
    this.hasSections.resolve()
    return this.postGradesStore.setSections(this.sections)
  }

  gotChunkOfStudents(students) {
    this.courseContent.assignmentStudentVisibility = {}
    const escapeStudentContent = student => {
      const unescapedName = student.name
      const unescapedSortableName = student.sortable_name

      const escapedStudent = htmlEscape(student)
      escapedStudent.name = unescapedName
      escapedStudent.sortable_name = unescapedSortableName

      escapedStudent?.enrollments.forEach(enrollment => {
        const gradesUrl = enrollment?.grades?.html_url
        if (gradesUrl) {
          enrollment.grades.html_url = htmlEscape.unescape(gradesUrl)
        }
      })
      return escapedStudent
    }
    students.forEach(student => {
      student.enrollments = _.filter(student.enrollments, function (e) {
        return e.type === 'StudentEnrollment' || e.type === 'StudentViewEnrollment'
      })
      student.sections = student.enrollments.map(function (e) {
        return e.course_section_id
      })
      const isStudentView = student.enrollments[0].type === 'StudentViewEnrollment'
      if (isStudentView) {
        this.studentViewStudents[student.id] = escapeStudentContent(student)
      } else {
        this.students[student.id] = escapeStudentContent(student)
      }
      student.computed_current_score || (student.computed_current_score = 0)
      student.computed_final_score || (student.computed_final_score = 0)
      student.isConcluded = _.every(student.enrollments, function (e) {
        return e.enrollment_state === 'completed'
      })
      student.isInactive = _.every(student.enrollments, function (e) {
        return e.enrollment_state === 'inactive'
      })
      student.cssClass = `student_${student.id}`
      this.updateStudentRow(student)
    })
    this.gridReady.then(() => {
      return this.setupGrading(students)
    })
    if (this.isFilteringRowsBySearchTerm()) {
      // When filtering, students cannot be matched until loaded. The grid must
      // be re-rendered more aggressively to ensure new rows are inserted.
      return this.buildRows()
    } else {
      return this.gradebookGrid.render()
    }
  }

  finishRenderingUI() {
    this.initGrid()
    this.initHeader()
    this.gridReady.resolve()
    return this.loadOverridesForSIS()
  }

  setupGrading(students) {
    let assignment, assignment_id, j, len, name, ref1, student, submissionState
    // set up a submission for each student even if we didn't receive one
    this.submissionStateMap.setup(students, this.assignments)
    for (j = 0, len = students.length; j < len; j++) {
      student = students[j]
      ref1 = this.assignments
      for (assignment_id in ref1) {
        assignment = ref1[assignment_id]
        if (student[(name = `assignment_${assignment_id}`)] == null) {
          student[name] = this.submissionStateMap.getSubmission(student.id, assignment_id)
        }
        submissionState = this.submissionStateMap.getSubmissionState(
          student[`assignment_${assignment_id}`]
        )
        student[`assignment_${assignment_id}`].gradeLocked = submissionState.locked
        student[`assignment_${assignment_id}`].gradingType = assignment.grading_type
      }
      student.initialized = true
      this.calculateStudentGrade(student)
    }
    const studentIds = _.pluck(students, 'id')
    this.setAssignmentVisibility(studentIds)
    return this.invalidateRowsForStudentIds(studentIds)
  }

  resetGrading() {
    this.initSubmissionStateMap()
    return this.setupGrading(this.courseContent.students.listStudents())
  }

  getSubmission(studentId, assignmentId) {
    const student = this.student(studentId)
    return student != null ? student[`assignment_${assignmentId}`] : undefined
  }

  updateEffectiveDueDatesFromSubmissions(submissions) {
    let ref1
    return EffectiveDueDates.updateWithSubmissions(
      this.effectiveDueDates,
      submissions,
      (ref1 = this.gradingPeriodSet) != null ? ref1.gradingPeriods : undefined
    )
  }

  updateAssignmentEffectiveDueDates(assignment) {
    assignment.effectiveDueDates = this.effectiveDueDates[assignment.id] || {}
    return (assignment.inClosedGradingPeriod = _.some(assignment.effectiveDueDates, date => {
      return date.in_closed_grading_period
    }))
  }

  updateStudentIds(studentIds) {
    this.courseContent.students.setStudentIds(studentIds)
    this.assignmentStudentVisibility = {}
    this.setStudentIdsLoaded(true)
    this.buildRows()
    return this._updateEssentialDataLoaded()
  }

  updateStudentsLoaded(loaded) {
    this.setStudentsLoaded(loaded)
    if (this._gridHasRendered()) {
      this.updateColumnHeaders()
    }
    this.renderFilters()
    if (loaded && this.contentLoadStates.submissionsLoaded) {
      // The "total grade" column needs to be re-rendered after loading all
      // students and submissions so that the column can indicate any hidden
      // submissions.
      return this.updateTotalGradeColumn()
    }
  }

  studentsThatCanSeeAssignment(assignmentId) {
    let allStudents, assignment, base
    return (
      (base = this.courseContent.assignmentStudentVisibility)[assignmentId] ||
      (base[assignmentId] =
        ((assignment = this.getAssignment(assignmentId)),
        (allStudents = {...this.students, ...this.studentViewStudents}),
        assignment.only_visible_to_overrides
          ? _.pick(allStudents, ...assignment.assignment_visibility)
          : allStudents))
    )
  }

  isInvalidSort() {
    const sortSettings = this.gradebookColumnOrderSettings
    if (
      (sortSettings != null ? sortSettings.sortType : undefined) === 'custom' &&
      !(sortSettings != null ? sortSettings.customOrder : undefined)
    ) {
      // This course was sorted by a custom column sort at some point but no longer has any stored
      // column order to sort by
      // let's mark it invalid so it reverts to default sort
      return true
    }
    if (
      (sortSettings != null ? sortSettings.sortType : undefined) === 'module_position' &&
      this.listContextModules().length === 0
    ) {
      // This course was sorted by module_position at some point but no longer contains modules
      // let's mark it invalid so it reverts to default sort
      return true
    }
    return false
  }

  isDefaultSortOrder(sortOrder) {
    return !['due_date', 'name', 'points', 'module_position', 'custom'].includes(sortOrder)
  }

  setColumnOrder(order) {
    if (this.gradebookColumnOrderSettings == null) {
      this.gradebookColumnOrderSettings = {
        direction: 'ascending',
        freezeTotalGrade: false,
        sortType: this.defaultSortType
      }
    }
    if (!order) {
      return
    }
    if (order.freezeTotalGrade != null) {
      this.gradebookColumnOrderSettings.freezeTotalGrade = order.freezeTotalGrade
    }
    if (order.sortType === 'custom' && order.customOrder != null) {
      this.gradebookColumnOrderSettings.sortType = 'custom'
      return (this.gradebookColumnOrderSettings.customOrder = order.customOrder)
    } else if (order.sortType != null && order.direction != null) {
      this.gradebookColumnOrderSettings.sortType = order.sortType
      return (this.gradebookColumnOrderSettings.direction = order.direction)
    }
  }

  getColumnOrder() {
    if (this.isInvalidSort() || !this.gradebookColumnOrderSettings) {
      return {
        direction: 'ascending',
        freezeTotalGrade: false,
        sortType: this.defaultSortType
      }
    } else {
      return this.gradebookColumnOrderSettings
    }
  }

  saveColumnOrder() {
    let url
    if (!this.isInvalidSort()) {
      url = this.options.gradebook_column_order_settings_url
      return $.ajaxJSON(url, 'POST', {
        column_order: this.getColumnOrder()
      })
    }
  }

  reorderCustomColumns(ids) {
    return $.ajaxJSON(this.options.reorder_custom_columns_url, 'POST', {
      order: ids
    })
  }

  saveCustomColumnOrder() {
    this.setColumnOrder({
      customOrder: this.gridData.columns.scrollable,
      sortType: 'custom'
    })
    return this.saveColumnOrder()
  }

  arrangeColumnsBy(newSortOrder, isFirstArrangement) {
    if (!isFirstArrangement) {
      this.setColumnOrder(newSortOrder)
      this.saveColumnOrder()
    }
    const columns = this.gridData.columns.scrollable.map(columnId => {
      return this.gridData.columns.definitions[columnId]
    })
    columns.sort(this.makeColumnSortFn(newSortOrder))
    this.gridData.columns.scrollable = columns.map(function (column) {
      return column.id
    })
    this.updateGrid()
    this.renderViewOptionsMenu()
    return this.updateColumnHeaders()
  }

  makeColumnSortFn(sortOrder) {
    switch (sortOrder.sortType) {
      case 'due_date':
        return this.wrapColumnSortFn(compareAssignmentDueDates, sortOrder.direction)
      case 'module_position':
        return this.wrapColumnSortFn(this.compareAssignmentModulePositions, sortOrder.direction)
      case 'name':
        return this.wrapColumnSortFn(this.compareAssignmentNames, sortOrder.direction)
      case 'points':
        return this.wrapColumnSortFn(this.compareAssignmentPointsPossible, sortOrder.direction)
      case 'custom':
        return this.makeCompareAssignmentCustomOrderFn(sortOrder)
      default:
        return this.wrapColumnSortFn(this.compareAssignmentPositions, sortOrder.direction)
    }
  }

  compareAssignmentPositions(a, b) {
    const diffOfAssignmentGroupPosition =
      a.object.assignment_group.position - b.object.assignment_group.position
    const diffOfAssignmentPosition = a.object.position - b.object.position
    // order first by assignment_group position and then by assignment position
    // will work when there are less than 1000000 assignments in an assignment_group
    return diffOfAssignmentGroupPosition * 1000000 + diffOfAssignmentPosition
  }

  compareAssignmentModulePositions(a, b) {
    let firstPositionInModule, ref1, ref2, secondPositionInModule
    const firstAssignmentModulePosition =
      (ref1 = this.getContextModule(a.object.module_ids[0])) != null ? ref1.position : undefined
    const secondAssignmentModulePosition =
      (ref2 = this.getContextModule(b.object.module_ids[0])) != null ? ref2.position : undefined
    if (firstAssignmentModulePosition != null && secondAssignmentModulePosition != null) {
      if (firstAssignmentModulePosition === secondAssignmentModulePosition) {
        // let's determine their order in the module because both records are in the same module
        firstPositionInModule = a.object.module_positions[0]
        secondPositionInModule = b.object.module_positions[0]
        return firstPositionInModule - secondPositionInModule
      } else {
        // let's determine the order of their modules because both records are in different modules
        return firstAssignmentModulePosition - secondAssignmentModulePosition
      }
    } else if (firstAssignmentModulePosition == null && secondAssignmentModulePosition != null) {
      return 1
    } else if (firstAssignmentModulePosition != null && secondAssignmentModulePosition == null) {
      return -1
    } else {
      return this.compareAssignmentPositions(a, b)
    }
  }

  compareAssignmentNames(a, b) {
    return this.localeSort(a.object.name, b.object.name)
  }

  compareAssignmentPointsPossible(a, b) {
    return a.object.points_possible - b.object.points_possible
  }

  makeCompareAssignmentCustomOrderFn(sortOrder) {
    let assignmentId, indexCounter, j, len
    const sortMap = {}
    indexCounter = 0
    const ref1 = sortOrder.customOrder
    for (j = 0, len = ref1.length; j < len; j++) {
      assignmentId = ref1[j]
      sortMap[String(assignmentId)] = indexCounter
      indexCounter += 1
    }
    return (a, b) => {
      let aIndex, bIndex
      // The second lookup for each index is to maintain backwards
      // compatibility with old gradebook sorting on load which only
      // considered assignment ids.
      aIndex = sortMap[a.id]
      if (a.object != null) {
        if (aIndex == null) {
          aIndex = sortMap[String(a.object.id)]
        }
      }
      bIndex = sortMap[b.id]
      if (b.object != null) {
        if (bIndex == null) {
          bIndex = sortMap[String(b.object.id)]
        }
      }
      if (aIndex != null && bIndex != null) {
        return aIndex - bIndex
        // if there's a new assignment or assignment group and its
        // order has not been stored, it should come at the end
      } else if (aIndex != null && bIndex == null) {
        return -1
      } else if (bIndex != null) {
        return 1
      } else {
        return this.wrapColumnSortFn(this.compareAssignmentPositions)(a, b)
      }
    }
  }

  wrapColumnSortFn(wrappedFn, direction = 'ascending') {
    return function (a, b) {
      if (b.type === 'total_grade_override') {
        return -1
      }
      if (a.type === 'total_grade_override') {
        return 1
      }
      if (b.type === 'total_grade') {
        return -1
      }
      if (a.type === 'total_grade') {
        return 1
      }
      if (b.type === 'assignment_group' && a.type !== 'assignment_group') {
        return -1
      }
      if (a.type === 'assignment_group' && b.type !== 'assignment_group') {
        return 1
      }
      if (a.type === 'assignment_group' && b.type === 'assignment_group') {
        return a.object.position - b.object.position
      }
      if (direction === 'descending') {
        ;[a, b] = [b, a]
      }
      return wrappedFn(a, b)
    }
  }

  rowFilter(student) {
    if (!this.isFilteringRowsBySearchTerm()) {
      return true
    }
    const propertiesToMatch = ['name', 'login_id', 'short_name', 'sortable_name', 'sis_user_id']
    const pattern = new RegExp(this.userFilterTerm, 'i')
    return _.some(propertiesToMatch, function (prop) {
      let ref1
      return (ref1 = student[prop]) != null ? ref1.match(pattern) : undefined
    })
  }

  filterAssignments(assignments) {
    const assignmentFilters = [
      this.filterAssignmentBySubmissionTypes,
      this.filterAssignmentByPublishedStatus,
      this.filterAssignmentByAssignmentGroup,
      this.filterAssignmentByGradingPeriod,
      this.filterAssignmentByModule
    ]
    const matchesAllFilters = assignment => {
      return assignmentFilters.every(filter => {
        return filter(assignment)
      })
    }
    return assignments.filter(matchesAllFilters)
  }

  filterAssignmentBySubmissionTypes(assignment) {
    const submissionType = '' + assignment.submission_types
    return (
      submissionType !== 'not_graded' && (submissionType !== 'attendance' || this.show_attendance)
    )
  }

  filterAssignmentByPublishedStatus(assignment) {
    return assignment.published || this.gridDisplaySettings.showUnpublishedAssignments
  }

  filterAssignmentByAssignmentGroup(assignment) {
    if (!this.isFilteringColumnsByAssignmentGroup()) {
      return true
    }
    return this.getAssignmentGroupToShow() === assignment.assignment_group_id
  }

  filterAssignmentByGradingPeriod(assignment) {
    if (!this.isFilteringColumnsByGradingPeriod()) return true

    const assignmentsForPeriod = this.getGradingPeriodAssignments(this.gradingPeriodId)
    return assignmentsForPeriod.includes(assignment.id)
  }

  filterAssignmentByModule(assignment) {
    let ref1
    const contextModuleFilterSetting = this.getModuleToShow()
    if (contextModuleFilterSetting === '0') {
      return true
    }
    return (
      (ref1 = this.getFilterColumnsBySetting('contextModuleId')),
      indexOf.call(assignment.module_ids || [], ref1) >= 0
    )
  }

  handleSubmissionPostedChange(assignment) {
    let anonymousColumnIds, ref1
    if (assignment.anonymize_students) {
      anonymousColumnIds = [
        this.getAssignmentColumnId(assignment.id),
        this.getAssignmentGroupColumnId(assignment.assignment_group_id),
        'total_grade',
        'total_grade_override'
      ]
      if (
        ((ref1 = this.getSortRowsBySetting().columnId), indexOf.call(anonymousColumnIds, ref1) >= 0)
      ) {
        this.setSortRowsBySetting('student', 'sortable_name', 'ascending')
      }
    }
    this.gradebookGrid.gridSupport.columns.updateColumnHeaders([
      this.getAssignmentColumnId(assignment.id)
    ])
    this.updateFilteredContentInfo()
    return this.resetGrading()
  }

  handleSubmissionsDownloading(assignmentId) {
    this.getAssignment(assignmentId).hasDownloadedSubmissions = true
    return this.gradebookGrid.gridSupport.columns.updateColumnHeaders([
      this.getAssignmentColumnId(assignmentId)
    ])
  }

  buildRows() {
    let j, len, student
    this.gridData.rows.length = 0 // empty the list of rows
    const ref1 = this.courseContent.students.listStudents()
    for (j = 0, len = ref1.length; j < len; j++) {
      student = ref1[j]
      if (this.rowFilter(student)) {
        this.gridData.rows.push(this.buildRow(student))
        this.calculateStudentGrade(student) // TODO: this may not be necessary
      }
    }
    return this.gradebookGrid.invalidate()
  }

  buildRow(student) {
    // because student is current mutable, we need to retain the reference
    return student
  }

  updateSubmissionsLoaded(loaded) {
    this.setSubmissionsLoaded(loaded)
    this.updateColumnHeaders()
    this.renderFilters()
    if (loaded && this.contentLoadStates.studentsLoaded) {
      // The "total grade" column needs to be re-rendered after loading all
      // students and submissions so that the column can indicate any hidden
      // submissions.
      return this.updateTotalGradeColumn()
    }
  }

  gotSubmissionsChunk(student_submissions) {
    let j, k, len, len1, ref1, student, studentSubmissionGroup, submission
    let changedStudentIds = []
    const submissions = []
    for (j = 0, len = student_submissions.length; j < len; j++) {
      studentSubmissionGroup = student_submissions[j]
      changedStudentIds.push(studentSubmissionGroup.user_id)
      student = this.student(studentSubmissionGroup.user_id)
      ref1 = studentSubmissionGroup.submissions
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        submission = ref1[k]
        ensureAssignmentVisibility(this.getAssignment(submission.assignment_id), submission)
        submissions.push(submission)
        this.updateSubmission(submission)
      }
      student.loaded = true
    }
    this.updateEffectiveDueDatesFromSubmissions(submissions)
    _.each(this.assignments, assignment => {
      return this.updateAssignmentEffectiveDueDates(assignment)
    })
    changedStudentIds = _.uniq(changedStudentIds)
    const students = changedStudentIds.map(this.student)
    return this.setupGrading(students)
  }

  student(id) {
    return this.students[id] || this.studentViewStudents[id]
  }

  updateSubmission(submission) {
    let assignment, name
    const student = this.student(submission.user_id)
    submission.submitted_at = tz.parse(submission.submitted_at)
    submission.excused = !!submission.excused
    submission.hidden = !!submission.hidden
    submission.rawGrade = submission.grade // save the unformatted version of the grade too
    if ((assignment = this.assignments[submission.assignment_id])) {
      submission.gradingType = assignment.grading_type
      if (submission.gradingType !== 'pass_fail') {
        submission.grade = GradeFormatHelper.formatGrade(submission.grade, {
          gradingType: submission.gradingType,
          delocalize: false
        })
      }
    }
    const cell = student[(name = `assignment_${submission.assignment_id}`)] || (student[name] = {})
    return _.extend(cell, submission)
  }

  updateSubmissionsFromExternal(submissions) {
    let cell, column, idToMatch, index, k, len1, student, submissionState
    const columns = this.gradebookGrid.grid.getColumns()
    const changedColumnHeaders = {}
    const changedStudentIds = []
    for (let j = 0, len = submissions.length; j < len; j++) {
      const submission = submissions[j]
      student = this.student(submission.user_id)
      if (!student) {
        // if the student isn't loaded, we don't need to update it
        continue
      }
      idToMatch = this.getAssignmentColumnId(submission.assignment_id)
      for (index = k = 0, len1 = columns.length; k < len1; index = ++k) {
        column = columns[index]
        if (column.id === idToMatch) {
          cell = index
        }
      }
      if (!changedColumnHeaders[submission.assignment_id]) {
        changedColumnHeaders[submission.assignment_id] = cell
      }
      if (!submission.assignment_visible) {
        // check for DA visible
        this.updateAssignmentVisibilities(submission)
      }
      this.updateSubmission(submission)
      this.submissionStateMap.setSubmissionCellState(
        student,
        this.assignments[submission.assignment_id],
        submission
      )
      submissionState = this.submissionStateMap.getSubmissionState(submission)
      student[`assignment_${submission.assignment_id}`].gradeLocked = submissionState.locked
      this.calculateStudentGrade(student)
      changedStudentIds.push(student.id)
    }
    const changedColumnIds = Object.keys(changedColumnHeaders).map(this.getAssignmentColumnId)
    this.gradebookGrid.gridSupport.columns.updateColumnHeaders(changedColumnIds)
    return this.updateRowCellsForStudentIds(_.uniq(changedStudentIds))
  }

  submissionsForStudent(student) {
    let key, value
    const allSubmissions = (function () {
      const results = []
      for (key in student) {
        value = student[key]
        if (key.match(ASSIGNMENT_KEY_REGEX)) {
          results.push(value)
        }
      }
      return results
    })()
    if (this.gradingPeriodSet == null) {
      return allSubmissions
    }
    if (!this.isFilteringColumnsByGradingPeriod()) {
      return allSubmissions
    }
    return _.filter(allSubmissions, submission => {
      let ref1
      const studentPeriodInfo = this.effectiveDueDates[submission.assignment_id]?.[
        submission.user_id
      ]
      return studentPeriodInfo && studentPeriodInfo.grading_period_id === this.gradingPeriodId
    })
  }

  getStudentGrades(student, preferCachedGrades) {
    if (preferCachedGrades && this.calculatedGradesByStudentId[student.id] != null) {
      return this.calculatedGradesByStudentId[student.id]
    }

    const hasGradingPeriods = this.gradingPeriodSet && this.effectiveDueDates
    const grades = CourseGradeCalculator.calculate(
      this.submissionsForStudent(student),
      this.assignmentGroups,
      this.options.group_weighting_scheme,
      this.options.grade_calc_ignore_unposted_anonymous_enabled,
      hasGradingPeriods ? this.gradingPeriodSet : undefined,
      hasGradingPeriods
        ? EffectiveDueDates.scopeToUser(this.effectiveDueDates, student.id)
        : undefined
    )
    this.calculatedGradesByStudentId[student.id] = grades

    return grades
  }

  calculateStudentGrade(student, preferCachedGrades = false) {
    if (!(student.loaded && student.initialized)) {
      return null
    }

    let grades = this.getStudentGrades(student, preferCachedGrades)
    if (this.isFilteringColumnsByGradingPeriod()) {
      grades = grades.gradingPeriods[this.gradingPeriodId]
    }

    const scoreType = this.viewUngradedAsZero() ? 'final' : 'current'
    Object.keys(this.assignmentGroups).forEach(assignmentGroupId => {
      let grade = grades.assignmentGroups[assignmentGroupId]
      grade = grade?.[scoreType] || {
        score: 0,
        possible: 0,
        submissions: []
      }
      student[`assignment_group_${assignmentGroupId}`] = grade

      grade.submissions.forEach(submissionData => {
        submissionData.submission.drop = submissionData.drop
      })
    })
    student.total_grade = grades[scoreType]
  }

  // # Grid Styling Methods

  // this is because of a limitation with SlickGrid,
  // when it makes the header row it does this:
  // $("<div class='slick-header-columns' style='width:10000px; left:-1000px' />")
  // if a course has a ton of assignments then it will not be wide enough to
  // contain them all
  fixMaxHeaderWidth() {
    return this.$grid.find('.slick-header-columns').width(1000000)
  }

  onGridBlur(e) {
    let className
    if (this.getSubmissionTrayState().open) {
      this.closeSubmissionTray()
    }
    // Prevent exiting the cell editor when clicking in the cell being edited.
    const editingNode = this.gradebookGrid.gridSupport.state.getEditingNode()
    if (editingNode != null ? editingNode.contains(e.target) : undefined) {
      return
    }
    const activeNode = this.gradebookGrid.gridSupport.state.getActiveNode()
    if (!activeNode) {
      return
    }
    if (activeNode.contains(e.target)) {
      // SlickGrid does not re-engage the editor for the active cell upon single click
      this.gradebookGrid.gridSupport.helper.beginEdit()
      return
    }
    className = e.target.className
    // PopoverMenu's trigger sends an event with a target whose className is a SVGAnimatedString
    // This normalizes the className where possible
    if (typeof className !== 'string') {
      if (typeof className === 'object') {
        className = className.baseVal || ''
      } else {
        className = ''
      }
    }
    // Do nothing if clicking on another cell
    if (className.match(/cell|slick/)) {
      return
    }
    return this.gradebookGrid.gridSupport.state.blur()
  }

  sectionList() {
    return _.values(this.sections)
      .sort((a, b) => {
        return a.id - b.id
      })
      .map(section => {
        return {...section, name: htmlEscape.unescape(section.name)}
      })
  }

  updateSectionFilterVisibility() {
    let props
    const mountPoint = document.getElementById('sections-filter-container')
    if (
      this.showSections() &&
      indexOf.call(this.gridDisplaySettings.selectedViewOptionsFilters, 'sections') >= 0
    ) {
      props = {
        sections: this.sectionList(),
        onSelect: this.updateCurrentSection,
        selectedSectionId: this.getFilterRowsBySetting('sectionId') || '0',
        disabled: !this.contentLoadStates.studentsLoaded
      }
      return renderComponent(SectionFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentSection(null)
      return ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  updateCurrentSection(sectionId) {
    sectionId = sectionId === '0' ? null : sectionId
    const currentSection = this.getFilterRowsBySetting('sectionId')
    if (currentSection !== sectionId) {
      this.setFilterRowsBySetting('sectionId', sectionId)
      this.postGradesStore.setSelectedSection(sectionId)
      return this.saveSettings({}, () => {
        this.updateSectionFilterVisibility()
        return this.dataLoader.reloadStudentDataForSectionFilterChange()
      })
    }
  }

  showSections() {
    return this.sections_enabled
  }

  showStudentGroups() {
    return this.studentGroupsEnabled
  }

  updateStudentGroupFilterVisibility() {
    let props, studentGroupSets
    const mountPoint = document.getElementById('student-group-filter-container')
    if (
      this.showStudentGroups() &&
      indexOf.call(this.gridDisplaySettings.selectedViewOptionsFilters, 'studentGroups') >= 0
    ) {
      studentGroupSets = Object.values(this.studentGroupCategories).sort((a, b) => {
        return a.id - b.id
      })
      props = {
        studentGroupSets,
        onSelect: this.updateCurrentStudentGroup,
        selectedStudentGroupId: this.getStudentGroupToShow(),
        disabled: !this.contentLoadStates.studentsLoaded
      }
      return renderComponent(StudentGroupFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentStudentGroup(null)
      return ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  getStudentGroupToShow() {
    const groupId = this.getFilterRowsBySetting('studentGroupId') || '0'
    if (indexOf.call(Object.keys(this.studentGroups), groupId) >= 0) {
      return groupId
    } else {
      return '0'
    }
  }

  updateCurrentStudentGroup(groupId) {
    groupId = groupId === '0' ? null : groupId
    if (this.getFilterRowsBySetting('studentGroupId') !== groupId) {
      this.setFilterRowsBySetting('studentGroupId', groupId)
      return this.saveSettings({}, () => {
        this.updateStudentGroupFilterVisibility()
        return this.dataLoader.reloadStudentDataForStudentGroupFilterChange()
      })
    }
  }

  assignmentGroupList() {
    if (!this.assignmentGroups) {
      return []
    }
    return Object.values(this.assignmentGroups).sort((a, b) => {
      return a.position - b.position
    })
  }

  updateAssignmentGroupFilterVisibility() {
    let props
    const mountPoint = document.getElementById('assignment-group-filter-container')
    const groups = this.assignmentGroupList()
    if (
      groups.length > 1 &&
      indexOf.call(this.gridDisplaySettings.selectedViewOptionsFilters, 'assignmentGroups') >= 0
    ) {
      props = {
        assignmentGroups: groups,
        disabled: false,
        onSelect: this.updateCurrentAssignmentGroup,
        selectedAssignmentGroupId: this.getAssignmentGroupToShow()
      }
      return renderComponent(AssignmentGroupFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentAssignmentGroup(null)
      return ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  updateCurrentAssignmentGroup(group) {
    if (this.getFilterColumnsBySetting('assignmentGroupId') !== group) {
      this.setFilterColumnsBySetting('assignmentGroupId', group)
      this.saveSettings()
      this.resetGrading()
      this.updateFilteredContentInfo()
      this.updateColumnsAndRenderViewOptionsMenu()
      return this.updateAssignmentGroupFilterVisibility()
    }
  }

  gradingPeriodList() {
    return this.gradingPeriodSet.gradingPeriods.sort((a, b) => {
      return a.startDate - b.startDate
    })
  }

  updateGradingPeriodFilterVisibility() {
    let props
    const mountPoint = document.getElementById('grading-periods-filter-container')
    if (
      this.gradingPeriodSet != null &&
      indexOf.call(this.gridDisplaySettings.selectedViewOptionsFilters, 'gradingPeriods') >= 0
    ) {
      props = {
        disabled: !this.contentLoadStates.assignmentsLoaded.all,
        gradingPeriods: this.gradingPeriodList(),
        onSelect: this.updateCurrentGradingPeriod,
        selectedGradingPeriodId: this.gradingPeriodId
      }
      return renderComponent(GradingPeriodFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentGradingPeriod(null)
      return ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  updateCurrentGradingPeriod(period) {
    if (this.getFilterColumnsBySetting('gradingPeriodId') !== period) {
      this.setFilterColumnsBySetting('gradingPeriodId', period)
      this.setCurrentGradingPeriod()
      this.saveSettings()
      this.resetGrading()
      this.sortGridRows()
      this.updateFilteredContentInfo()
      this.updateColumnsAndRenderViewOptionsMenu()
      this.updateGradingPeriodFilterVisibility()
      return this.renderActionMenu()
    }
  }

  updateCurrentModule(moduleId) {
    if (this.getFilterColumnsBySetting('contextModuleId') !== moduleId) {
      this.setFilterColumnsBySetting('contextModuleId', moduleId)
      this.saveSettings()
      this.updateFilteredContentInfo()
      this.updateColumnsAndRenderViewOptionsMenu()
      return this.updateModulesFilterVisibility()
    }
  }

  moduleList() {
    return this.listContextModules().sort((a, b) => {
      return a.position - b.position
    })
  }

  updateModulesFilterVisibility() {
    let props, ref1
    const mountPoint = document.getElementById('modules-filter-container')
    if (
      ((ref1 = this.listContextModules()) != null ? ref1.length : undefined) > 0 &&
      indexOf.call(this.gridDisplaySettings.selectedViewOptionsFilters, 'modules') >= 0
    ) {
      props = {
        disabled: false,
        modules: this.moduleList(),
        onSelect: this.updateCurrentModule,
        selectedModuleId: this.getModuleToShow()
      }
      return renderComponent(ModuleFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentModule(null)
      return ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  initSubmissionStateMap() {
    return (this.submissionStateMap = new SubmissionStateMap({
      hasGradingPeriods: this.gradingPeriodSet != null,
      selectedGradingPeriodID: this.gradingPeriodId,
      isAdmin: isAdmin()
    }))
  }

  initPostGradesStore() {
    this.postGradesStore = PostGradesStore({
      course: {
        id: this.options.context_id,
        sis_id: this.options.context_sis_id
      }
    })
    this.postGradesStore.addChangeListener(this.updatePostGradesFeatureButton)
    const sectionId = this.getFilterRowsBySetting('sectionId')
    return this.postGradesStore.setSelectedSection(sectionId)
  }

  delayedCall(delay, fn) {
    return setTimeout(fn, delay)
  }

  initPostGradesLtis() {
    return (this.postGradesLtis = this.options.post_grades_ltis.map(lti => {
      let postGradesLti
      return (postGradesLti = {
        id: lti.id,
        name: lti.name,
        onSelect: () => {
          const postGradesDialog = new PostGradesFrameDialog({
            returnFocusTo: document.querySelector("[data-component='ActionMenu'] button"),
            baseUrl: lti.data_url
          })
          this.delayedCall(10, () => {
            return postGradesDialog.open()
          })
          return (window.external_tool_redirect = {
            ready: postGradesDialog.close,
            cancel: postGradesDialog.close
          })
        }
      })
    }))
  }

  updatePostGradesFeatureButton() {
    this.disablePostGradesFeature =
      !this.postGradesStore.hasAssignments() || !this.postGradesStore.selectedSISId()
    return this.gridReady.then(() => {
      return this.renderActionMenu()
    })
  }

  initHeader() {
    this.renderGradebookMenus()
    this.renderFilters()
    this.arrangeColumnsBy(this.getColumnOrder(), true)
    this.renderGradebookSettingsModal()
    this.renderSettingsButton()
    this.renderStatusesModal()
    return $('#keyboard-shortcuts').click(function () {
      const questionMarkKeyDown = $.Event('keydown', {
        keyCode: 191,
        shiftKey: true
      })
      return $(document).trigger(questionMarkKeyDown)
    })
  }

  renderGradebookMenus() {
    this.renderGradebookMenu()
    this.renderViewOptionsMenu()
    return this.renderActionMenu()
  }

  renderGradebookMenu() {
    let j, len, mountPoint
    const mountPoints = document.querySelectorAll('[data-component="GradebookMenu"]')
    const props = {
      assignmentOrOutcome: this.options.assignmentOrOutcome,
      courseUrl: this.options.context_url,
      learningMasteryEnabled: this.options.outcome_gradebook_enabled
    }
    const results = []
    for (j = 0, len = mountPoints.length; j < len; j++) {
      mountPoint = mountPoints[j]
      props.variant = mountPoint.getAttribute('data-variant')
      results.push(renderComponent(GradebookMenu, mountPoint, props))
    }
    return results
  }

  getTeacherNotesViewOptionsMenuProps() {
    let onSelect
    const teacherNotes = this.getTeacherNotesColumn()
    const showingNotes = teacherNotes != null && !teacherNotes.hidden
    if (showingNotes) {
      onSelect = () => {
        return this.setTeacherNotesHidden(true)
      }
    } else if (teacherNotes) {
      onSelect = () => {
        return this.setTeacherNotesHidden(false)
      }
    } else {
      onSelect = this.createTeacherNotes
    }
    return {
      disabled:
        this.contentLoadStates.teacherNotesColumnUpdating || this.gridReady.state() !== 'resolved',
      onSelect,
      selected: showingNotes
    }
  }

  getColumnSortSettingsViewOptionsMenuProps() {
    const storedSortOrder = this.getColumnOrder()
    const criterion = this.isDefaultSortOrder(storedSortOrder.sortType)
      ? 'default'
      : storedSortOrder.sortType
    return {
      criterion,
      direction: storedSortOrder.direction || 'ascending',
      disabled: !this.assignmentsLoadedForCurrentView(),
      modulesEnabled: this.listContextModules().length > 0,
      onSortByDefault: () => {
        return this.arrangeColumnsBy(
          {
            sortType: 'default',
            direction: 'ascending'
          },
          false
        )
      },
      onSortByNameAscending: () => {
        return this.arrangeColumnsBy(
          {
            sortType: 'name',
            direction: 'ascending'
          },
          false
        )
      },
      onSortByNameDescending: () => {
        return this.arrangeColumnsBy(
          {
            sortType: 'name',
            direction: 'descending'
          },
          false
        )
      },
      onSortByDueDateAscending: () => {
        return this.arrangeColumnsBy(
          {
            sortType: 'due_date',
            direction: 'ascending'
          },
          false
        )
      },
      onSortByDueDateDescending: () => {
        return this.arrangeColumnsBy(
          {
            sortType: 'due_date',
            direction: 'descending'
          },
          false
        )
      },
      onSortByPointsAscending: () => {
        return this.arrangeColumnsBy(
          {
            sortType: 'points',
            direction: 'ascending'
          },
          false
        )
      },
      onSortByPointsDescending: () => {
        return this.arrangeColumnsBy(
          {
            sortType: 'points',
            direction: 'descending'
          },
          false
        )
      },
      onSortByModuleAscending: () => {
        return this.arrangeColumnsBy(
          {
            sortType: 'module_position',
            direction: 'ascending'
          },
          false
        )
      },
      onSortByModuleDescending: () => {
        return this.arrangeColumnsBy(
          {
            sortType: 'module_position',
            direction: 'descending'
          },
          false
        )
      }
    }
  }

  getFilterSettingsViewOptionsMenuProps() {
    return {
      available: this.listAvailableViewOptionsFilters(),
      onSelect: this.updateFilterSettings,
      selected: this.listSelectedViewOptionsFilters()
    }
  }

  updateFilterSettings(filters) {
    this.setSelectedViewOptionsFilters(filters)
    this.renderViewOptionsMenu()
    this.renderFilters()
    return this.saveSettings()
  }

  getViewOptionsMenuProps() {
    return {
      teacherNotes: this.getTeacherNotesViewOptionsMenuProps(),
      columnSortSettings: this.getColumnSortSettingsViewOptionsMenuProps(),
      filterSettings: this.getFilterSettingsViewOptionsMenuProps(),
      showUnpublishedAssignments: this.gridDisplaySettings.showUnpublishedAssignments,
      onSelectShowUnpublishedAssignments: this.toggleUnpublishedAssignments,
      onSelectShowStatusesModal: () => {
        return this.statusesModal.open()
      },
      onSelectViewUngradedAsZero: this.confirmViewUngradedAsZero,
      viewUngradedAsZero: this.gridDisplaySettings.viewUngradedAsZero,
      allowViewUngradedAsZero: this.courseFeatures.allowViewUngradedAsZero
    }
  }

  renderViewOptionsMenu() {
    const mountPoint = document.querySelector("[data-component='ViewOptionsMenu']")
    return (this.viewOptionsMenu = renderComponent(
      ViewOptionsMenu,
      mountPoint,
      this.getViewOptionsMenuProps()
    ))
  }

  getActionMenuProps() {
    let attachmentData
    const focusReturnPoint = document.querySelector("[data-component='ActionMenu'] button")
    const actionMenuProps = {
      gradebookIsEditable: this.options.gradebook_is_editable,
      contextAllowsGradebookUploads: this.options.context_allows_gradebook_uploads,
      gradebookImportUrl: this.options.gradebook_import_url,
      currentUserId: this.options.currentUserId,
      gradebookExportUrl: this.options.export_gradebook_csv_url,
      postGradesLtis: this.postGradesLtis,
      postGradesFeature: {
        enabled: this.options.post_grades_feature != null && !this.disablePostGradesFeature,
        returnFocusTo: focusReturnPoint,
        label: this.options.sis_name,
        store: this.postGradesStore
      },
      publishGradesToSis: {
        isEnabled: this.options.publish_to_sis_enabled,
        publishToSisUrl: this.options.publish_to_sis_url
      },
      gradingPeriodId: this.gradingPeriodId
    }
    const progressData = this.options.gradebook_csv_progress
    if (this.options.gradebook_csv_progress) {
      actionMenuProps.lastExport = {
        progressId: `${progressData.progress.id}`,
        workflowState: progressData.progress.workflow_state
      }
      attachmentData = this.options.attachment
      if (attachmentData) {
        actionMenuProps.attachment = {
          id: `${attachmentData.attachment.id}`,
          downloadUrl: this.options.attachment_url,
          updatedAt: attachmentData.attachment.updated_at
        }
      }
    }
    return actionMenuProps
  }

  renderActionMenu() {
    const mountPoint = document.querySelector("[data-component='ActionMenu']")
    const props = this.getActionMenuProps()
    return renderComponent(ActionMenu, mountPoint, props)
  }

  renderFilters() {
    // Sections and grading periods are passed into the constructor, and therefore are always
    // available, whereas assignment groups and context modules are fetched via the DataLoader,
    // so we need to wait until they are loaded to set their filter visibility.
    this.updateSectionFilterVisibility()
    this.updateStudentGroupFilterVisibility()
    if (this.contentLoadStates.assignmentGroupsLoaded) {
      this.updateAssignmentGroupFilterVisibility()
    }
    this.updateGradingPeriodFilterVisibility()
    if (this.contentLoadStates.contextModulesLoaded) {
      this.updateModulesFilterVisibility()
    }
    return this.renderSearchFilter()
  }

  renderGridColor() {
    const gridColorMountPoint = document.querySelector('[data-component="GridColor"]')
    const gridColorProps = {
      colors: this.getGridColors()
    }
    return renderComponent(GridColor, gridColorMountPoint, gridColorProps)
  }

  renderGradebookSettingsModal() {
    this.gradebookSettingsModal = React.createRef(null)
    const props = {
      anonymousAssignmentsPresent: _.some(this.assignments, assignment => {
        return assignment.anonymous_grading
      }),
      courseId: this.options.context_id,
      courseFeatures: this.courseFeatures,
      courseSettings: this.courseSettings,
      gradedLateSubmissionsExist: this.options.graded_late_submissions_exist,
      locale: this.options.locale,
      onClose: () => {
        return this.gradebookSettingsModalButton.focus()
      },
      onCourseSettingsUpdated: settings => {
        return this.courseSettings.handleUpdated(settings)
      },
      onLatePolicyUpdate: this.onLatePolicyUpdate,
      postPolicies: this.postPolicies,
      ref: this.gradebookSettingsModal
    }
    const $container = document.querySelector("[data-component='GradebookSettingsModal']")
    return AsyncComponents.renderGradebookSettingsModal(props, $container)
  }

  renderSettingsButton() {
    const iconSettingsSolid = React.createElement(IconSettingsSolid)
    const buttonMountPoint = document.getElementById('gradebook-settings-modal-button-container')
    const buttonProps = {
      icon: iconSettingsSolid,
      id: 'gradebook-settings-button',
      variant: 'icon',
      onClick: () => {
        let ref1
        return (ref1 = this.gradebookSettingsModal.current) != null ? ref1.open() : undefined
      }
    }
    const screenReaderContent = React.createElement(
      ScreenReaderContent,
      {},
      I18n.t('Gradebook Settings')
    )
    return (this.gradebookSettingsModalButton = renderComponent(
      Button,
      buttonMountPoint,
      buttonProps,
      screenReaderContent
    ))
  }

  renderStatusesModal() {
    const statusesModalMountPoint = document.querySelector("[data-component='StatusesModal']")
    const statusesModalProps = {
      onClose: () => {
        return this.viewOptionsMenu.focus()
      },
      colors: this.getGridColors(),
      afterUpdateStatusColors: this.updateGridColors
    }
    return (this.statusesModal = renderComponent(
      StatusesModal,
      statusesModalMountPoint,
      statusesModalProps
    ))
  }

  checkForUploadComplete() {
    if (UserSettings.contextGet('gradebookUploadComplete')) {
      $.flashMessage(I18n.t('Upload successful'))
      return UserSettings.contextRemove('gradebookUploadComplete')
    }
  }

  weightedGroups() {
    return this.options.group_weighting_scheme === 'percent'
  }

  weightedGrades() {
    let ref1
    return (
      this.weightedGroups() ||
      !!((ref1 = this.gradingPeriodSet) != null ? ref1.weighted : undefined)
    )
  }

  switchTotalDisplay({dontWarnAgain = false} = {}) {
    if (dontWarnAgain) {
      UserSettings.contextSet('warned_about_totals_display', true)
    }
    this.options.show_total_grade_as_points = !this.options.show_total_grade_as_points
    $.ajaxJSON(this.options.setting_update_url, 'PUT', {
      show_total_grade_as_points: this.options.show_total_grade_as_points
    })
    this.gradebookGrid.invalidate()
    if (this.courseSettings.allowFinalGradeOverride) {
      return this.gradebookGrid.gridSupport.columns.updateColumnHeaders([
        'total_grade',
        'total_grade_override'
      ])
    } else {
      return this.gradebookGrid.gridSupport.columns.updateColumnHeaders(['total_grade'])
    }
  }

  togglePointsOrPercentTotals(cb) {
    let dialog_options
    if (UserSettings.contextGet('warned_about_totals_display')) {
      this.switchTotalDisplay()
      if (typeof cb === 'function') {
        return cb()
      }
    } else {
      dialog_options = {
        showing_points: this.options.show_total_grade_as_points,
        save: this.switchTotalDisplay,
        onClose: cb
      }
      return new GradeDisplayWarningDialog(dialog_options)
    }
  }

  onUserFilterInput(term) {
    this.userFilterTerm = term
    return this.buildRows()
  }

  renderSearchFilter() {
    if (!this.userFilter) {
      this.userFilter = new InputFilterView({
        el: '#search-filter-container input'
      })
      this.userFilter.on('input', this.onUserFilterInput)
    }
    const disabled =
      !this.contentLoadStates.studentsLoaded || !this.contentLoadStates.submissionsLoaded
    this.userFilter.el.disabled = disabled
    return this.userFilter.el.setAttribute('aria-disabled', disabled)
  }

  setVisibleGridColumns() {
    let assignmentGroupId, ref1
    const parentColumnIds = this.gridData.columns.frozen.filter(function (columnId) {
      return !/^custom_col_/.test(columnId)
    })
    const customColumnIds = this.listVisibleCustomColumns().map(column => {
      return this.getCustomColumnId(column.id)
    })
    const assignments = this.filterAssignments(Object.values(this.assignments))
    const scrollableColumns = assignments.map(assignment => {
      return this.gridData.columns.definitions[this.getAssignmentColumnId(assignment.id)]
    })
    if (!this.hideAggregateColumns()) {
      for (assignmentGroupId in this.assignmentGroups) {
        scrollableColumns.push(
          this.gridData.columns.definitions[this.getAssignmentGroupColumnId(assignmentGroupId)]
        )
      }
      if (this.getColumnOrder().freezeTotalGrade) {
        if (!parentColumnIds.includes('total_grade')) {
          parentColumnIds.push('total_grade')
        }
      } else {
        scrollableColumns.push(this.gridData.columns.definitions.total_grade)
      }
      if (this.courseSettings.allowFinalGradeOverride) {
        scrollableColumns.push(this.gridData.columns.definitions.total_grade_override)
      }
    }
    if ((ref1 = this.gradebookColumnOrderSettings) != null ? ref1.sortType : undefined) {
      scrollableColumns.sort(this.makeColumnSortFn(this.getColumnOrder()))
    }
    this.gridData.columns.frozen = [...parentColumnIds, ...customColumnIds]
    return (this.gridData.columns.scrollable = scrollableColumns.map(function (column) {
      return column.id
    }))
  }

  updateGrid() {
    this.gradebookGrid.updateColumns()
    return this.gradebookGrid.invalidate()
  }

  // # Grid Column Definitions

  // Student Column
  buildStudentColumn() {
    let studentColumnWidth
    studentColumnWidth = 150
    if (this.gradebookColumnSizeSettings) {
      if (this.gradebookColumnSizeSettings.student) {
        studentColumnWidth = parseInt(this.gradebookColumnSizeSettings.student, 10)
      }
    }
    return {
      id: 'student',
      type: 'student',
      width: studentColumnWidth,
      cssClass: 'meta-cell primary-column student',
      headerCssClass: 'primary-column student',
      resizable: true
    }
  }

  buildCustomColumn(customColumn) {
    const columnId = this.getCustomColumnId(customColumn.id)
    return {
      id: columnId,
      type: 'custom_column',
      field: `custom_col_${customColumn.id}`,
      width: 100,
      cssClass: `meta-cell custom_column ${columnId}`,
      headerCssClass: `custom_column ${columnId}`,
      resizable: true,
      editor: LongTextEditor,
      customColumnId: customColumn.id,
      autoEdit: false,
      maxLength: 255
    }
  }

  // Assignment Column
  buildAssignmentColumn(assignment) {
    let assignmentWidth
    const shrinkForOutOfText =
      assignment && assignment.grading_type === 'points' && assignment.points_possible != null
    const minWidth = shrinkForOutOfText ? 140 : 90
    const columnId = this.getAssignmentColumnId(assignment.id)
    const fieldName = `assignment_${assignment.id}`
    if (this.gradebookColumnSizeSettings && this.gradebookColumnSizeSettings[fieldName]) {
      assignmentWidth = parseInt(this.gradebookColumnSizeSettings[fieldName], 10)
    } else {
      assignmentWidth = testWidth(assignment.name, minWidth, columnWidths.assignment.default_max)
    }
    const columnDef = {
      id: columnId,
      field: fieldName,
      object: assignment,
      getGridSupport: () => {
        return this.gradebookGrid.gridSupport
      },
      propFactory: new AssignmentRowCellPropFactory(this),
      minWidth: columnWidths.assignment.min,
      maxWidth: columnWidths.assignment.max,
      width: assignmentWidth,
      cssClass: `assignment ${columnId}`,
      headerCssClass: `assignment ${columnId}`,
      toolTip: assignment.name,
      type: 'assignment',
      assignmentId: assignment.id
    }
    if (!(columnDef.width > columnDef.minWidth)) {
      columnDef.cssClass += ' minimized'
      columnDef.headerCssClass += ' minimized'
    }
    return columnDef
  }

  buildAssignmentGroupColumn(assignmentGroup) {
    let width
    const columnId = this.getAssignmentGroupColumnId(assignmentGroup.id)
    const fieldName = `assignment_group_${assignmentGroup.id}`
    if (this.gradebookColumnSizeSettings && this.gradebookColumnSizeSettings[fieldName]) {
      width = parseInt(this.gradebookColumnSizeSettings[fieldName], 10)
    } else {
      width = testWidth(
        assignmentGroup.name,
        columnWidths.assignmentGroup.min,
        columnWidths.assignmentGroup.default_max
      )
    }
    return {
      id: columnId,
      field: fieldName,
      toolTip: assignmentGroup.name,
      object: assignmentGroup,
      minWidth: columnWidths.assignmentGroup.min,
      maxWidth: columnWidths.assignmentGroup.max,
      width,
      cssClass: `meta-cell assignment-group-cell ${columnId}`,
      headerCssClass: `assignment_group ${columnId}`,
      type: 'assignment_group',
      assignmentGroupId: assignmentGroup.id
    }
  }

  buildTotalGradeColumn() {
    let totalWidth
    const label = I18n.t('Total')
    if (this.gradebookColumnSizeSettings && this.gradebookColumnSizeSettings.total_grade) {
      totalWidth = parseInt(this.gradebookColumnSizeSettings.total_grade, 10)
    } else {
      totalWidth = testWidth(label, columnWidths.total.min, columnWidths.total.max)
    }
    return {
      id: 'total_grade',
      field: 'total_grade',
      toolTip: label,
      minWidth: columnWidths.total.min,
      maxWidth: columnWidths.total.max,
      width: totalWidth,
      cssClass: 'total-cell total_grade',
      headerCssClass: 'total_grade',
      type: 'total_grade'
    }
  }

  buildTotalGradeOverrideColumn() {
    let totalWidth
    const label = I18n.t('Override')
    if (this.gradebookColumnSizeSettings && this.gradebookColumnSizeSettings.total_grade_override) {
      totalWidth = parseInt(this.gradebookColumnSizeSettings.total_grade_override, 10)
    } else {
      totalWidth = testWidth(
        label,
        columnWidths.total_grade_override.min,
        columnWidths.total_grade_override.max
      )
    }
    return {
      cssClass: 'total-grade-override',
      getGridSupport: () => {
        return this.gradebookGrid.gridSupport
      },
      headerCssClass: 'total-grade-override',
      id: 'total_grade_override',
      maxWidth: columnWidths.total_grade_override.max,
      minWidth: columnWidths.total_grade_override.min,
      propFactory: new TotalGradeOverrideCellPropFactory(this),
      toolTip: label,
      type: 'total_grade_override',
      width: totalWidth
    }
  }

  initGrid() {
    let assignmentGroup, assignmentGroupColumn, id
    this.updateFilteredContentInfo()
    const studentColumn = this.buildStudentColumn()
    this.gridData.columns.definitions[studentColumn.id] = studentColumn
    this.gridData.columns.frozen.push(studentColumn.id)
    const ref2 = this.assignmentGroups
    for (id in ref2) {
      assignmentGroup = ref2[id]
      assignmentGroupColumn = this.buildAssignmentGroupColumn(assignmentGroup)
      this.gridData.columns.definitions[assignmentGroupColumn.id] = assignmentGroupColumn
    }
    const totalGradeColumn = this.buildTotalGradeColumn()
    this.gridData.columns.definitions[totalGradeColumn.id] = totalGradeColumn
    const totalGradeOverrideColumn = this.buildTotalGradeOverrideColumn()
    this.gridData.columns.definitions[totalGradeOverrideColumn.id] = totalGradeOverrideColumn
    this.renderGridColor()
    return this.createGrid()
  }

  addAssignmentColumnDefinition(assignment) {
    const assignmentColumn = this.buildAssignmentColumn(assignment)
    if (!this.gridData.columns.definitions[assignmentColumn.id]) {
      this.gridData.columns.definitions[assignmentColumn.id] = assignmentColumn
    }
  }

  createGrid() {
    this.setVisibleGridColumns()
    this.gradebookGrid.initialize()
    // This is a faux blur event for SlickGrid.
    // Use capture to preempt SlickGrid's internal handlers.
    document.getElementById('application').addEventListener('click', this.onGridBlur, true)
    // Grid Events
    this.gradebookGrid.grid.onKeyDown.subscribe(onGridKeyDown)
    // Grid Body Cell Events
    this.gradebookGrid.grid.onBeforeEditCell.subscribe(this.onBeforeEditCell)
    this.gradebookGrid.grid.onCellChange.subscribe(this.onCellChange)
    this.keyboardNav = new GradebookKeyboardNav({
      gridSupport: this.gradebookGrid.gridSupport,
      getColumnTypeForColumnId: this.getColumnTypeForColumnId,
      toggleDefaultSort: this.toggleDefaultSort,
      openSubmissionTray: this.openSubmissionTray
    })
    this.gradebookGrid.gridSupport.initialize()
    this.gradebookGrid.gridSupport.events.onActiveLocationChanged.subscribe((event, location) => {
      if (location.columnId === 'student' && location.region === 'body') {
        // In IE11, if we're navigating into the student column from a grade
        // input cell with no text, this focus() call will select the <body>
        // instead of the grades link.  Delaying the call (even with no actual
        // delay) fixes the issue.
        return this.delayedCall(0, () => {
          let ref1
          return (ref1 = this.gradebookGrid.gridSupport.state
            .getActiveNode()
            .querySelector('.student-grades-link')) != null
            ? ref1.focus()
            : undefined
        })
      }
    })
    this.gradebookGrid.gridSupport.events.onKeyDown.subscribe((event, location) => {
      let ref1
      if (location.region === 'header') {
        return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
          ? ref1.handleKeyDown(event)
          : undefined
      }
    })
    this.gradebookGrid.gridSupport.events.onNavigatePrev.subscribe((event, location) => {
      let ref1
      if (location.region === 'header') {
        return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
          ? ref1.focusAtStart()
          : undefined
      }
    })
    this.gradebookGrid.gridSupport.events.onNavigateNext.subscribe((event, location) => {
      let ref1
      if (location.region === 'header') {
        return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
          ? ref1.focusAtStart()
          : undefined
      }
    })
    this.gradebookGrid.gridSupport.events.onNavigateLeft.subscribe((event, location) => {
      let ref1
      if (location.region === 'header') {
        return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
          ? ref1.focusAtStart()
          : undefined
      }
    })
    this.gradebookGrid.gridSupport.events.onNavigateRight.subscribe((event, location) => {
      let ref1
      if (location.region === 'header') {
        return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
          ? ref1.focusAtStart()
          : undefined
      }
    })
    this.gradebookGrid.gridSupport.events.onNavigateUp.subscribe((event, location) => {
      if (location.region === 'header') {
        // As above, "delay" the call so that we properly focus the header cell
        // when navigating from a grade input cell with no text.
        return this.delayedCall(0, () => {
          let ref1
          return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
            ? ref1.focusAtStart()
            : undefined
        })
      }
    })
    return this.onGridInit()
  }

  onGridInit() {
    if (this.spinner) {
      // TODO: this "if @spinner" crap is necessary because the outcome
      // gradebook kicks off the gradebook (unnecessarily).  back when the
      // gradebook was slow, this code worked, but now the spinner may never
      // initialize.  fix the way outcome gradebook loads
      $(this.spinner.el).remove()
    }
    $('#gradebook-grid-wrapper').show()
    this.uid = this.gradebookGrid.grid.getUID()
    $('#accessibility_warning').focus(function () {
      $('#accessibility_warning').removeClass('screenreader-only')
      return $('#accessibility_warning').blur(function () {
        return $('#accessibility_warning').addClass('screenreader-only')
      })
    })
    this.$grid = $('#gradebook_grid').fillWindowWithMe({
      onResize: () => {
        return this.gradebookGrid.grid.resizeCanvas()
      }
    })
    if (this.options.gradebook_is_editable) {
      this.$grid.addClass('editable')
    }
    this.fixMaxHeaderWidth()
    this.keyboardNav.init()
    const keyBindings = this.keyboardNav.keyBindings
    this.kbDialog = new KeyboardNavDialog().render(KeyboardNavTemplate({keyBindings}))
    return $(document).trigger('gridready')
  }

  onBeforeEditCell(event, obj) {
    let ref1
    if (
      obj.column.type === 'custom_column' &&
      ((ref1 = this.getCustomColumn(obj.column.customColumnId)) != null
        ? ref1.read_only
        : undefined)
    ) {
      return false
    }
    if (obj.column.type !== 'assignment') {
      return true
    }
    return !!this.student(obj.item.id)
  }

  onCellChange(_event, obj) {
    let col_id, url
    const {item, column} = obj
    if (column.type === 'custom_column') {
      col_id = column.field.match(/^custom_col_(\d+)/)
      url = this.options.custom_column_datum_url
        .replace(/:id/, col_id[1])
        .replace(/:user_id/, item.id)
      return $.ajaxJSON(url, 'PUT', {
        'column_data[content]': item[column.field]
      })
    } else {
      // this is the magic that actually updates group and final grades when you edit a cell
      this.calculateStudentGrade(item)
      return this.gradebookGrid.invalidate()
    }
  }

  // Persisted Gradebook Settings
  saveColumnWidthPreference(id, newWidth) {
    const url = this.options.gradebook_column_size_settings_url
    return $.ajaxJSON(url, 'POST', {
      column_id: id,
      column_size: newWidth
    })
  }

  saveSettings(
    {
      selectedViewOptionsFilters = this.listSelectedViewOptionsFilters(),
      showConcludedEnrollments = this.getEnrollmentFilters().concluded,
      showInactiveEnrollments = this.getEnrollmentFilters().inactive,
      showUnpublishedAssignments = this.gridDisplaySettings.showUnpublishedAssignments,
      studentColumnDisplayAs = this.getSelectedPrimaryInfo(),
      studentColumnSecondaryInfo = this.getSelectedSecondaryInfo(),
      sortRowsBy = this.getSortRowsBySetting(),
      viewUngradedAsZero = this.gridDisplaySettings.viewUngradedAsZero,
      colors = this.getGridColors()
    } = {},
    successFn,
    errorFn
  ) {
    if (!(selectedViewOptionsFilters.length > 0)) {
      selectedViewOptionsFilters.push('')
    }
    const data = {
      gradebook_settings: {
        enter_grades_as: this.gridDisplaySettings.enterGradesAs,
        filter_columns_by: underscore(this.gridDisplaySettings.filterColumnsBy),
        selected_view_options_filters: selectedViewOptionsFilters,
        show_concluded_enrollments: showConcludedEnrollments,
        show_inactive_enrollments: showInactiveEnrollments,
        show_unpublished_assignments: showUnpublishedAssignments,
        student_column_display_as: studentColumnDisplayAs,
        student_column_secondary_info: studentColumnSecondaryInfo,
        filter_rows_by: underscore(this.gridDisplaySettings.filterRowsBy),
        sort_rows_by_column_id: sortRowsBy.columnId,
        sort_rows_by_setting_key: sortRowsBy.settingKey,
        sort_rows_by_direction: sortRowsBy.direction,
        view_ungraded_as_zero: viewUngradedAsZero,
        colors
      }
    }
    return $.ajaxJSON(this.options.settings_update_url, 'PUT', data, successFn, errorFn)
  }

  // # Grid Sorting Methods
  sortRowsBy(sortFn) {
    const respectorOfPersonsSort = () => {
      if (_(this.studentViewStudents).size()) {
        return (a, b) => {
          if (this.studentViewStudents[a.id]) {
            return 1
          } else if (this.studentViewStudents[b.id]) {
            return -1
          } else {
            return sortFn(a, b)
          }
        }
      } else {
        return sortFn
      }
    }
    this.gridData.rows.sort(respectorOfPersonsSort())
    this.courseContent.students.setStudentIds(_.map(this.gridData.rows, 'id'))
    return this.gradebookGrid.invalidate()
  }

  getColumnTypeForColumnId(columnId) {
    if (columnId.match(/^custom_col/)) {
      return 'custom_column'
    } else if (columnId.match(ASSIGNMENT_KEY_REGEX)) {
      return 'assignment'
    } else if (columnId.match(/^assignment_group/)) {
      return 'assignment_group'
    } else {
      return columnId
    }
  }

  localeSort(a, b, {asc = true, nullsLast = false} = {}) {
    if (nullsLast) {
      if (a != null && b == null) {
        return -1
      }
      if (a == null && b != null) {
        return 1
      }
    }
    if (!asc) {
      ;[b, a] = [a, b]
    }
    return natcompare.strings(a || '', b || '')
  }

  idSort(a, b, {asc = true}) {
    return NumberCompare(Number(a.id), Number(b.id), {
      descending: !asc
    })
  }

  secondaryAndTertiarySort(a, b, {asc = true}) {
    let result
    result = this.localeSort(a.sortable_name, b.sortable_name, {asc})
    if (result === 0) {
      result = this.idSort(a, b, {asc})
    }
    return result
  }

  gradeSort(a, b, field, asc) {
    let result
    const scoreForSorting = student => {
      const grade = getStudentGradeForColumn(student, field)
      if (field === 'total_grade') {
        if (this.options.show_total_grade_as_points) {
          return grade.score
        } else {
          return getGradeAsPercent(grade)
        }
      } else if (field.match(/^assignment_group/)) {
        return getGradeAsPercent(grade)
      } else {
        // TODO: support assignment grading types
        return grade.score
      }
    }
    result = NumberCompare(scoreForSorting(a), scoreForSorting(b), {
      descending: !asc
    })
    if (result === 0) {
      result = this.secondaryAndTertiarySort(a, b, {asc})
    }
    return result
  }

  // when fn is true, those rows get a -1 so they go to the top of the sort
  sortRowsWithFunction(fn, {asc = true} = {}) {
    return this.sortRowsBy((a, b) => {
      let rowA, rowB
      rowA = fn(a)
      rowB = fn(b)
      if (!asc) {
        ;[rowA, rowB] = [rowB, rowA]
      }
      if (rowA > rowB) {
        return -1
      }
      if (rowA < rowB) {
        return 1
      }
      return this.secondaryAndTertiarySort(a, b, {asc})
    })
  }

  missingSort(columnId) {
    return this.sortRowsWithFunction(row => {
      let ref1
      return !!((ref1 = row[columnId]) != null ? ref1.missing : undefined)
    })
  }

  lateSort(columnId) {
    return this.sortRowsWithFunction(row => {
      return row[columnId].late
    })
  }

  sortByStudentColumn(settingKey, direction) {
    return this.sortRowsBy((a, b) => {
      let result
      const asc = direction === 'ascending'
      result = this.localeSort(a[settingKey], b[settingKey], {
        asc,
        nullsLast: true
      })
      if (result === 0) {
        result = this.idSort(a, b, {asc})
      }
      return result
    })
  }

  sortByCustomColumn(columnId, direction) {
    return this.sortRowsBy((a, b) => {
      let result
      const asc = direction === 'ascending'
      result = this.localeSort(a[columnId], b[columnId], {asc})
      if (result === 0) {
        result = this.secondaryAndTertiarySort(a, b, {asc})
      }
      return result
    })
  }

  sortByAssignmentColumn(columnId, settingKey, direction) {
    switch (settingKey) {
      case 'grade':
        return this.sortRowsBy((a, b) => {
          return this.gradeSort(a, b, columnId, direction === 'ascending')
        })
      case 'late':
        return this.lateSort(columnId)
      case 'missing':
        return this.missingSort(columnId)
    }
  }

  sortByAssignmentGroupColumn(columnId, settingKey, direction) {
    if (settingKey === 'grade') {
      return this.sortRowsBy((a, b) => {
        return this.gradeSort(a, b, columnId, direction === 'ascending')
      })
    }
  }

  sortByTotalGradeColumn(direction) {
    return this.sortRowsBy((a, b) => {
      return this.gradeSort(a, b, 'total_grade', direction === 'ascending')
    })
  }

  sortGridRows() {
    const {columnId, settingKey, direction} = this.getSortRowsBySetting()
    const columnType = this.getColumnTypeForColumnId(columnId)
    switch (columnType) {
      case 'custom_column':
        this.sortByCustomColumn(columnId, direction)
        break
      case 'assignment':
        this.sortByAssignmentColumn(columnId, settingKey, direction)
        break
      case 'assignment_group':
        this.sortByAssignmentGroupColumn(columnId, settingKey, direction)
        break
      case 'total_grade':
        this.sortByTotalGradeColumn(direction)
        break
      default:
        this.sortByStudentColumn(settingKey, direction)
    }
    return this.updateColumnHeaders()
  }

  updateStudentRow(student) {
    const index = this.gridData.rows.findIndex(row => {
      return row.id === student.id
    })
    if (index !== -1) {
      this.gridData.rows[index] = this.buildRow(student)
      return this.gradebookGrid.invalidateRow(index)
    }
  }

  updateFilteredContentInfo() {
    let assignment, assignmentId, invalidAssignmentGroups
    const unorderedAssignments = function () {
      const ref1 = this.assignments
      const results = []
      for (assignmentId in ref1) {
        assignment = ref1[assignmentId]
        results.push(assignment)
      }
      return results
    }.call(this)
    const filteredAssignments = this.filterAssignments(unorderedAssignments)
    this.filteredContentInfo.totalPointsPossible = _.reduce(
      this.assignmentGroups,
      function (sum, assignmentGroup) {
        return sum + getAssignmentGroupPointsPossible(assignmentGroup)
      },
      0
    )
    if (this.weightedGroups()) {
      invalidAssignmentGroups = _.filter(this.assignmentGroups, function (ag) {
        return getAssignmentGroupPointsPossible(ag) === 0
      })
      return (this.filteredContentInfo.invalidAssignmentGroups = invalidAssignmentGroups)
    } else {
      return (this.filteredContentInfo.invalidAssignmentGroups = [])
    }
  }

  listInvalidAssignmentGroups() {
    return this.filteredContentInfo.invalidAssignmentGroups
  }

  listHiddenAssignments(studentId) {
    if (!(this.contentLoadStates.submissionsLoaded && this.assignmentsLoadedForCurrentView())) {
      return []
    }

    const assignmentsToConsider = this.filterAssignments(Object.values(this.assignments))
    return assignmentsToConsider.filter(assignment => {
      const submission = this.getSubmission(studentId, assignment.id)
      // Ignore anonymous assignments when deciding whether to show the
      // "hidden" icon, as including them could reveal which students have
      // and have not been graded.
      // Ignore 'not_graded' assignments as they are not counted into the
      // student's grade, nor are they visible in the Gradebook.
      return (
        submission != null &&
        isPostable(submission) &&
        !assignment.anonymize_students &&
        assignment.grading_type !== 'not_graded'
      )
    })
  }

  getTotalPointsPossible() {
    return this.filteredContentInfo.totalPointsPossible
  }

  handleColumnHeaderMenuClose() {
    return this.keyboardNav.handleMenuOrDialogClose()
  }

  toggleNotesColumn() {
    const parentColumnIds = this.gridData.columns.frozen.filter(function (columnId) {
      return !/^custom_col_/.test(columnId)
    })
    const customColumnIds = this.listVisibleCustomColumns().map(column => {
      return this.getCustomColumnId(column.id)
    })
    this.gridData.columns.frozen = [...parentColumnIds, ...customColumnIds]
    return this.updateGrid()
  }

  showNotesColumn() {
    let ref1
    if (this.teacherNotesNotYetLoaded) {
      this.teacherNotesNotYetLoaded = false
      this.dataLoader.loadCustomColumnData(this.getTeacherNotesColumn().id)
    }
    if ((ref1 = this.getTeacherNotesColumn()) != null) {
      ref1.hidden = false
    }
    return this.toggleNotesColumn()
  }

  hideNotesColumn() {
    let ref1
    if ((ref1 = this.getTeacherNotesColumn()) != null) {
      ref1.hidden = true
    }
    return this.toggleNotesColumn()
  }

  hideAggregateColumns() {
    if (this.gradingPeriodSet == null) {
      return false
    }
    if (this.gradingPeriodSet.displayTotalsForAllGradingPeriods) {
      return false
    }
    return !this.isFilteringColumnsByGradingPeriod()
  }

  getCustomColumnId(customColumnId) {
    return `custom_col_${customColumnId}`
  }

  getAssignmentColumnId(assignmentId) {
    return `assignment_${assignmentId}`
  }

  getAssignmentGroupColumnId(assignmentGroupId) {
    return `assignment_group_${assignmentGroupId}`
  }

  listRows() {
    return this.gridData.rows // currently the source of truth for filtered and sorted rows
  }

  listRowIndicesForStudentIds(studentIds) {
    const rowIndicesByStudentId = this.listRows().reduce((map, row, index) => {
      map[row.id] = index
      return map
    }, {})
    return studentIds.map(studentId => {
      return rowIndicesByStudentId[studentId]
    })
  }

  updateRowCellsForStudentIds(studentIds) {
    let column, columnIndex, j, k, len, len1, rowIndex
    if (!this.gradebookGrid.grid) {
      return
    }
    // Update each row without entirely replacing the DOM elements.
    // This is needed to preserve the editor for the active cell, when present.
    const rowIndices = this.listRowIndicesForStudentIds(studentIds)
    const columns = this.gradebookGrid.grid.getColumns()
    for (j = 0, len = rowIndices.length; j < len; j++) {
      rowIndex = rowIndices[j]
      for (columnIndex = k = 0, len1 = columns.length; k < len1; columnIndex = ++k) {
        column = columns[columnIndex]
        this.gradebookGrid.grid.updateCell(rowIndex, columnIndex)
      }
    }
    return null // skip building an unused array return value
  }

  invalidateRowsForStudentIds(studentIds) {
    let j, len, rowIndex
    const rowIndices = this.listRowIndicesForStudentIds(studentIds)
    for (j = 0, len = rowIndices.length; j < len; j++) {
      rowIndex = rowIndices[j]
      if (rowIndex != null) {
        this.gradebookGrid.invalidateRow(rowIndex)
      }
    }
    this.gradebookGrid.render()
    return null // skip building an unused array return value
  }

  updateTotalGradeColumn() {
    this.updateColumnWithId('total_grade')
  }

  updateAllTotalColumns() {
    this.updateTotalGradeColumn()

    Object.keys(this.assignmentGroups).forEach(assignmentGroupId => {
      this.updateColumnWithId(`assignment_group_${assignmentGroupId}`)
    })
  }

  updateColumnWithId(id) {
    let j, len, rowIndex
    if (this.gradebookGrid.grid == null) {
      return
    }
    const columnIndex = this.gradebookGrid.grid.getColumns().findIndex(column => column.id === id)
    if (columnIndex === -1) {
      return
    }
    const ref1 = this.listRowIndicesForStudentIds(this.courseContent.students.listStudentIds())
    for (j = 0, len = ref1.length; j < len; j++) {
      rowIndex = ref1[j]
      if (rowIndex != null) {
        this.gradebookGrid.grid.updateCell(rowIndex, columnIndex)
      }
    }
    return null // skip building an unused array return value
  }

  updateColumns() {
    this.setVisibleGridColumns()
    this.gradebookGrid.updateColumns()
    return this.updateColumnHeaders()
  }

  updateColumnsAndRenderViewOptionsMenu() {
    this.updateColumns()
    return this.renderViewOptionsMenu()
  }

  updateColumnsAndRenderGradebookSettingsModal() {
    this.updateColumns()
    return this.renderGradebookSettingsModal()
  }

  setHeaderComponentRef(columnId, ref) {
    return (this.headerComponentRefs[columnId] = ref)
  }

  getHeaderComponentRef(columnId) {
    return this.headerComponentRefs[columnId]
  }

  removeHeaderComponentRef(columnId) {
    return delete this.headerComponentRefs[columnId]
  }

  updateColumnHeaders(columnIds = []) {
    let ref1
    return (ref1 = this.gradebookGrid.gridSupport) != null
      ? ref1.columns.updateColumnHeaders(columnIds)
      : undefined
  }

  handleHeaderKeyDown(e, columnId) {
    return this.gradebookGrid.gridSupport.navigation.handleHeaderKeyDown(e, {
      region: 'header',
      cell: this.gradebookGrid.grid.getColumnIndex(columnId),
      columnId
    })
  }

  freezeTotalGradeColumn() {
    this.totalColumnPositionChanged = true
    this.gradebookColumnOrderSettings.freezeTotalGrade = true
    const studentColumnPosition = this.gridData.columns.frozen.indexOf('student')
    this.gridData.columns.frozen.splice(studentColumnPosition + 1, 0, 'total_grade')
    this.gridData.columns.scrollable = this.gridData.columns.scrollable.filter(function (columnId) {
      return columnId !== 'total_grade'
    })
    this.saveColumnOrder()
    this.updateGrid()
    this.updateColumnHeaders()
    return this.gradebookGrid.gridSupport.columns.scrollToStart()
  }

  moveTotalGradeColumnToEnd() {
    this.totalColumnPositionChanged = true
    this.gradebookColumnOrderSettings.freezeTotalGrade = false
    this.gridData.columns.frozen = this.gridData.columns.frozen.filter(function (columnId) {
      return columnId !== 'total_grade'
    })
    this.gridData.columns.scrollable = this.gridData.columns.scrollable.filter(function (columnId) {
      return columnId !== 'total_grade'
    })
    this.gridData.columns.scrollable.push('total_grade')
    if (this.getColumnOrder().sortType === 'custom') {
      this.saveCustomColumnOrder()
    } else {
      this.saveColumnOrder()
    }
    this.updateGrid()
    this.updateColumnHeaders()
    return this.gradebookGrid.gridSupport.columns.scrollToEnd()
  }

  totalColumnShouldFocus() {
    if (this.totalColumnPositionChanged) {
      this.totalColumnPositionChanged = false
      return true
    } else {
      return false
    }
  }

  assignmentColumns() {
    return this.gradebookGrid.gridSupport.grid.getColumns().filter(column => {
      return column.type === 'assignment'
    })
  }

  navigateAssignment(direction) {
    let assignment, curAssignment, i, j, len, ref1, ref2, ref3
    const location = this.gradebookGrid.gridSupport.state.getActiveLocation()
    const columns = this.gradebookGrid.grid.getColumns()
    const range =
      direction === 'next'
        ? function () {
            const results = []
            for (
              let j = (ref1 = location.cell + 1), ref2 = columns.length;
              ref1 <= ref2 ? j <= ref2 : j >= ref2;
              ref1 <= ref2 ? j++ : j--
            ) {
              results.push(j)
            }
            return results
          }.apply(this)
        : function () {
            const results = []
            for (
              let j = (ref3 = location.cell - 1);
              ref3 <= 0 ? j < 0 : j > 0;
              ref3 <= 0 ? j++ : j--
            ) {
              results.push(j)
            }
            return results
          }.apply(this)
    assignment
    for (j = 0, len = range.length; j < len; j++) {
      i = range[j]
      curAssignment = columns[i]
      if (curAssignment.id.match(/^assignment_(?!group)/)) {
        this.gradebookGrid.gridSupport.state.setActiveLocation('body', {
          row: location.row,
          cell: i
        })
        assignment = curAssignment
        break
      }
    }
    return assignment
  }

  loadTrayStudent(direction) {
    const location = this.gradebookGrid.gridSupport.state.getActiveLocation()
    const rowDelta = direction === 'next' ? 1 : -1
    const newRowIdx = location.row + rowDelta
    const student = this.listRows()[newRowIdx]
    if (!student) {
      return
    }
    this.gradebookGrid.gridSupport.state.setActiveLocation('body', {
      row: newRowIdx,
      cell: location.cell
    })
    this.setSubmissionTrayState(true, student.id)
    return this.updateRowAndRenderSubmissionTray(student.id)
  }

  loadTrayAssignment(direction) {
    const studentId = this.getSubmissionTrayState().studentId
    const assignment = this.navigateAssignment(direction)
    if (!assignment) {
      return
    }
    this.setSubmissionTrayState(true, studentId, assignment.assignmentId)
    return this.updateRowAndRenderSubmissionTray(studentId)
  }

  getSubmissionTrayProps(student) {
    const {open, studentId, assignmentId, comments, editedCommentId} = this.getSubmissionTrayState()
    student || (student = this.student(studentId))
    // get the student's submission, or use a fake submission object in case the
    // submission has not yet loaded
    const fakeSubmission = {
      assignment_id: assignmentId,
      late: false,
      missing: false,
      excused: false,
      seconds_late: 0
    }
    const submission = this.getSubmission(studentId, assignmentId) || fakeSubmission
    const assignment = this.getAssignment(assignmentId)
    const activeLocation = this.gradebookGrid.gridSupport.state.getActiveLocation()
    const cell = activeLocation.cell
    const columns = this.gradebookGrid.gridSupport.grid.getColumns()
    const currentColumn = columns[cell]
    const assignmentColumns = this.assignmentColumns()
    const currentAssignmentIdx = assignmentColumns.indexOf(currentColumn)
    const isFirstAssignment = currentAssignmentIdx === 0
    const isLastAssignment = currentAssignmentIdx === assignmentColumns.length - 1
    const isFirstStudent = activeLocation.row === 0
    const isLastStudent = activeLocation.row === this.listRows().length - 1
    const submissionState = this.submissionStateMap.getSubmissionState({
      user_id: studentId,
      assignment_id: assignmentId
    })
    const isGroupWeightZero =
      this.assignmentGroups[assignment.assignment_group_id].group_weight === 0
    return {
      assignment: camelize(assignment),
      colors: this.getGridColors(),
      comments,
      courseId: this.options.context_id,
      currentUserId: this.options.currentUserId,
      enterGradesAs: this.getEnterGradesAsSetting(assignmentId),
      gradingDisabled:
        !!(submissionState != null ? submissionState.locked : undefined) || student.isConcluded,
      gradingScheme: this.getAssignmentGradingScheme(assignmentId).data,
      isFirstAssignment,
      isInOtherGradingPeriod: !!(submissionState != null
        ? submissionState.inOtherGradingPeriod
        : undefined),
      isInClosedGradingPeriod: !!(submissionState != null
        ? submissionState.inClosedGradingPeriod
        : undefined),
      isInNoGradingPeriod: !!(submissionState != null
        ? submissionState.inNoGradingPeriod
        : undefined),
      isLastAssignment,
      isFirstStudent,
      isLastStudent,
      isNotCountedForScore:
        assignment.omit_from_final_grade ||
        (this.options.group_weighting_scheme === 'percent' && isGroupWeightZero),
      isOpen: open,
      key: 'grade_details_tray',
      latePolicy: this.courseContent.latePolicy,
      locale: this.options.locale,
      onAnonymousSpeedGraderClick: this.showAnonymousSpeedGraderAlertForURL,
      onClose: () => {
        return this.gradebookGrid.gridSupport.helper.focus()
      },
      onGradeSubmission: this.gradeSubmission,
      onRequestClose: this.closeSubmissionTray,
      pendingGradeInfo: this.getPendingGradeInfo({
        assignmentId,
        userId: studentId
      }),
      requireStudentGroupForSpeedGrader: this.requireStudentGroupForSpeedGrader(assignment),
      selectNextAssignment: () => {
        return this.loadTrayAssignment('next')
      },
      selectPreviousAssignment: () => {
        return this.loadTrayAssignment('previous')
      },
      selectNextStudent: () => {
        return this.loadTrayStudent('next')
      },
      selectPreviousStudent: () => {
        return this.loadTrayStudent('previous')
      },
      showSimilarityScore: this.options.show_similarity_score,
      speedGraderEnabled: this.options.speed_grader_enabled,
      student: {
        id: student.id,
        name: htmlDecode(student.name),
        avatarUrl: htmlDecode(student.avatar_url),
        gradesUrl: `${student.enrollments[0].grades.html_url}#tab-assignments`,
        isConcluded: student.isConcluded
      },
      submission: camelize(submission),
      submissionUpdating: this.submissionIsUpdating({
        assignmentId,
        userId: studentId
      }),
      updateSubmission: this.updateSubmissionAndRenderSubmissionTray,
      processing: this.getCommentsUpdating(),
      setProcessing: this.setCommentsUpdating,
      createSubmissionComment: this.apiCreateSubmissionComment,
      updateSubmissionComment: this.apiUpdateSubmissionComment,
      deleteSubmissionComment: this.apiDeleteSubmissionComment,
      editSubmissionComment: this.editSubmissionComment,
      submissionComments: this.getSubmissionComments(),
      submissionCommentsLoaded: this.getSubmissionCommentsLoaded(),
      editedCommentId
    }
  }

  renderSubmissionTray(student) {
    const {open, studentId, assignmentId} = this.getSubmissionTrayState()
    const mountPoint = document.getElementById('StudentTray__Container')
    const props = this.getSubmissionTrayProps(student)
    if (!this.getSubmissionCommentsLoaded() && open) {
      this.loadSubmissionComments(assignmentId, studentId)
    }
    return AsyncComponents.renderGradeDetailTray(props, mountPoint)
  }

  loadSubmissionComments(assignmentId, studentId) {
    return SubmissionCommentApi.getSubmissionComments(
      this.options.context_id,
      assignmentId,
      studentId
    )
      .then(comments => {
        this.setSubmissionCommentsLoaded(true)
        return this.updateSubmissionComments(comments)
      })
      .catch(FlashAlert.showFlashError(I18n.t('There was an error fetching Submission Comments')))
  }

  updateRowAndRenderSubmissionTray(studentId) {
    this.unloadSubmissionComments()
    this.updateRowCellsForStudentIds([studentId])
    return this.renderSubmissionTray(this.student(studentId))
  }

  toggleSubmissionTrayOpen(studentId, assignmentId) {
    this.setSubmissionTrayState(!this.getSubmissionTrayState().open, studentId, assignmentId)
    return this.updateRowAndRenderSubmissionTray(studentId)
  }

  openSubmissionTray(studentId, assignmentId) {
    this.setSubmissionTrayState(true, studentId, assignmentId)
    return this.updateRowAndRenderSubmissionTray(studentId)
  }

  closeSubmissionTray() {
    this.setSubmissionTrayState(false)
    const rowIndex = this.gradebookGrid.grid.getActiveCell().row
    const studentId = this.gridData.rows[rowIndex].id
    this.updateRowAndRenderSubmissionTray(studentId)
    return this.gradebookGrid.gridSupport.helper.beginEdit()
  }

  getSubmissionTrayState() {
    return this.gridDisplaySettings.submissionTray
  }

  setSubmissionTrayState(open, studentId, assignmentId) {
    this.gridDisplaySettings.submissionTray.open = open
    if (studentId) {
      this.gridDisplaySettings.submissionTray.studentId = studentId
    }
    if (assignmentId) {
      this.gridDisplaySettings.submissionTray.assignmentId = assignmentId
    }
    if (open) {
      return this.gradebookGrid.gridSupport.helper.commitCurrentEdit()
    }
  }

  setCommentsUpdating(status) {
    return (this.gridDisplaySettings.submissionTray.commentsUpdating = !!status)
  }

  getCommentsUpdating() {
    return this.gridDisplaySettings.submissionTray.commentsUpdating
  }

  setSubmissionComments(comments) {
    return (this.gridDisplaySettings.submissionTray.comments = comments)
  }

  updateSubmissionComments(comments) {
    this.setSubmissionComments(comments)
    this.setEditedCommentId(null)
    this.setCommentsUpdating(false)
    return this.renderSubmissionTray()
  }

  unloadSubmissionComments() {
    this.setSubmissionComments([])
    return this.setSubmissionCommentsLoaded(false)
  }

  apiCreateSubmissionComment(comment) {
    const {assignmentId, studentId} = this.getSubmissionTrayState()
    const assignment = this.getAssignment(assignmentId)
    const groupComment = assignmentHelper.gradeByGroup(assignment) ? 1 : 0
    const commentData = {
      group_comment: groupComment,
      text_comment: comment
    }
    return SubmissionCommentApi.createSubmissionComment(
      this.options.context_id,
      assignmentId,
      studentId,
      commentData
    )
      .then(this.updateSubmissionComments)
      .then(FlashAlert.showFlashSuccess(I18n.t('Successfully saved the comment')))
      .catch(() => {
        return this.setCommentsUpdating(false)
      })
      .catch(FlashAlert.showFlashError(I18n.t('There was a problem saving the comment')))
  }

  apiUpdateSubmissionComment(updatedComment, commentId) {
    return SubmissionCommentApi.updateSubmissionComment(commentId, updatedComment)
      .then(response => {
        const {id, comment, editedAt} = response.data
        const comments = this.getSubmissionComments().map(submissionComment => {
          if (submissionComment.id === id) {
            return {...submissionComment, comment, editedAt}
          } else {
            return submissionComment
          }
        })
        this.updateSubmissionComments(comments)
        return FlashAlert.showFlashSuccess(I18n.t('Successfully updated the comment'))()
      })
      .catch(FlashAlert.showFlashError(I18n.t('There was a problem updating the comment')))
  }

  apiDeleteSubmissionComment(commentId) {
    return SubmissionCommentApi.deleteSubmissionComment(commentId)
      .then(this.removeSubmissionComment(commentId))
      .then(FlashAlert.showFlashSuccess(I18n.t('Successfully deleted the comment')))
      .catch(FlashAlert.showFlashError(I18n.t('There was a problem deleting the comment')))
  }

  editSubmissionComment(commentId) {
    this.setEditedCommentId(commentId)
    return this.renderSubmissionTray()
  }

  setEditedCommentId(id) {
    return (this.gridDisplaySettings.submissionTray.editedCommentId = id)
  }

  getSubmissionComments() {
    return this.gridDisplaySettings.submissionTray.comments
  }

  removeSubmissionComment(commentId) {
    const comments = _.reject(this.getSubmissionComments(), c => {
      return c.id === commentId
    })
    return this.updateSubmissionComments(comments)
  }

  setSubmissionCommentsLoaded(loaded) {
    return (this.gridDisplaySettings.submissionTray.commentsLoaded = loaded)
  }

  getSubmissionCommentsLoaded() {
    return this.gridDisplaySettings.submissionTray.commentsLoaded
  }

  initShowUnpublishedAssignments(showUnpublishedAssignments = 'true') {
    return (this.gridDisplaySettings.showUnpublishedAssignments =
      showUnpublishedAssignments === 'true')
  }

  toggleUnpublishedAssignments() {
    const toggleableAction = () => {
      this.gridDisplaySettings.showUnpublishedAssignments = !this.gridDisplaySettings
        .showUnpublishedAssignments
      return this.updateColumnsAndRenderViewOptionsMenu()
    }
    toggleableAction()
    return this.saveSettings(
      {
        showUnpublishedAssignments: this.gridDisplaySettings.showUnpublishedAssignments
      },
      () => {},
      toggleableAction
    ) // on success, do nothing since the render happened earlier
  }

  confirmViewUngradedAsZero() {
    const showDialog = () =>
      showConfirmationDialog({
        body: I18n.t(
          'This setting only affects your view of student grades and displays grades as if all ungraded assignments were given a score of zero. This setting is a visual change only and does not affect grades for students or other users of this Gradebook. When this setting is enabled, Canvas will not populate zeros in the Gradebook for student submissions within individual assignments. Only the assignment groups and total columns will automatically factor scores of zero into the overall percentages for each student.'
        ),
        confirmText: I18n.t('OK'),
        label: I18n.t('View Ungraded as Zero')
      })

    const confirmationPromise = this.gridDisplaySettings.viewUngradedAsZero
      ? Promise.resolve(true)
      : showDialog()

    return confirmationPromise.then(userAccepted => {
      if (userAccepted) {
        this.toggleViewUngradedAsZero()
      }
    })
  }

  toggleViewUngradedAsZero() {
    const toggleableAction = () => {
      this.gridDisplaySettings.viewUngradedAsZero = !this.gridDisplaySettings.viewUngradedAsZero
      this.updateColumnsAndRenderViewOptionsMenu()

      this.courseContent.students.listStudents().forEach(student => {
        this.calculateStudentGrade(student, true)
      })
      this.updateAllTotalColumns()
    }
    toggleableAction()
    this.saveSettings(
      {viewUngradedAsZero: this.gridDisplaySettings.viewUngradedAsZero},
      () => {},
      toggleableAction
    ) // on success, do nothing since the render happened earlier
  }

  assignmentsLoadedForCurrentView() {
    const gradingPeriodId = this.gradingPeriodId
    const loadStates = this.contentLoadStates.assignmentsLoaded
    if (loadStates.all || gradingPeriodId === '0') {
      return loadStates.all
    }

    return loadStates.gradingPeriod[gradingPeriodId]
  }

  setAssignmentsLoaded(gradingPeriodIds) {
    const {assignmentsLoaded} = this.contentLoadStates
    if (!gradingPeriodIds) {
      assignmentsLoaded.all = true
      Object.keys(assignmentsLoaded.gradingPeriod).forEach(periodId => {
        assignmentsLoaded.gradingPeriod[periodId] = true
      })
      return
    }

    gradingPeriodIds.forEach(id => (assignmentsLoaded.gradingPeriod[id] = true))
    if (Object.values(assignmentsLoaded.gradingPeriod).every(loaded => loaded)) {
      assignmentsLoaded.all = true
    }
  }

  setAssignmentGroupsLoaded(loaded) {
    return (this.contentLoadStates.assignmentGroupsLoaded = loaded)
  }

  setContextModulesLoaded(loaded) {
    return (this.contentLoadStates.contextModulesLoaded = loaded)
  }

  setCustomColumnsLoaded(loaded) {
    return (this.contentLoadStates.customColumnsLoaded = loaded)
  }

  setGradingPeriodAssignmentsLoaded(loaded) {
    return (this.contentLoadStates.gradingPeriodAssignmentsLoaded = loaded)
  }

  setStudentIdsLoaded(loaded) {
    return (this.contentLoadStates.studentIdsLoaded = loaded)
  }

  setStudentsLoaded(loaded) {
    return (this.contentLoadStates.studentsLoaded = loaded)
  }

  setSubmissionsLoaded(loaded) {
    return (this.contentLoadStates.submissionsLoaded = loaded)
  }

  isGradeEditable(studentId, assignmentId) {
    if (!this.isStudentGradeable(studentId)) {
      return false
    }
    const submissionState = this.submissionStateMap.getSubmissionState({
      assignment_id: assignmentId,
      user_id: studentId
    })
    return submissionState != null && !submissionState.locked
  }

  isGradeVisible(studentId, assignmentId) {
    const submissionState = this.submissionStateMap.getSubmissionState({
      assignment_id: assignmentId,
      user_id: studentId
    })
    return submissionState != null && !submissionState.hideGrade
  }

  isStudentGradeable(studentId) {
    const student = this.student(studentId)
    return !(!student || student.isConcluded)
  }

  studentCanReceiveGradeOverride(studentId) {
    return this.isStudentGradeable(studentId) && this.studentHasGradedSubmission(studentId)
  }

  studentHasGradedSubmission(studentId) {
    const student = this.student(studentId)
    const submissions = this.submissionsForStudent(student)
    if (!(submissions.length > 0)) {
      return false
    }
    return submissions.some(function (submission) {
      // A submission is graded if either:
      // - it has a score and the workflow state is 'graded'
      // - it is excused
      return (
        submission.excused || (submission.score != null && submission.workflow_state === 'graded')
      )
    })
  }

  addPendingGradeInfo(submission, gradeInfo) {
    const {userId, assignmentId} = submission
    const pendingGradeInfo = {assignmentId, userId, ...gradeInfo}
    this.removePendingGradeInfo(submission)
    return this.actionStates.pendingGradeInfo.push(pendingGradeInfo)
  }

  removePendingGradeInfo(submission) {
    return (this.actionStates.pendingGradeInfo = _.reject(
      this.actionStates.pendingGradeInfo,
      function (info) {
        return info.userId === submission.userId && info.assignmentId === submission.assignmentId
      }
    ))
  }

  getPendingGradeInfo(submission) {
    return (
      this.actionStates.pendingGradeInfo.find(function (info) {
        return info.userId === submission.userId && info.assignmentId === submission.assignmentId
      }) || null
    )
  }

  submissionIsUpdating(submission) {
    let ref1
    return Boolean((ref1 = this.getPendingGradeInfo(submission)) != null ? ref1.valid : undefined)
  }

  setTeacherNotesColumnUpdating(updating) {
    return (this.contentLoadStates.teacherNotesColumnUpdating = updating)
  }

  setOverridesColumnUpdating(updating) {
    return (this.contentLoadStates.overridesColumnUpdating = updating)
  }

  getFilterColumnsBySetting(filterKey) {
    return this.gridDisplaySettings.filterColumnsBy[filterKey]
  }

  setFilterColumnsBySetting(filterKey, value) {
    return (this.gridDisplaySettings.filterColumnsBy[filterKey] = value)
  }

  getFilterRowsBySetting(filterKey) {
    return this.gridDisplaySettings.filterRowsBy[filterKey]
  }

  setFilterRowsBySetting(filterKey, value) {
    return (this.gridDisplaySettings.filterRowsBy[filterKey] = value)
  }

  isFilteringColumnsByAssignmentGroup() {
    return this.getAssignmentGroupToShow() !== '0'
  }

  getModuleToShow() {
    const moduleId = this.getFilterColumnsBySetting('contextModuleId')
    if (moduleId == null || !this.listContextModules().some(module => module.id === moduleId)) {
      return '0'
    }
    return moduleId
  }

  getAssignmentGroupToShow() {
    const groupId = this.getFilterColumnsBySetting('assignmentGroupId') || '0'
    if (indexOf.call(_.pluck(this.assignmentGroups, 'id'), groupId) >= 0) {
      return groupId
    } else {
      return '0'
    }
  }

  isFilteringColumnsByGradingPeriod() {
    return this.gradingPeriodId !== '0'
  }

  isFilteringRowsBySearchTerm() {
    return this.userFilterTerm != null && this.userFilterTerm !== ''
  }

  setCurrentGradingPeriod() {
    if (this.gradingPeriodSet == null) {
      this.gradingPeriodId = '0'
      return
    }

    const periodId =
      this.getFilterColumnsBySetting('gradingPeriodId') || this.options.current_grading_period_id

    if (this.gradingPeriodSet.gradingPeriods.some(period => period.id === periodId)) {
      this.gradingPeriodId = periodId
    } else {
      this.gradingPeriodId = '0'
    }
  }

  getGradingPeriod(gradingPeriodId) {
    let ref1
    return (((ref1 = this.gradingPeriodSet) != null ? ref1.gradingPeriods : undefined) || []).find(
      gradingPeriod => {
        return gradingPeriod.id === gradingPeriodId
      }
    )
  }

  setSelectedPrimaryInfo(primaryInfo, skipRedraw) {
    this.gridDisplaySettings.selectedPrimaryInfo = primaryInfo
    this.saveSettings()
    if (!skipRedraw) {
      this.buildRows()
      return this.gradebookGrid.gridSupport.columns.updateColumnHeaders(['student'])
    }
  }

  toggleDefaultSort(columnId) {
    let direction
    const sortSettings = this.getSortRowsBySetting()
    const columnType = this.getColumnTypeForColumnId(columnId)
    const settingKey = this.getDefaultSettingKeyForColumnType(columnType)
    direction = 'ascending'
    if (
      sortSettings.columnId === columnId &&
      sortSettings.settingKey === settingKey &&
      sortSettings.direction === 'ascending'
    ) {
      direction = 'descending'
    }
    return this.setSortRowsBySetting(columnId, settingKey, direction)
  }

  getDefaultSettingKeyForColumnType(columnType) {
    if (
      columnType === 'assignment' ||
      columnType === 'assignment_group' ||
      columnType === 'total_grade'
    ) {
      return 'grade'
    } else if (columnType === 'student') {
      return 'sortable_name'
    }
  }

  getSelectedPrimaryInfo() {
    return this.gridDisplaySettings.selectedPrimaryInfo
  }

  setSelectedSecondaryInfo(secondaryInfo, skipRedraw) {
    this.gridDisplaySettings.selectedSecondaryInfo = secondaryInfo
    this.saveSettings()
    if (!skipRedraw) {
      this.buildRows()
      return this.gradebookGrid.gridSupport.columns.updateColumnHeaders(['student'])
    }
  }

  getSelectedSecondaryInfo() {
    return this.gridDisplaySettings.selectedSecondaryInfo
  }

  setSortRowsBySetting(columnId, settingKey, direction) {
    this.gridDisplaySettings.sortRowsBy.columnId = columnId
    this.gridDisplaySettings.sortRowsBy.settingKey = settingKey
    this.gridDisplaySettings.sortRowsBy.direction = direction
    this.saveSettings()
    return this.sortGridRows()
  }

  getSortRowsBySetting() {
    return this.gridDisplaySettings.sortRowsBy
  }

  updateGridColors(colors, successFn, errorFn) {
    const setAndRenderColors = () => {
      this.setGridColors(colors)
      this.renderGridColor()
      return successFn()
    }
    return this.saveSettings({colors}, setAndRenderColors, errorFn)
  }

  setGridColors(colors) {
    return (this.gridDisplaySettings.colors = colors)
  }

  getGridColors() {
    return statusColors(this.gridDisplaySettings.colors)
  }

  listAvailableViewOptionsFilters() {
    const filters = []
    if (Object.keys(this.assignmentGroups || {}).length > 1) {
      filters.push('assignmentGroups')
    }
    if (this.gradingPeriodSet != null) {
      filters.push('gradingPeriods')
    }
    if (this.listContextModules().length > 0) {
      filters.push('modules')
    }
    if (this.sections_enabled) {
      filters.push('sections')
    }
    if (this.studentGroupsEnabled) {
      filters.push('studentGroups')
    }
    return filters
  }

  setSelectedViewOptionsFilters(filters) {
    return (this.gridDisplaySettings.selectedViewOptionsFilters = filters)
  }

  listSelectedViewOptionsFilters() {
    return this.gridDisplaySettings.selectedViewOptionsFilters
  }

  toggleEnrollmentFilter(enrollmentFilter, skipApply) {
    this.getEnrollmentFilters()[enrollmentFilter] = !this.getEnrollmentFilters()[enrollmentFilter]
    if (!skipApply) {
      return this.applyEnrollmentFilter()
    }
  }

  updateStudentHeadersAndReloadData() {
    this.gradebookGrid.gridSupport.columns.updateColumnHeaders(['student'])
    return this.dataLoader.reloadStudentDataForEnrollmentFilterChange()
  }

  applyEnrollmentFilter() {
    const showInactive = this.getEnrollmentFilters().inactive
    const showConcluded = this.getEnrollmentFilters().concluded
    return this.saveSettings({showInactive, showConcluded}, this.updateStudentHeadersAndReloadData)
  }

  getEnrollmentFilters() {
    return this.gridDisplaySettings.showEnrollments
  }

  getSelectedEnrollmentFilters() {
    let filter
    const filters = this.getEnrollmentFilters()
    const selectedFilters = []
    for (filter in filters) {
      if (filters[filter]) {
        selectedFilters.push(filter)
      }
    }
    return selectedFilters
  }

  setEnterGradesAsSetting(assignmentId, setting) {
    return (this.gridDisplaySettings.enterGradesAs[assignmentId] = setting)
  }

  getEnterGradesAsSetting(assignmentId) {
    const gradingType = this.getAssignment(assignmentId).grading_type
    const options = EnterGradesAsSetting.optionsForGradingType(gradingType)
    if (!options.length) {
      return null
    }
    const setting = this.gridDisplaySettings.enterGradesAs[assignmentId]
    if (options.includes(setting)) {
      return setting
    }
    return EnterGradesAsSetting.defaultOptionForGradingType(gradingType)
  }

  updateEnterGradesAsSetting(assignmentId, value) {
    this.setEnterGradesAsSetting(assignmentId, value)
    return this.saveSettings({}, () => {
      this.gradebookGrid.gridSupport.columns.updateColumnHeaders([
        this.getAssignmentColumnId(assignmentId)
      ])
      return this.gradebookGrid.invalidate()
    })
  }

  postAssignmentGradesTrayOpenChanged({assignmentId, isOpen}) {
    const columnId = this.getAssignmentColumnId(assignmentId)
    const definition = this.gridData.columns.definitions[columnId]
    if (!(definition && definition.type === 'assignment')) {
      return
    }
    definition.postAssignmentGradesTrayOpenForAssignmentId = isOpen
    return this.updateGrid()
  }

  // # Course Settings Access Methods
  getCourseGradingScheme() {
    return this.courseContent.courseGradingScheme
  }

  getDefaultGradingScheme() {
    return this.courseContent.defaultGradingScheme
  }

  getGradingScheme(gradingSchemeId) {
    return this.courseContent.gradingSchemes.find(scheme => {
      return scheme.id === gradingSchemeId
    })
  }

  getAssignmentGradingScheme(assignmentId) {
    const assignment = this.getAssignment(assignmentId)
    return this.getGradingScheme(assignment.grading_standard_id) || this.getDefaultGradingScheme()
  }

  getSections() {
    return Object.values(this.sections)
  }

  setSections(sections) {
    this.sections = _.indexBy(sections, 'id')
    return (this.sections_enabled = sections.length > 1)
  }

  setStudentGroups(groupCategories) {
    this.studentGroupCategories = _.indexBy(groupCategories, 'id')
    const studentGroupList = _.flatten(_.pluck(groupCategories, 'groups')).map(htmlEscape)
    this.studentGroups = _.indexBy(studentGroupList, 'id')
    return (this.studentGroupsEnabled = studentGroupList.length > 0)
  }

  setAssignments(assignmentMap) {
    return (this.assignments = assignmentMap)
  }

  setAssignmentGroups(assignmentGroupMap) {
    return (this.assignmentGroups = assignmentGroupMap)
  }

  getAssignment(assignmentId) {
    return this.assignments[assignmentId]
  }

  getAssignmentGroup(assignmentGroupId) {
    return this.assignmentGroups[assignmentGroupId]
  }

  getCustomColumn(customColumnId) {
    return this.gradebookContent.customColumns.find(function (column) {
      return column.id === customColumnId
    })
  }

  getTeacherNotesColumn() {
    return this.gradebookContent.customColumns.find(function (column) {
      return column.teacher_notes
    })
  }

  listVisibleCustomColumns() {
    return this.gradebookContent.customColumns.filter(function (column) {
      return !column.hidden
    })
  }

  updateContextModules(contextModules) {
    this.setContextModules(contextModules)
    this.setContextModulesLoaded(true)
    this.renderViewOptionsMenu()
    this.renderFilters()
    return this._updateEssentialDataLoaded()
  }

  setContextModules(contextModules) {
    let contextModule, j, len
    this.courseContent.contextModules = contextModules
    this.courseContent.modulesById = {}
    if (contextModules != null ? contextModules.length : undefined) {
      for (j = 0, len = contextModules.length; j < len; j++) {
        contextModule = contextModules[j]
        this.courseContent.modulesById[contextModule.id] = contextModule
      }
    }
    return contextModules
  }

  onLatePolicyUpdate(latePolicy) {
    this.setLatePolicy(latePolicy)
    return this.applyLatePolicy()
  }

  setLatePolicy(latePolicy) {
    return (this.courseContent.latePolicy = latePolicy)
  }

  applyLatePolicy() {
    let ref1
    const latePolicy = (ref1 = this.courseContent) != null ? ref1.latePolicy : undefined
    const gradingStandard = this.options.grading_standard || this.options.default_grading_standard
    const studentsToInvalidate = {}
    forEachSubmission(this.students, submission => {
      let ref2
      const assignment = this.assignments[submission.assignment_id]
      const student = this.student(submission.user_id)
      if (student != null ? student.isConcluded : undefined) {
        return
      }
      if (
        (ref2 = this.getGradingPeriod(submission.grading_period_id)) != null
          ? ref2.isClosed
          : undefined
      ) {
        return
      }
      if (
        LatePolicyApplicator.processSubmission(submission, assignment, gradingStandard, latePolicy)
      ) {
        return (studentsToInvalidate[submission.user_id] = true)
      }
    })
    const studentIds = _.uniq(Object.keys(studentsToInvalidate))
    studentIds.forEach(studentId => {
      return this.calculateStudentGrade(this.students[studentId])
    })
    return this.invalidateRowsForStudentIds(studentIds)
  }

  getContextModule(contextModuleId) {
    let ref1
    if (contextModuleId != null) {
      return (ref1 = this.courseContent.modulesById) != null ? ref1[contextModuleId] : undefined
    }
  }

  listContextModules() {
    return this.courseContent.contextModules
  }

  getDownloadSubmissionsAction(assignmentId) {
    const assignment = this.getAssignment(assignmentId)
    const manager = new DownloadSubmissionsDialogManager(
      assignment,
      this.options.download_assignment_submissions_url,
      this.handleSubmissionsDownloading
    )
    return {
      hidden: !manager.isDialogEnabled(),
      onSelect: manager.showDialog
    }
  }

  getReuploadSubmissionsAction(assignmentId) {
    const assignment = this.getAssignment(assignmentId)
    const manager = new ReuploadSubmissionsDialogManager(
      assignment,
      this.options.re_upload_submissions_url,
      this.options.user_asset_string
    )
    return {
      hidden: !manager.isDialogEnabled(),
      onSelect: manager.showDialog
    }
  }

  getSetDefaultGradeAction(assignmentId) {
    const assignment = this.getAssignment(assignmentId)
    const manager = new SetDefaultGradeDialogManager(
      assignment,
      this.studentsThatCanSeeAssignment(assignmentId),
      this.options.context_id,
      this.getFilterRowsBySetting('sectionId'),
      isAdmin(),
      this.contentLoadStates.submissionsLoaded
    )
    return {
      disabled: !manager.isDialogEnabled(),
      onSelect: manager.showDialog
    }
  }

  getCurveGradesAction(assignmentId) {
    const assignment = this.getAssignment(assignmentId)
    return CurveGradesDialogManager.createCurveGradesAction(
      assignment,
      this.studentsThatCanSeeAssignment(assignmentId),
      {
        isAdmin: isAdmin(),
        contextUrl: this.options.context_url,
        submissionsLoaded: this.contentLoadStates.submissionsLoaded
      }
    )
  }

  createTeacherNotes() {
    this.setTeacherNotesColumnUpdating(true)
    this.renderViewOptionsMenu()
    return GradebookApi.createTeacherNotesColumn(this.options.context_id)
      .then(response => {
        this.gradebookContent.customColumns.push(response.data)
        const teacherNotesColumn = this.buildCustomColumn(response.data)
        this.gridData.columns.definitions[teacherNotesColumn.id] = teacherNotesColumn
        this.showNotesColumn()
        this.setTeacherNotesColumnUpdating(false)
        return this.renderViewOptionsMenu()
      })
      .catch(_error => {
        $.flashError(I18n.t('There was a problem creating the teacher notes column.'))
        this.setTeacherNotesColumnUpdating(false)
        return this.renderViewOptionsMenu()
      })
  }

  setTeacherNotesHidden(hidden) {
    this.setTeacherNotesColumnUpdating(true)
    this.renderViewOptionsMenu()
    const teacherNotes = this.getTeacherNotesColumn()
    return GradebookApi.updateTeacherNotesColumn(this.options.context_id, teacherNotes.id, {
      hidden
    })
      .then(() => {
        if (hidden) {
          this.hideNotesColumn()
        } else {
          this.showNotesColumn()
          this.reorderCustomColumns(
            this.gradebookContent.customColumns.map(function (c) {
              return c.id
            })
          )
        }
        this.setTeacherNotesColumnUpdating(false)
        return this.renderViewOptionsMenu()
      })
      .catch(_error => {
        if (hidden) {
          $.flashError(I18n.t('There was a problem hiding the teacher notes column.'))
        } else {
          $.flashError(I18n.t('There was a problem showing the teacher notes column.'))
        }
        this.setTeacherNotesColumnUpdating(false)
        return this.renderViewOptionsMenu()
      })
  }

  apiUpdateSubmission(submission, gradeInfo) {
    const {userId, assignmentId} = submission
    const student = this.student(userId)
    this.addPendingGradeInfo(submission, gradeInfo)
    if (this.getSubmissionTrayState().open) {
      this.renderSubmissionTray(student)
    }
    return GradebookApi.updateSubmission(this.options.context_id, assignmentId, userId, submission)
      .then(response => {
        this.removePendingGradeInfo(submission)
        this.updateSubmissionsFromExternal(response.data.all_submissions)
        if (this.getSubmissionTrayState().open) {
          this.renderSubmissionTray(student)
        }
        return response
      })
      .catch(response => {
        this.removePendingGradeInfo(submission)
        this.updateRowCellsForStudentIds([userId])
        $.flashError(I18n.t('There was a problem updating the submission.'))
        if (this.getSubmissionTrayState().open) {
          this.renderSubmissionTray(student)
        }
        return Promise.reject(response)
      })
  }

  gradeSubmission(submission, gradeInfo) {
    let gradeChangeOptions, submissionData
    if (gradeInfo.valid) {
      gradeChangeOptions = {
        enterGradesAs: this.getEnterGradesAsSetting(submission.assignmentId),
        gradingScheme: this.getAssignmentGradingScheme(submission.assignmentId).data,
        pointsPossible: this.getAssignment(submission.assignmentId).points_possible
      }
      if (GradeInputHelper.hasGradeChanged(submission, gradeInfo, gradeChangeOptions)) {
        submissionData = {
          assignmentId: submission.assignmentId,
          userId: submission.userId
        }
        if (gradeInfo.excused) {
          submissionData.excuse = true
        } else if (gradeInfo.enteredAs === null) {
          submissionData.posted_grade = ''
        } else if (['passFail', 'gradingScheme'].includes(gradeInfo.enteredAs)) {
          submissionData.posted_grade = gradeInfo.grade
        } else {
          submissionData.posted_grade = gradeInfo.score
        }
        return this.apiUpdateSubmission(submissionData, gradeInfo).then(response => {
          const assignment = this.getAssignment(submission.assignmentId)
          const outlierScoreHelper = new OutlierScoreHelper(
            response.data.score,
            assignment.points_possible
          )
          if (outlierScoreHelper.hasWarning()) {
            return $.flashWarning(outlierScoreHelper.warningMessage())
          }
        })
      } else {
        this.removePendingGradeInfo(submission)
        this.updateRowCellsForStudentIds([submission.userId])
        if (this.getSubmissionTrayState().open) {
          return this.renderSubmissionTray()
        }
      }
    } else {
      FlashAlert.showFlashAlert({
        message: I18n.t(
          'You have entered an invalid grade for this student. Check the value and the grading type and try again.'
        ),
        type: 'error'
      })
      this.addPendingGradeInfo(submission, gradeInfo)
      this.updateRowCellsForStudentIds([submission.userId])
      if (this.getSubmissionTrayState().open) {
        return this.renderSubmissionTray()
      }
    }
  }

  updateSubmissionAndRenderSubmissionTray(data) {
    const {studentId, assignmentId} = this.getSubmissionTrayState()
    const submissionData = {
      assignmentId,
      userId: studentId,
      ...data
    }
    const submission = this.getSubmission(studentId, assignmentId)
    const gradeInfo = {
      excused: submission.excused,
      grade: submission.entered_grade,
      score: submission.entered_score,
      valid: true
    }
    return this.apiUpdateSubmission(submissionData, gradeInfo)
  }

  renderAnonymousSpeedGraderAlert(props) {
    return renderComponent(AnonymousSpeedGraderAlert, anonymousSpeedGraderAlertMountPoint(), props)
  }

  showAnonymousSpeedGraderAlertForURL(speedGraderUrl) {
    const props = {
      speedGraderUrl,
      onClose: this.hideAnonymousSpeedGraderAlert
    }
    this.anonymousSpeedGraderAlert = this.renderAnonymousSpeedGraderAlert(props)
    return this.anonymousSpeedGraderAlert.open()
  }

  hideAnonymousSpeedGraderAlert() {
    // React throws an error if we try to unmount while the event is being handled
    return this.delayedCall(0, () => {
      return ReactDOM.unmountComponentAtNode(anonymousSpeedGraderAlertMountPoint())
    })
  }

  requireStudentGroupForSpeedGrader(assignment) {
    if (assignmentHelper.gradeByGroup(assignment)) {
      // Assignments that grade by group (not by student) don't require a group selection
      return false
    }
    return (
      this.options.course_settings.filter_speed_grader_by_student_group &&
      this.getStudentGroupToShow() === '0'
    )
  }

  showSimilarityScore(_assignment) {
    return !!this.options.show_similarity_score
  }

  viewUngradedAsZero() {
    return !!(
      this.courseFeatures.allowViewUngradedAsZero && this.gridDisplaySettings.viewUngradedAsZero
    )
  }

  destroy() {
    let ref1
    $(window).unbind('resize.fillWindowWithMe')
    $(document).unbind('gridready')
    this.gradebookGrid.destroy()
    return (ref1 = this.postPolicies) != null ? ref1.destroy() : undefined
  }

  _gridHasRendered() {
    return this.gridReady.state() === 'resolved'
  }

  _updateEssentialDataLoaded() {
    if (
      this.contentLoadStates.studentIdsLoaded &&
      this.contentLoadStates.contextModulesLoaded &&
      this.contentLoadStates.customColumnsLoaded &&
      this.contentLoadStates.assignmentGroupsLoaded &&
      this.assignmentsLoadedForCurrentView() &&
      (!this.gradingPeriodSet || this.contentLoadStates.gradingPeriodAssignmentsLoaded)
    ) {
      return this._essentialDataLoaded.resolve()
    }
  }
}

Gradebook.prototype.hasSections = $.Deferred()

// # Gradebook Application State
Gradebook.prototype.defaultSortType = 'assignment_group'

export default Gradebook
