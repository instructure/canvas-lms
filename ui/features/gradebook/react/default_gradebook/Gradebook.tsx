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
import type JQuery from 'jquery'
import deferPromise from '@instructure/defer-promise'
import {
  each,
  every,
  filter,
  flatten,
  intersection,
  isEqual,
  keyBy,
  map,
  pick,
  reduce,
  reject,
  some,
} from 'lodash'
import * as tz from '@canvas/datetime'
import React, {Suspense} from 'react'
import ReactDOM from 'react-dom'
import GenericErrorPage from '@canvas/generic-error-page'
import ErrorBoundary from '@canvas/error-boundary'
// @ts-ignore
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import type {ActionMenuProps} from './components/ActionMenu'
import type {SubmissionTrayProps} from './components/SubmissionTray'
import type {
  Assignment,
  AssignmentGroup,
  AssignmentGroupMap,
  AssignmentMap,
  AssignmentUserDueDateMap,
  AttachmentData,
  Course,
  DueDate,
  Enrollment,
  Module,
  Section,
  SectionMap,
  Student,
  StudentGroup,
  StudentGroupCategory,
  StudentGroupCategoryMap,
  StudentGroupMap,
  StudentMap,
  Submission,
  SubmissionCommentData,
  UserSubmissionGroup,
} from '../../../../api.d'
import type {GradebookSettingsModalProps} from './components/GradebookSettingsModal'
import type {
  AssignmentStudentMap,
  ColumnOrderSettings,
  ColumnSizeSettings,
  ContentLoadStates,
  CourseContent,
  CustomColumn,
  CustomColumnData,
  Filter,
  FilteredContentInfo,
  FlashMessage,
  GradebookOptions,
  GradebookSettings,
  GradebookStudent,
  GradebookViewOptions,
  GradingPeriodAssignmentMap,
  InitialActionStates,
  LatePolicyCamelized,
  PendingGradeInfo,
  ProgressCamelized,
  SerializedComment,
  SortDirection,
  SortRowsSettingKey,
  SubmissionFilterValue,
} from './gradebook.d'
import type {
  AggregateGrade,
  AssignmentGroupGrade,
  AssignmentGroupGradeMap,
  CamelizedGradingPeriodSet,
  CamelizedSubmission,
  FinalGradeOverrideMap,
  GradeEntryMode,
  GradeResult,
  GradingPeriodGradeMap,
  DeprecatedGradingScheme,
  StudentGrade,
} from '@canvas/grading/grading.d'
import type {
  ColumnFilterKey,
  FilterRowsBy,
  GridColumn,
  GridData,
  GridDataColumnsWithObjects,
  GridDisplaySettings,
  GridLocation,
  FilterColumnsOptions,
  RowFilterKey,
} from './grid.d'
import type GradebookGridType from './GradebookGrid/index'
import type {StatusColors} from './constants/colors'
import type {ProxyDetails} from '@canvas/proxy-submission/react/ProxyUploadModal'
import type TotalGradeColumnHeader from './GradebookGrid/headers/TotalGradeColumnHeader'
import type {SendMessageArgs} from '@canvas/message-students-dialog/react/MessageStudentsWhoDialog'

import KeyboardNavDialog from '@canvas/keyboard-nav-dialog'
// @ts-expect-error
import KeyboardNavTemplate from '@canvas/keyboard-nav-dialog/jst/KeyboardNavDialog.handlebars'
import GradingPeriodSetsApi from '@canvas/grading/jquery/gradingPeriodSetsApi'
import {useScope as useI18nScope} from '@canvas/i18n'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import * as EffectiveDueDates from '@canvas/grading/EffectiveDueDates'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import MessageStudentsWhoHelper from '@canvas/grading/messageStudentsWhoHelper'
import AssignmentOverrideHelper from '@canvas/due-dates/AssignmentOverrideHelper'
import UserSettings from '@canvas/user-settings'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import GradeDisplayWarningDialog from '../../jquery/GradeDisplayWarningDialog'
import PostGradesFrameDialog from '../../jquery/PostGradesFrameDialog'
import NumberCompare from '../../util/NumberCompare'
import {camelizeProperties} from '@canvas/convert-case'
import htmlEscape from '@instructure/html-escape'
import * as EnterGradesAsSetting from '../shared/EnterGradesAsSetting'
import SetDefaultGradeDialogManager from '../shared/SetDefaultGradeDialogManager'
import AsyncComponents from './AsyncComponents'
import CurveGradesDialogManager from './CurveGradesDialogManager'
import GradebookApi from './apis/GradebookApi'
import SubmissionCommentApi from './apis/SubmissionCommentApi'
import CourseSettings from './CourseSettings/index'
import FinalGradeOverrides from './FinalGradeOverrides/index'
import AssignmentRowCellPropFactory from './GradebookGrid/editors/AssignmentCellEditor/AssignmentRowCellPropFactory'
import TotalGradeOverrideCellPropFactory from './GradebookGrid/editors/TotalGradeOverrideCellEditor/TotalGradeOverrideCellPropFactory'
import PostPolicies from './PostPolicies/index'
import GradebookMenu from '@canvas/gradebook-menu'
import ViewOptionsMenu from './components/ViewOptionsMenu'
import ActionMenu from './components/ActionMenu'
import FilterNav from './components/FilterNav'
import EnhancedActionMenu from './components/EnhancedActionMenu'
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
import * as GradeInputHelper from '@canvas/grading/GradeInputHelper'
import OutlierScoreHelper from '@canvas/grading/OutlierScoreHelper'
import {isPostable} from '@canvas/grading/SubmissionHelper'
import LatePolicyApplicator from '../LatePolicyApplicator'
import {IconButton} from '@instructure/ui-buttons'
import {IconSettingsSolid} from '@instructure/ui-icons'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import MultiSelectSearchInput from './components/MultiSelectSearchInput'
import ApplyScoreToUngradedModal from './components/ApplyScoreToUngradedModal'
import ScoreToUngradedManager from '../shared/ScoreToUngradedManager'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/datetime/jquery'
import 'jqueryui/dialog'
import 'jqueryui/tooltip'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import 'jquery-tinypubsub'
import 'jqueryui/position'
import '@canvas/util/jquery/fixDialogButtons'

import {
  assignmentSearchMatcher,
  buildAssignmentGroupColumnFn,
  buildCustomColumn,
  buildStudentColumn,
  compareAssignmentDueDates,
  confirmViewUngradedAsZero,
  ensureAssignmentVisibility,
  escapeStudentContent,
  filterAssignmentsBySubmissionsFn,
  filterStudentBySubmissionFn,
  filterStudentBySectionFn,
  findFilterValuesOfType,
  findSubmissionFilterValue,
  forEachSubmission,
  getAssignmentColumnId,
  getAssignmentGroupColumnId,
  getAssignmentGroupPointsPossible,
  getColumnTypeForColumnId,
  getCourseFeaturesFromOptions,
  getCourseFromOptions,
  getCustomColumnId,
  getDefaultSettingKeyForColumnType,
  getGradeAsPercent,
  getStudentGradeForColumn,
  idArraysEqual,
  hiddenStudentIdsForAssignment,
  htmlDecode,
  isAdmin,
  isGradedOrExcusedSubmissionUnposted,
  onGridKeyDown,
  renderComponent,
  sectionList,
  testWidth,
} from './Gradebook.utils'
import {
  DEFAULT_COLUMN_SORT_TYPE,
  getColumnOrder,
  hideAggregateColumns,
  isInvalidSort,
  listRowIndicesForStudentIds,
} from './GradebookGrid/Grid.utils'
import {
  compareAssignmentNames,
  compareAssignmentPointsPossible,
  compareAssignmentPositions,
  idSort,
  isDefaultSortOrder,
  localeSort,
  makeCompareAssignmentCustomOrderFn,
  secondaryAndTertiarySort,
  wrapColumnSortFn,
} from './Gradebook.sorting'

import {
  getInitialGradebookContent,
  getInitialGridDisplaySettings,
  getInitialCourseContent,
  getInitialContentLoadStates,
  getInitialActionStates,
  columnWidths,
} from './initialState'
import {ExportProgressBar} from './components/ExportProgressBar'
import {ProgressBar} from '@instructure/ui-progress'
import GradebookExportManager from '../shared/GradebookExportManager'
import {handleExternalContentMessages} from '@canvas/external-tools/messages'
import type {EnvGradebookCommon} from '@canvas/global/env/EnvGradebook'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import {TotalGradeOverrideTrayProvider} from './components/TotalGradeOverrideTray'

const I18n = useI18nScope('gradebook')

const GradebookGrid = React.lazy(() => import('./components/GradebookGrid'))

const ASSIGNMENT_KEY_REGEX = /^assignment_(?!group)/

export function Portal({node, children}: {node: HTMLElement; children: React.ReactNode}) {
  return ReactDOM.createPortal(children, node)
}
// Allow unchecked access to module-specific ENV variables
declare const ENV: GlobalEnv & EnvGradebookCommon

export type GradebookProps = {
  actionMenuNode: HTMLSpanElement
  anonymousSpeedGraderAlertNode: HTMLSpanElement
  assignmentMap: AssignmentMap
  enhancedActionMenuNode: HTMLSpanElement
  appliedFilters: Filter[]
  applyScoreToUngradedModalNode: HTMLElement
  currentUserId: string
  customColumns: CustomColumn[]
  recentlyLoadedCustomColumnData: null | {
    customColumnId: string
    columnData: CustomColumnData[]
  }
  fetchFinalGradeOverrides: () => Promise<void>
  fetchGradingPeriodAssignments: () => Promise<GradingPeriodAssignmentMap>
  loadDataForCustomColumn: (customColumnId: string) => Promise<CustomColumnData[]>
  finalGradeOverrides: FinalGradeOverrideMap
  flashAlerts: FlashMessage[]
  flashMessageContainer: HTMLElement
  gradebookEnv: GradebookOptions
  gradebookGridNode: HTMLElement
  gradebookMenuNode: HTMLElement
  gradebookSettingsModalContainer: HTMLSpanElement
  gradingPeriodAssignments: GradingPeriodAssignmentMap
  gridColorNode: HTMLElement
  isCustomColumnsLoaded: boolean
  isFiltersLoading: boolean
  isGridLoaded: boolean
  isModulesLoading: boolean
  isStudentIdsLoading: boolean
  isStudentDataLoaded: boolean
  isSubmissionDataLoaded: boolean
  locale: string
  modules: Module[]
  postGradesStore: ReturnType<typeof PostGradesStore>
  recentlyLoadedAssignmentGroups: {
    assignmentGroups: AssignmentGroup[]
    gradingPeriodIds?: string[]
  }
  recentlyLoadedStudents: Student[]
  recentlyLoadedSubmissions: UserSubmissionGroup[]
  reloadStudentData: () => void
  reorderCustomColumns: (customColumnIds: string[]) => Promise<void>
  settingsModalButtonContainer: HTMLElement
  sisOverrides: AssignmentGroup[]
  studentIds: string[]
  totalSubmissionsLoaded: number
  totalStudentsToLoad: number
  updateColumnOrder: (courseId: string, columnOrder: ColumnOrderSettings) => Promise<void>
  viewOptionsMenuNode: HTMLElement
}

type GradebookState = {
  assignmentGroups: AssignmentGroup[]
  gradingPeriodId: string | null
  gridColors: StatusColors
  isEssentialDataLoaded: boolean
  isGridLoaded: boolean
  modules: Module[]
  sections: Section[]
  isStatusesModalOpen: boolean
  exportState?: {
    completion?: number
    filename?: string
  }
  exportManager: any
}

class Gradebook extends React.Component<GradebookProps, GradebookState> {
  kbDialog: any

  anonymousSpeedGraderAlert?: any

  assignmentStudentVisibility: AssignmentStudentMap = {}

  teacherNotesNotYetLoaded = true

  headerComponentRefs: {
    [key: string]: TotalGradeColumnHeader | null
  } = {}

  calculatedGradesByStudentId: {
    [studentId: string]: {
      assignmentGroups: AssignmentGroupGradeMap
      current: {
        score: number
        possible: number
      }
      final: {
        score: number
        possible: number
      }
      scoreUnit: 'points' | 'percentage'
    }
  } = {}

  effectiveDueDates: AssignmentUserDueDateMap = {}

  $grid?: JQuery<HTMLElement>

  postGradesLtis: {id: string; name: string; onSelect: () => void}[] = []

  disablePostGradesFeature = false

  viewOptionsMenu?: HTMLElement

  keyboardNav?: GradebookKeyboardNav

  filteredContentInfo: FilteredContentInfo = {
    invalidAssignmentGroups: [],
    totalPointsPossible: 0,
  }

  sections: SectionMap = {}

  filteredStudentIds: string[] = []

  searchFilteredStudentIds: string[] = []

  assignmentGroups: AssignmentGroupMap = {}

  contentLoadStates: ContentLoadStates

  course: Course

  searchFilteredAssignmentIds: string[] = []

  filteredAssignmentIds: string[] = []

  gradebookSettingsModal: React.RefObject<HTMLElement & {open: () => void}>

  isRunningScoreToUngraded: boolean

  gradebookSettingsModalButton: React.RefObject<any> = React.createRef()

  gradingPeriodSet: CamelizedGradingPeriodSet | null = null

  gradingPeriodId = '0'

  options: GradebookOptions

  sections_enabled = false

  show_attendance: boolean

  studentGroups: StudentGroupMap = {}

  studentGroupsEnabled?: boolean

  students: StudentMap = {}

  studentViewStudents: StudentMap = {}

  totalColumnPositionChanged?: boolean

  uid?: string

  courseFeatures: {
    finalGradeOverrideEnabled: boolean
    allowViewUngradedAsZero: boolean
  }

  courseSettings: CourseSettings

  downloadedSubmissionsMap: {
    [assignmentId: string]: boolean
  } = {}

  gridData: GridData = {
    columns: {
      definitions: {},
      frozen: [],
      scrollable: [],
    },
    rows: [],
  }

  gradebookGrid: null | GradebookGridType = null

  finalGradeOverrides: FinalGradeOverrides | null

  postPolicies: PostPolicies

  gridReady = deferPromise<null>()

  courseContent: CourseContent

  gradebookContent: {
    customColumns: CustomColumn[]
  }

  actionStates?: InitialActionStates

  gradebookColumnOrderSettings?: ColumnOrderSettings

  gridDisplaySettings: GridDisplaySettings

  startedInitializing?: boolean

  assignments: AssignmentMap = {}

  submissionStateMap!: SubmissionStateMap

  studentGroupCategoriesById: StudentGroupCategoryMap = {}

  gradebookColumnSizeSettings: ColumnSizeSettings = {}

  scoreToUngradedManager: ScoreToUngradedManager | null

  constructor(props: GradebookProps) {
    super(props)
    this.options = {...(props.gradebookEnv || {}), ...props}
    this.gradingPeriodSet = this.options.grading_period_set
      ? GradingPeriodSetsApi.deserializeSet(this.options.grading_period_set)
      : null
    this.gridDisplaySettings = getInitialGridDisplaySettings(
      this.options.settings,
      this.props.gradebookEnv.colors
    )
    this.gradingPeriodId = this.getCurrentGradingPeriod()

    this.state = {
      assignmentGroups: [],
      gradingPeriodId: this.getCurrentGradingPeriod(),
      gridColors: statusColors(this.props.gradebookEnv.colors),
      isEssentialDataLoaded: false,
      isGridLoaded: this.props.isGridLoaded,
      modules: [],
      sections: this.options.sections.length > 1 ? this.options.sections : [],
      isStatusesModalOpen: false,
      exportState: undefined,
      exportManager: undefined,
    }
    // @ts-expect-error
    this.course = getCourseFromOptions(this.options)
    this.courseFeatures = getCourseFeaturesFromOptions(this.options)
    this.courseSettings = new CourseSettings(this, {
      allowFinalGradeOverride: this.options.course_settings.allow_final_grade_override,
    })
    if (this.courseFeatures.finalGradeOverrideEnabled) {
      this.finalGradeOverrides = new FinalGradeOverrides(this)
    } else {
      this.finalGradeOverrides = null
    }
    this.postPolicies = new PostPolicies(this)
    this.isRunningScoreToUngraded = false
    if (this.allowApplyScoreToUngraded()) {
      const progressData = this.options.gradebook_score_to_ungraded_progress
      let lastProgress: ProgressCamelized | undefined
      if (progressData) {
        lastProgress = {
          progressId: `${progressData.progress.id}`,
          workflowState: progressData.progress.workflow_state,
        }
      }
      this.scoreToUngradedManager = new ScoreToUngradedManager(lastProgress)
    } else {
      this.scoreToUngradedManager = null
    }
    $.subscribe('assignment_muting_toggled', this.handleSubmissionPostedChange)
    $.subscribe('submissions_updated', this.updateSubmissionsFromExternal)
    // emitted by SectionMenuView; also subscribed in OutcomeGradebookView
    $.subscribe('currentSection/change', this.updateCurrentSection)
    this.courseContent = getInitialCourseContent(this.options)
    this.gradebookContent = getInitialGradebookContent(this.options)
    this.contentLoadStates = getInitialContentLoadStates(this.options)
    this.actionStates = getInitialActionStates()
    this.setAssignments({})
    this.setAssignmentGroups({})
    this.courseContent.students = new StudentDatastore(this.students, this.studentViewStudents)

    this.props.postGradesStore.addChangeListener(this.updatePostGradesFeatureButton)
    const sectionId = this.getFilterRowsBySetting('sectionId')
    this.props.postGradesStore.setSelectedSection(sectionId)

    this.initPostGradesLtis()
    this.checkForUploadComplete()

    this.show_attendance = Boolean(UserSettings.contextGet<boolean>('show_attendance'))
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
    this.initShowSeparateFirstLastNames(
      this.options.settings.show_separate_first_last_names === 'true' &&
        this.options.allow_separate_first_last_names
    )
    this.initHideAssignmentGroupTotals(
      this.options.settings.hide_assignment_group_totals === 'true'
    )
    this.initHideTotal(this.options.settings.hide_total === 'true')
    this.initSubmissionStateMap()
    this.gradebookColumnSizeSettings = this.options.gradebook_column_size_settings
    this.setColumnOrder({
      ...this.options.gradebook_column_order_settings,
      // TODO: resolve boolean vs. string (e.g. 'true') mismatch for freezeTotalGrade
      freezeTotalGrade:
        (this.options.gradebook_column_order_settings != null
          ? this.options.gradebook_column_order_settings.freezeTotalGrade
          : undefined) === 'true',
    })
    this.teacherNotesNotYetLoaded =
      this.getTeacherNotesColumn() == null || this.getTeacherNotesColumn()!.hidden || false
    this.setSections(this.options.sections)
    this.props.postGradesStore.setSections(this.sections)
    if (!this.getSelectedSecondaryInfo()) {
      if (this.sections_enabled) {
        this.gridDisplaySettings.selectedSecondaryInfo = 'section'
      } else {
        this.gridDisplaySettings.selectedSecondaryInfo = 'none'
      }
    }
    this.setStudentGroups(this.options.student_groups)
    this.gradebookSettingsModal = React.createRef()
  }

  bindGridEvents = () => {
    if (!this.gradebookGrid) throw new Error('gradebookGrid not initialized')
    this.gradebookGrid.events.onColumnsReordered.subscribe(
      (_event: Event, columns: GridDataColumnsWithObjects) => {
        let currentCustomColumnIds: string[]
        let currentFrozenColumns: GridColumn[]
        let updatedCustomColumnIds: string[]
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
        if (!isEqual(currentFrozenIds, updatedFrozenIds)) {
          currentFrozenColumns = currentFrozenIds.map(columnId => {
            return this.gridData.columns.definitions[columnId]
          })
          currentCustomColumnIds = (function () {
            const results: string[] = []
            for (const column of currentFrozenColumns) {
              if (column.type === 'custom_column' && column.customColumnId) {
                results.push(column.customColumnId)
              }
            }
            return results
          })()
          updatedCustomColumnIds = (function () {
            const results: string[] = []
            for (const column of columns.frozen) {
              if (column.type === 'custom_column') {
                results.push(column.customColumnId)
              }
            }
            return results
          })()
          if (!isEqual(currentCustomColumnIds, updatedCustomColumnIds)) {
            // eslint-disable-next-line promise/catch-or-return
            this.props.reorderCustomColumns(updatedCustomColumnIds).then(() => {
              const colsById: {
                [columnId: string]: CustomColumn
              } = keyBy(this.gradebookContent.customColumns, (c: CustomColumn) => c.id)
              if (this.gradebookContent.customColumns) {
                this.gradebookContent.customColumns = updatedCustomColumnIds.map(id => colsById[id])
              }
              return this.gradebookContent.customColumns
            })
          }
        } else {
          this.saveCustomColumnOrder()
        }
        this.renderViewOptionsMenu()
        return this.updateColumnHeaders()
      }
    )
    this.gradebookGrid.events.onColumnsResized.subscribe((_event: Event, columns: GridColumn[]) => {
      return columns.forEach((column: GridColumn) => {
        return this.saveColumnWidthPreference(column.id, column.width)
      })
    })
  }

  onShow = () => {
    $('.post-grades-button-placeholder').show()
    if (this.startedInitializing) {
      return
    }
    this.startedInitializing = true
    if (this.gridReady.state !== 'resolved') {
      return $('#gradebook-grid-wrapper').hide()
    } else {
      return $('#gradebook_grid').trigger('resize.fillWindowWithMe')
    }
  }

  addOverridesToPostGradesStore = (assignmentGroups: AssignmentGroup[]) => {
    for (const group of assignmentGroups) {
      for (const assignment of group.assignments) {
        if (this.assignments[assignment.id]) {
          this.assignments[assignment.id].overrides = assignment.overrides
        }
      }
    }
    this.props.postGradesStore.setGradeBookAssignments(this.assignments)
  }

  // dependencies - gridReady
  setAssignmentVisibility = (studentIds: string[]) => {
    const studentsWithHiddenAssignments: string[] = []
    const ref1 = this.assignments
    for (const assignmentId in ref1) {
      const a = ref1[assignmentId]
      if (a.only_visible_to_overrides) {
        const hiddenStudentIds = hiddenStudentIdsForAssignment(studentIds, a)
        for (const studentId of hiddenStudentIds) {
          studentsWithHiddenAssignments.push(studentId)
          this.updateSubmission({
            assignment_id: assignmentId,
            user_id: studentId,
            hidden: true,
          })
        }
      }
    }
    const ref2: string[] = [...new Set(studentsWithHiddenAssignments)]
    for (const studentId of ref2) {
      const student = this.student(studentId)
      this.calculateStudentGrade(student)
    }
  }

  updateAssignmentVisibilities = (hiddenSub: Submission) => {
    const assignment = this.assignments[hiddenSub.assignment_id]
    const filteredVisibility = assignment.assignment_visibility.filter(
      id => id !== hiddenSub.user_id
    )
    assignment.assignment_visibility = filteredVisibility
  }

  gotCustomColumns = (columns: CustomColumn[]) => {
    // prepare array of objects to be mutated
    // necessary until we remove object mutation from this file
    this.gradebookContent.customColumns = structuredClone(columns)
    columns.forEach(column => {
      const customColumn = buildCustomColumn(column)
      this.gridData.columns.definitions[customColumn.id] = customColumn
    })
    this._updateEssentialDataLoaded()
  }

  gotCustomColumnDataChunk = (customColumnId: string, columnData: CustomColumnData[]) => {
    const studentIds: string[] = []
    for (const datum of columnData) {
      const student = this.student(datum.user_id)
      if (student != null) {
        student[`custom_col_${customColumnId}`] = datum.content
        studentIds.push(student.id) // ignore filtered students
      } else {
        this.courseContent.students.preloadStudentData(datum.user_id, {
          [`custom_col_${customColumnId}`]: datum.content,
        })
      }
    }

    this.invalidateRowsForStudentIds([...new Set(studentIds)])
  }

  updateFilterAssignmentIds = () => {
    this.filteredAssignmentIds = this.filterAssignments(Object.values(this.assignments)).map(
      assignment => assignment.id
    )
  }

  // Assignment Group Data & Lifecycle Methods
  updateAssignmentGroups = (assignmentGroups: AssignmentGroup[], gradingPeriodIds?: string[]) => {
    this.gotAllAssignmentGroups(assignmentGroups)
    this.setState({assignmentGroups})
    this.setAssignmentsLoaded(gradingPeriodIds)
    this.renderViewOptionsMenu()
    this.renderFilters()
    this.updateColumnHeaders()
    this._updateEssentialDataLoaded()
    this.updateFilterAssignmentIds()
  }

  gotAllAssignmentGroups = (assignmentGroups: AssignmentGroup[]) => {
    this.setAssignmentGroupsLoaded(true)
    assignmentGroups.forEach(assignmentGroup => {
      let group = this.assignmentGroups[assignmentGroup.id]
      if (!group) {
        group = assignmentGroup
        this.assignmentGroups[group.id] = group
      }

      // @ts-expect-error
      group.assignments = group.assignments || [] // perhaps unnecessary
      assignmentGroup.assignments.forEach(assignment => {
        assignment.assignment_group = group
        // @ts-expect-error
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

  updateGradingPeriodAssignments = (gradingPeriodAssignments: GradingPeriodAssignmentMap) => {
    this.gotGradingPeriodAssignments({
      grading_period_assignments: gradingPeriodAssignments,
    })

    Object.keys(gradingPeriodAssignments).forEach(periodId => {
      this.contentLoadStates.assignmentsLoaded.gradingPeriod[periodId] =
        this.contentLoadStates.assignmentsLoaded.all
    })

    this.setGradingPeriodAssignmentsLoaded(true)
    if (this._gridHasRendered()) {
      this.updateColumns()
    }
    this._updateEssentialDataLoaded()
  }

  getGradingPeriodAssignments = (gradingPeriodId: string) => {
    return this.courseContent.gradingPeriodAssignments[gradingPeriodId] || []
  }

  gotGradingPeriodAssignments = ({
    grading_period_assignments: gradingPeriodAssignments,
  }: {
    grading_period_assignments: GradingPeriodAssignmentMap
  }) => {
    return (this.courseContent.gradingPeriodAssignments = gradingPeriodAssignments)
  }

  gotChunkOfStudents = (students: Student[]) => {
    this.courseContent.assignmentStudentVisibility = {}
    students.forEach(student => {
      student.enrollments = filter(
        student.enrollments,
        (e: Enrollment) => e.type === 'StudentEnrollment' || e.type === 'StudentViewEnrollment'
      )
      student.sections = student.enrollments.map(e => e.course_section_id)
      const isStudentView = student.enrollments[0].type === 'StudentViewEnrollment'
      // TODO: avoid mutating the student object
      escapeStudentContent(student)
      if (this.courseContent.students.preloadedStudentData[student.id]) {
        Object.assign(student, this.courseContent.students.preloadedStudentData[student.id])
      }
      if (isStudentView) {
        this.studentViewStudents[student.id] = student
      } else {
        this.students[student.id] = student
      }
      student.computed_current_score || (student.computed_current_score = 0)
      student.computed_final_score || (student.computed_final_score = 0)
      student.isConcluded = every(student.enrollments, function (e: {enrollment_state: string}) {
        return e.enrollment_state === 'completed'
      })
      student.isInactive = every(student.enrollments, function (e: {enrollment_state: string}) {
        return e.enrollment_state === 'inactive'
      })
      student.cssClass = `student_${student.id}`
      this.updateStudentRow(student)
    })
    AssignmentOverrideHelper.setStudentDisplayNames([
      ...Object.values(this.students),
      ...Object.values(this.studentViewStudents),
    ])
    // eslint-disable-next-line promise/catch-or-return
    this.gridReady.promise.then(() => {
      const studentIds = this.setupGrading(students)
      this.invalidateRowsForStudentIds(studentIds)
    })
    if (this.isFilteringRowsBySearchTerm()) {
      // When filtering, students cannot be matched until loaded. The grid must
      // be re-rendered more aggressively to ensure new rows are inserted.
      this.buildRows()
    } else {
      this.gradebookGrid?.render()
    }
  }

  // # Post-Data Load Initialization
  finishRenderingUI = () => {
    this.initGrid()
    this.initHeader()
    this.gridReady.resolve(null)
    if (this.options.post_grades_feature) {
      this.addOverridesToPostGradesStore(this.props.sisOverrides)
    }
  }

  setupGrading = (students: GradebookStudent[]): string[] => {
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
    const studentIds: string[] = map(students, 'id')
    this.setAssignmentVisibility(studentIds)
    return studentIds
  }

  resetGrading = () => {
    this.initSubmissionStateMap()
    const studentIds = this.setupGrading(this.courseContent.students.listStudents())
    this.invalidateRowsForStudentIds(studentIds)
  }

  getSubmission = (studentId: string, assignmentId: string): Submission | undefined => {
    const student = this.student(studentId)
    return student != null ? student[`assignment_${assignmentId}`] : undefined
  }

  updateEffectiveDueDatesFromSubmissions = (submissions: Submission[]) => {
    return EffectiveDueDates.updateWithSubmissions(
      this.effectiveDueDates,
      submissions,
      this.gradingPeriodSet?.gradingPeriods
    )
  }

  updateAssignmentEffectiveDueDates = (assignment: Assignment) => {
    assignment.effectiveDueDates = this.effectiveDueDates[assignment.id] || {}
    assignment.inClosedGradingPeriod = some(
      assignment.effectiveDueDates,
      (date: DueDate) => date.in_closed_grading_period
    )
  }

  // Student Data & Lifecycle Methods
  updateStudentIds = (studentIds: string[]) => {
    this.courseContent.students.setStudentIds(studentIds)
    this.assignmentStudentVisibility = {}
    this.setStudentIdsLoaded(true)
    this.buildRows()
    this._updateEssentialDataLoaded()
  }

  updateStudentsLoaded = (loaded: boolean) => {
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

  studentsThatCanSeeAssignment = (assignmentId: string): StudentMap => {
    const {assignmentStudentVisibility} = this.courseContent
    if (assignmentStudentVisibility[assignmentId] == null) {
      const allStudentsById: StudentMap = {...this.students, ...this.studentViewStudents}

      const assignment = this.getAssignment(assignmentId)
      assignmentStudentVisibility[assignmentId] = assignment.only_visible_to_overrides
        ? (pick(allStudentsById, ...assignment.assignment_visibility) as StudentMap)
        : allStudentsById
    }

    return assignmentStudentVisibility[assignmentId]
  }

  // This is like studentsThatCanSeeAssignment, but returns only students
  // visible with the current filters, instead of all the students the
  // Gradebook knows about.
  visibleStudentsThatCanSeeAssignment = (assignmentId: string): StudentMap => {
    const allStudentIds = this.courseContent.students.listStudentIds()

    const visibleStudentsIgnoringSearch: StudentMap = pick(
      this.studentsThatCanSeeAssignment(assignmentId),
      allStudentIds
    )

    const fileredVisibleStudents = Object.values(visibleStudentsIgnoringSearch).filter(student =>
      this.filteredStudentIds.includes(student.id)
    )

    return Object.fromEntries(fileredVisibleStudents.map(student => [student.id, student]))
  }

  setColumnOrder = (order: ColumnOrderSettings) => {
    if (this.gradebookColumnOrderSettings == null) {
      this.gradebookColumnOrderSettings = {
        direction: 'ascending',
        freezeTotalGrade: false,
        sortType: DEFAULT_COLUMN_SORT_TYPE,
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

  saveColumnOrder = () => {
    if (!isInvalidSort(this.props.modules, this.gradebookColumnOrderSettings)) {
      const url = this.options.gradebook_column_order_settings_url
      $.ajaxJSON(url, 'POST', {
        column_order: getColumnOrder(this.props.modules, this.gradebookColumnOrderSettings),
      })
    }
  }

  saveCustomColumnOrder = () => {
    this.setColumnOrder({
      customOrder: this.gridData.columns.scrollable,
      sortType: 'custom',
    })
    this.saveColumnOrder()
  }

  arrangeColumnsBy = (newSortOrder: ColumnOrderSettings, isFirstArrangement: boolean) => {
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
    this.updateColumnHeaders()
  }

  makeColumnSortFn = (sortOrder: ColumnOrderSettings) => {
    switch (sortOrder.sortType) {
      case 'due_date':
        return wrapColumnSortFn(compareAssignmentDueDates, sortOrder.direction)
      case 'module_position':
        return wrapColumnSortFn(this.compareAssignmentModulePositions, sortOrder.direction)
      case 'name':
        return wrapColumnSortFn(compareAssignmentNames, sortOrder.direction)
      case 'points':
        return wrapColumnSortFn(compareAssignmentPointsPossible, sortOrder.direction)
      case 'custom':
        return makeCompareAssignmentCustomOrderFn(sortOrder)
      default:
        return wrapColumnSortFn(compareAssignmentPositions, sortOrder.direction)
    }
  }

  compareAssignmentModulePositions = (
    a: Pick<GridColumn, 'id' | 'type' | 'object'>,
    b: Pick<GridColumn, 'id' | 'type' | 'object'>
  ) => {
    let firstPositionInModule: number
    let secondPositionInModule: number
    let ref1, ref2
    const firstAssignmentModulePosition =
      (ref1 = this.getContextModule(a.object?.module_ids?.[0])) != null ? ref1.position : undefined
    const secondAssignmentModulePosition =
      (ref2 = this.getContextModule(b.object?.module_ids?.[0])) != null ? ref2.position : undefined
    if (firstAssignmentModulePosition != null && secondAssignmentModulePosition != null) {
      if (firstAssignmentModulePosition === secondAssignmentModulePosition) {
        // let's determine their order in the module because both records are in the same module
        firstPositionInModule = a.object?.module_positions?.[0] || 0
        secondPositionInModule = b.object?.module_positions?.[0] || 0
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
      return compareAssignmentPositions(a, b)
    }
  }

  // Filtering
  rowFilter = (student: Student) => {
    if (!this.isFilteringRowsBySearchTerm()) {
      return true
    }

    return this.searchFilteredStudentIds.includes(student.id)
  }

  filterAssignments = (assignments: Assignment[]) => {
    const assignmentFilters = [
      this.filterAssignmentBySearchInput,
      this.filterAssignmentBySubmissionTypes,
      this.filterAssignmentByPublishedStatus,
      this.filterAssignmentByAssignmentGroup,
      this.filterAssignmentByGradingPeriod,
      this.filterAssignmentByModule,
      this.filterAssignmentByStartDate,
      this.filterAssignmentByEndDate,
      filterAssignmentsBySubmissionsFn(
        this.props.appliedFilters,
        this.submissionStateMap,
        this.searchFilteredStudentIds,
        this.options.custom_grade_statuses_enabled ? this.options.custom_grade_statuses : []
      ),
    ]
    const matchesAllFilters = (assignment: Assignment) => {
      return assignmentFilters.every(filter => filter(assignment))
    }

    return assignments.filter(matchesAllFilters)
  }

  filterAssignmentBySearchInput = (assignment: Assignment) => {
    if (this.searchFilteredAssignmentIds.length > 0) {
      return this.searchFilteredAssignmentIds.includes(assignment.id)
    }

    return true
  }

  filterAssignmentBySubmissionTypes = (assignment: Assignment) => {
    const submissionType = '' + assignment.submission_types
    return (
      submissionType !== 'not_graded' && (submissionType !== 'attendance' || this.show_attendance)
    )
  }

  filterAssignmentByPublishedStatus = (assignment: Assignment) => {
    return assignment.published || this.gridDisplaySettings.showUnpublishedAssignments
  }

  filterAssignmentByAssignmentGroup = (assignment: Assignment) => {
    if (!this.options.enhanced_gradebook_filters) {
      if (!this.isFilteringColumnsByAssignmentGroup()) {
        return true
      }
      return this.getAssignmentGroupToShow() === assignment.assignment_group_id
    }

    const assignmentGroupIds = findFilterValuesOfType('assignment-group', this.props.appliedFilters)
    return (
      assignmentGroupIds.length === 0 || assignmentGroupIds.includes(assignment.assignment_group_id)
    )
  }

  filterAssignmentByGradingPeriod = (assignment: Assignment) => {
    if (!this.isFilteringColumnsByGradingPeriod()) return true

    const assignmentsForPeriod = this.getGradingPeriodAssignments(this.gradingPeriodId)
    return assignmentsForPeriod.includes(assignment.id)
  }

  filterAssignmentByModule = (assignment: Assignment) => {
    if (!this.options.enhanced_gradebook_filters) {
      const contextModuleFilterSetting = this.getModuleToShow()
      if (contextModuleFilterSetting === '0') {
        return true
      }
      return (
        (assignment.module_ids || []).indexOf(
          this.getFilterColumnsBySetting('contextModuleId') || ''
        ) >= 0
      )
    }

    const moduleIds = findFilterValuesOfType('module', this.props.appliedFilters)
    return moduleIds.length === 0 || intersection(assignment.module_ids, moduleIds).length > 0
  }

  filterAssignmentByStartDate = (assignment: Assignment) => {
    const date = findFilterValuesOfType('start-date', this.props.appliedFilters)[0]
    if (!date) {
      return true
    }
    return Object.values(assignment.effectiveDueDates || {}).some(
      // @ts-expect-error
      (effectiveDueDateObject: DueDate) => tz.parse(effectiveDueDateObject.due_at) >= tz.parse(date)
    )
  }

  filterAssignmentByEndDate = (assignment: Assignment) => {
    const date = findFilterValuesOfType('end-date', this.props.appliedFilters)[0]
    if (!date) {
      return true
    }
    return Object.keys(assignment.effectiveDueDates || {}).some(
      (assignmentId: string) =>
        assignment.effectiveDueDates &&
        // @ts-expect-error
        tz.parse(assignment.effectiveDueDates[assignmentId].due_at) <= tz.parse(date)
    )
  }

  // Course Content Event Handlers
  handleSubmissionPostedChange = (assignment: Assignment) => {
    let anonymousColumnIds
    if (assignment.anonymize_students) {
      anonymousColumnIds = [
        getAssignmentColumnId(assignment.id),
        getAssignmentGroupColumnId(assignment.assignment_group_id),
        'total_grade',
        'total_grade_override',
      ]
      if (anonymousColumnIds.indexOf(this.getSortRowsBySetting().columnId) >= 0) {
        this.setSortRowsBySetting('student', 'sortable_name', 'ascending')
      }
    }
    this.gradebookGrid?.gridSupport?.columns.updateColumnHeaders([
      getAssignmentColumnId(assignment.id),
    ])
    this.updateFilteredContentInfo()
    return this.resetGrading()
  }

  handleSubmissionsDownloading = (assignmentId: string) => {
    // TODO: Use separate object to track which submissions are downloaded
    // Don't mutate assignment objects
    this.downloadedSubmissionsMap[assignmentId] = true
    return this.gradebookGrid?.gridSupport?.columns.updateColumnHeaders([
      getAssignmentColumnId(assignmentId),
    ])
  }

  filterStudents = (students: Student[]): Student[] => {
    // need to apply row specific filters here as well, such as the student groups filter when it becomes a frontend filter
    if (this.isFilteringRowsBySearchTerm()) {
      return students
        .filter(student => this.searchFilteredStudentIds.includes(student.id))
        .filter(filterStudentBySectionFn(this.props.appliedFilters, this.getEnrollmentFilters()))
    }

    return students
      .filter(
        filterStudentBySubmissionFn(
          this.props.appliedFilters,
          this.submissionStateMap,
          this.filteredAssignmentIds,
          this.options.custom_grade_statuses_enabled ? this.options.custom_grade_statuses : []
        )
      )
      .filter(filterStudentBySectionFn(this.props.appliedFilters, this.getEnrollmentFilters()))
  }

  updateFilteredStudentIds = () => {
    const students: Student[] = this.courseContent.students.listStudents()
    const newStudentIds = this.filterStudents(students).map(s => s.id)
    this.filteredStudentIds = newStudentIds
  }

  buildRows = () => {
    this.updateFilteredStudentIds()
    this.gridData.rows.length = 0 // empty the list of rows
    for (const studentId of this.filteredStudentIds) {
      const student = this.courseContent.students.student(studentId)
      if (!student) {
        throw new Error(`Student ${studentId} not found`)
      }
      this.gridData.rows.push(student)
      this.calculateStudentGrade(student)
    }
    this.gradebookGrid?.invalidate()
  }

  updateRows = (changedStudentIds: string[] = []) => {
    this.updateFilteredStudentIds()
    const rows = this.gridData.rows
    const rowCountChanged = this.filteredStudentIds.length !== rows.length
    const indicesToUpdate: string[] = []

    this.filteredStudentIds.forEach((studentId, index) => {
      const student = this.courseContent.students.student(studentId)
      if (!student) {
        throw new Error(`Student ${studentId} not found`)
      }
      this.calculateStudentGrade(student)

      if (index < rows.length) {
        const hasChanged =
          rows[index].id !== this.filteredStudentIds[index] || changedStudentIds.includes(studentId)
        if (hasChanged) {
          rows[index] = student
          indicesToUpdate.push(String(index))
        }
      } else {
        rows.push(student)
      }
    })

    if (indicesToUpdate.length > 0) {
      this.gradebookGrid?.invalidateRows(indicesToUpdate)
    }
    if (rowCountChanged) {
      this.gridData.rows.length = this.filteredStudentIds.length // truncate the array
      this.gradebookGrid?.updateRowCount()
    }

    this.gradebookGrid?.render()
  }

  // Submission Data & Lifecycle Methods
  updateSubmissionsLoaded = (loaded: boolean) => {
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

  gotSubmissionsChunk = (student_submission_groups: UserSubmissionGroup[]) => {
    let changedStudentIds: string[] = []
    const submissions: Submission[] = []
    for (const studentSubmissionGroup of student_submission_groups) {
      changedStudentIds.push(studentSubmissionGroup.user_id)
      const student = this.student(studentSubmissionGroup.user_id)
      if (!student) {
        continue
      }
      for (const submission of studentSubmissionGroup.submissions) {
        submission.posted_at = tz.parse(submission.posted_at)
        ensureAssignmentVisibility(this.getAssignment(submission.assignment_id), submission)
        submissions.push(submission)
        this.updateSubmission(submission)
      }
      student.loaded = true
    }
    this.updateEffectiveDueDatesFromSubmissions(submissions)
    each(this.assignments, (assignment: Assignment) => {
      return this.updateAssignmentEffectiveDueDates(assignment)
    })
    changedStudentIds = [...new Set(changedStudentIds)]
    const students = changedStudentIds.map(this.student)
    this.setupGrading(students)
    this.updateColumns()
    this.updateRows(changedStudentIds)
  }

  student = (id: string): GradebookStudent => this.students[id] || this.studentViewStudents[id]

  updateSubmission = (
    submission: Partial<Submission> & Pick<Submission, 'user_id' | 'assignment_id'>
  ) => {
    const student = this.student(submission.user_id)
    if (!student) {
      return
    }
    submission.submitted_at = tz.parse(submission.submitted_at)
    submission.excused = Boolean(submission.excused)
    submission.hidden = Boolean(submission.hidden)
    submission.rawGrade = submission.grade // save the unformatted version of the grade too
    const assignment = this.assignments[submission.assignment_id]
    if (assignment) {
      submission.gradingType = assignment.grading_type
      if (submission.gradingType !== 'pass_fail') {
        submission.grade = GradeFormatHelper.formatGrade(submission.grade, {
          gradingType: submission.gradingType,
          delocalize: false,
        })
      }
    }
    const name = `assignment_${submission.assignment_id}`
    const cell = student[name] || (student[name] = {})
    Object.assign(cell, submission)
  }

  // this is used after the CurveGradesDialog submit xhr comes back.  it does not use the api
  // because there is no *bulk* submissions#update endpoint in the api.
  // It is different from gotSubmissionsChunk in that gotSubmissionsChunk expects an array of students
  // where each student has an array of submissions.  This one just expects an array of submissions,
  // they are not grouped by student.
  updateSubmissionsFromExternal = (submissions: Submission[]) => {
    let cell, idToMatch, index, student, submissionState
    const columns = this.gradebookGrid?.grid.getColumns()
    const changedColumnHeaders: {
      [assignmentId: string]: number | undefined
    } = {}
    const changedStudentIds: string[] = []
    for (const submission of submissions) {
      submission.posted_at = tz.parse(submission.posted_at)
      student = this.student(submission.user_id)
      if (!student) {
        // if the student isn't loaded, we don't need to update it
        continue
      }
      idToMatch = getAssignmentColumnId(submission.assignment_id)
      for (const column of columns) {
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
    const changedColumnIds = Object.keys(changedColumnHeaders).map(getAssignmentColumnId)
    this.gradebookGrid?.gridSupport?.columns.updateColumnHeaders(changedColumnIds)
    return this.updateRowCellsForStudentIds([...new Set(changedStudentIds)])
  }

  submissionsForStudent = (student: GradebookStudent): Submission[] => {
    const allSubmissions: Submission[] = (function () {
      const results: Submission[] = []
      for (const key in student) {
        if (key.match(ASSIGNMENT_KEY_REGEX)) {
          results.push(student[key])
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
    return filter(allSubmissions, (submission: Submission) => {
      const studentPeriodInfo =
        this.effectiveDueDates[submission.assignment_id]?.[submission.user_id]
      return studentPeriodInfo && studentPeriodInfo.grading_period_id === this.gradingPeriodId
    })
  }

  getStudentGrades = (
    student: Student,
    preferCachedGrades: boolean
  ): {
    assignmentGroups: AssignmentGroupGradeMap
    gradingPeriods?: GradingPeriodGradeMap
    current: {
      score: number
      possible: number
    }
    final: {
      score: number
      possible: number
    }
    scoreUnit: 'points' | 'percentage'
  } => {
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

  calculateStudentGrade = (student: GradebookStudent, preferCachedGrades = false) => {
    if (!(student.loaded && student.initialized)) {
      return
    }

    let grades = this.getStudentGrades(student, preferCachedGrades)
    if (this.isFilteringColumnsByGradingPeriod() && this.gradingPeriodId && grades.gradingPeriods) {
      grades = grades.gradingPeriods[this.gradingPeriodId]
    }

    const scoreType = this.viewUngradedAsZero() ? 'final' : 'current'
    Object.keys(this.assignmentGroups).forEach((assignmentGroupId: string) => {
      const assignmentGroupGrade: AssignmentGroupGrade = grades.assignmentGroups[assignmentGroupId]
      let grade: AggregateGrade
      if (scoreType === 'current' && assignmentGroupGrade?.current) {
        grade = assignmentGroupGrade.current
      } else if (scoreType === 'final' && assignmentGroupGrade?.final) {
        grade = assignmentGroupGrade.final
      } else {
        grade = {
          score: 0,
          possible: 0,
          submission_count: 0,
          submissions: [],
        }
      }
      student[`assignment_group_${assignmentGroupId}`] = grade

      grade.submissions.forEach((submissionData: StudentGrade) => {
        // @ts-expect-error
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
  fixMaxHeaderWidth = () => this.$grid?.find('.slick-header-columns').width(1000000)

  // SlickGrid doesn't have a blur event for the grid, so this mimics it in
  // conjunction with a click listener on <body />. When we 'blur' the grid
  // by clicking outside of it, save the current field.

  onGridBlur = (e: Event) => {
    let className
    if (this.getSubmissionTrayState().open) {
      this.closeSubmissionTray()
    }
    // Prevent exiting the cell editor when clicking in the cell being edited.
    const editingNode = this.gradebookGrid?.gridSupport?.state.getEditingNode()
    if (editingNode != null ? editingNode.contains(e.target) : undefined) {
      return
    }
    const activeNode = this.gradebookGrid?.gridSupport?.state.getActiveNode()
    if (!activeNode) {
      return
    }
    if (activeNode.contains(e.target)) {
      // SlickGrid does not re-engage the editor for the active cell upon single click
      this.gradebookGrid?.gridSupport?.helper.beginEdit()
      return
    }
    if (!(e.target instanceof HTMLElement)) {
      throw new Error('Expected target to be an HTMLElement')
    }
    className = e.target.className
    // PopoverMenu's trigger sends an event with a target whose className is a SVGAnimatedString
    // This normalizes the className where possible
    if (typeof className !== 'string') {
      if (typeof className === 'object') {
        className = (className as SVGAnimatedString).baseVal || ''
      } else {
        className = ''
      }
    }
    // Do nothing if clicking on another cell
    if (className.match(/cell|slick/)) {
      return
    }
    this.gradebookGrid?.gridSupport?.state.blur()
  }

  updateSectionFilterVisibility = () => {
    if (this.options.enhanced_gradebook_filters) return
    const mountPoint = document.getElementById('sections-filter-container')
    if (
      this.showSections() &&
      this.gridDisplaySettings.selectedViewOptionsFilters.indexOf('sections') >= 0
    ) {
      const props = {
        sections: sectionList(this.sections),
        onSelect: this.updateCurrentSection,
        selectedSectionId: this.getFilterRowsBySetting('sectionId') || '0',
        disabled: !this.contentLoadStates.studentsLoaded,
      }
      renderComponent(SectionFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentSection(null)
      ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  updateCurrentSection = (sectionId: string | null) => {
    sectionId = sectionId === '0' ? null : sectionId
    const currentSection = this.getFilterRowsBySetting('sectionId')
    if (currentSection !== sectionId) {
      this.setFilterRowsBySetting('sectionId', sectionId)
      this.props.postGradesStore.setSelectedSection(sectionId)
      this.saveSettings()
    }
  }

  updateCurrentSections = (sectionIds: string[]) => {
    const savedSetting = this.getFilterRowsBySetting('sectionIds') || []
    if (!idArraysEqual(sectionIds, savedSetting)) {
      this.setFilterRowsBySetting('sectionIds', sectionIds)
      const sectionId = sectionIds.length > 0 ? sectionIds[sectionIds.length - 1] : null
      this.setFilterRowsBySetting('sectionId', sectionId)
      this.props.postGradesStore.setSelectedSection(sectionId)
      this.saveSettings()
    }
  }

  showSections = () => this.sections_enabled

  updateStudentGroupFilterVisibility = () => {
    if (this.options.enhanced_gradebook_filters) return
    const mountPoint = document.getElementById('student-group-filter-container')
    if (
      this.studentGroupsEnabled &&
      this.gridDisplaySettings.selectedViewOptionsFilters.indexOf('studentGroups') >= 0
    ) {
      const studentGroupSets = Object.values(this.studentGroupCategoriesById).sort(
        (a: StudentGroupCategory, b: StudentGroupCategory) => {
          return a.id.localeCompare(b.id)
        }
      )
      const props = {
        studentGroupSets,
        onSelect: this.updateCurrentStudentGroup,
        selectedStudentGroupId: this.getStudentGroupToShow(),
        disabled: !this.contentLoadStates.studentsLoaded,
      }
      renderComponent(StudentGroupFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentStudentGroup(null)
      ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  getStudentGroupToShow = (): string => {
    const groupId = this.getFilterRowsBySetting('studentGroupId') || '0'
    if (Object.keys(this.studentGroups || {}).indexOf(groupId) >= 0) {
      return groupId
    } else {
      return '0'
    }
  }

  updateCurrentStudentGroup = (groupId: string | null) => {
    groupId = groupId === '0' ? null : groupId
    if (this.getFilterRowsBySetting('studentGroupId') !== groupId) {
      this.setFilterRowsBySetting('studentGroupId', groupId)
      return this.saveSettings({}).then(() => {
        this.updateStudentGroupFilterVisibility()
        this.props.reloadStudentData()
      })
    }
  }

  updateCurrentStudentGroups = (groupIds: string[]) => {
    const savedSetting = this.getFilterRowsBySetting('studentGroupIds') || []
    if (!idArraysEqual(groupIds, savedSetting)) {
      this.setFilterRowsBySetting('studentGroupIds', groupIds)
      const groupId = groupIds.length > 0 ? groupIds[groupIds.length - 1] : null
      this.setFilterRowsBySetting('studentGroupId', groupId)
      return this.saveSettings({}).then(() => {
        this.updateStudentGroupFilterVisibility()
        this.props.reloadStudentData()
      })
    }
  }

  assignmentGroupList = () => {
    if (!this.assignmentGroups) {
      return []
    }
    return Object.values(this.assignmentGroups).sort(
      (a: AssignmentGroup, b: AssignmentGroup) => a.position - b.position
    )
  }

  updateAssignmentGroupFilterVisibility = () => {
    if (this.options.enhanced_gradebook_filters) return
    const mountPoint = document.getElementById('assignment-group-filter-container')
    const groups = this.assignmentGroupList()
    if (
      groups.length > 1 &&
      this.gridDisplaySettings.selectedViewOptionsFilters.indexOf('assignmentGroups') >= 0
    ) {
      const props = {
        assignmentGroups: groups,
        disabled: false,
        onSelect: this.updateCurrentAssignmentGroup,
        selectedAssignmentGroupId: this.getAssignmentGroupToShow(),
      }
      renderComponent(AssignmentGroupFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentAssignmentGroup(null)
      ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  updateCurrentAssignmentGroup = (groupId: string | null) => {
    if (this.getFilterColumnsBySetting('assignmentGroupId') !== groupId) {
      this.gridDisplaySettings.filterColumnsBy.assignmentGroupId = groupId
      this.saveSettings()
      this.resetGrading()
      this.updateFilteredContentInfo()
      this.updateColumnsAndRenderViewOptionsMenu()
      this.updateAssignmentGroupFilterVisibility()
    }
  }

  updateCurrentAssignmentGroups = (groupIds: string[]) => {
    const savedSetting = this.getFilterColumnsBySetting('assignmentGroupIds') || []
    if (!idArraysEqual(groupIds, savedSetting)) {
      this.setFilterColumnsBySetting('assignmentGroupIds', groupIds)
      const groupId = groupIds.length > 0 ? groupIds[groupIds.length - 1] : null
      this.setFilterColumnsBySetting('assignmentGroupId', groupId)
      this.saveSettings()
      this.resetGrading()
      this.updateFilteredContentInfo()
      this.updateColumnsAndRenderViewOptionsMenu()
      this.updateAssignmentGroupFilterVisibility()
    }
  }

  updateSubmissionsFilter = async (submissionFilter: SubmissionFilterValue) => {
    if (this.getFilterColumnsBySetting('submissions') !== submissionFilter) {
      const originalValue = this.gridDisplaySettings.filterColumnsBy.submissions
      this.gridDisplaySettings.filterColumnsBy.submissions = submissionFilter || null
      await this.saveSettings({}).catch(() => {
        this.gridDisplaySettings.filterColumnsBy.submissions = originalValue
      })
    }
  }

  updateSubmissionsFilters = async (submissionFilters: SubmissionFilterValue[]) => {
    const savedSetting = this.getFilterColumnsBySetting('submissionFilters') || []
    if (!idArraysEqual(submissionFilters, savedSetting)) {
      this.setFilterColumnsBySetting('submissionFilters', submissionFilters)
      const submissionFilter =
        submissionFilters.length > 0 ? submissionFilters[submissionFilters.length - 1] : null
      const originalValue = this.gridDisplaySettings.filterColumnsBy.submissions
      this.setFilterColumnsBySetting('submissions', submissionFilter)
      await this.saveSettings({}).catch(() => {
        this.gridDisplaySettings.filterColumnsBy.submissions = originalValue
      })
    }
  }

  updateGradingPeriodFilterVisibility = () => {
    if (this.options.enhanced_gradebook_filters) return
    const mountPoint = document.getElementById('grading-periods-filter-container')
    if (
      this.gradingPeriodSet != null &&
      this.gridDisplaySettings.selectedViewOptionsFilters.indexOf('gradingPeriods') >= 0
    ) {
      const props = {
        disabled: !this.contentLoadStates.assignmentsLoaded.all,
        gradingPeriods: this.gradingPeriodSet.gradingPeriods.sort(
          (a, b) => Number(a.startDate) - Number(b.startDate)
        ),
        onSelect: this.updateCurrentGradingPeriod,
        selectedGradingPeriodId: this.gradingPeriodId,
      }
      return renderComponent(GradingPeriodFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentGradingPeriod(null)
      ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  updateCurrentGradingPeriod = (period: string | null) => {
    if (this.getFilterColumnsBySetting('gradingPeriodId') !== period) {
      this.gridDisplaySettings.filterColumnsBy.gradingPeriodId = period
      this.setState({gradingPeriodId: period}, () => {
        this.renderActionMenu()
      })
      this.setCurrentGradingPeriod()
      this.saveSettings()
      this.resetGrading()
      this.sortGridRows()
      this.updateFilteredContentInfo()
      this.updateColumnsAndRenderViewOptionsMenu()
      this.updateGradingPeriodFilterVisibility()
      this.renderActionMenu()
    }
  }

  updateCurrentModule = (moduleId: string | null) => {
    if (this.getFilterColumnsBySetting('contextModuleId') !== moduleId) {
      this.gridDisplaySettings.filterColumnsBy.contextModuleId = moduleId
      this.saveSettings()
      this.updateFilteredContentInfo()
      this.updateColumnsAndRenderViewOptionsMenu()
      this.updateModulesFilterVisibility()
    }
  }

  updateCurrentModules = (moduleIds: string[]) => {
    const savedSetting = this.getFilterColumnsBySetting('contextModuleIds') || []
    if (!idArraysEqual(moduleIds, savedSetting)) {
      this.setFilterColumnsBySetting('contextModuleIds', moduleIds)
      const moduleId = moduleIds.length > 0 ? moduleIds[moduleIds.length - 1] : null
      this.setFilterColumnsBySetting('contextModuleId', moduleId)
      this.saveSettings()
      this.updateFilteredContentInfo()
      this.updateColumnsAndRenderViewOptionsMenu()
      this.updateModulesFilterVisibility()
    }
  }

  updateCurrentStartDate = (startDate: null | string) => {
    if (this.getFilterColumnsBySetting('startDate') !== startDate) {
      this.gridDisplaySettings.filterColumnsBy.startDate = startDate
      this.saveSettings()
    }
  }

  updateCurrentEndDate = (endDate: null | string) => {
    if (this.getFilterColumnsBySetting('endDate') !== endDate) {
      this.gridDisplaySettings.filterColumnsBy.endDate = endDate
      this.saveSettings()
    }
  }

  moduleList = () => {
    return this.courseContent.contextModules.sort((a: Module, b: Module) => a.position - b.position)
  }

  updateModulesFilterVisibility = () => {
    if (this.options.enhanced_gradebook_filters) return
    const mountPoint = document.getElementById('modules-filter-container')
    if (
      this.courseContent.contextModules.length > 0 &&
      this.gridDisplaySettings.selectedViewOptionsFilters.indexOf('modules') >= 0
    ) {
      const props = {
        disabled: false,
        modules: this.moduleList(),
        onSelect: this.updateCurrentModule,
        selectedModuleId: this.getModuleToShow(),
      }
      renderComponent(ModuleFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentModule(null)
      ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  initSubmissionStateMap = () => {
    this.submissionStateMap = new SubmissionStateMap({
      hasGradingPeriods: this.gradingPeriodSet != null,
      selectedGradingPeriodID: this.gradingPeriodId,
      isAdmin: isAdmin(),
    })
  }

  initPostGradesLtis = () => {
    this.postGradesLtis = this.options.post_grades_ltis.map(lti => {
      return {
        id: lti.id,
        name: lti.name,
        onSelect: () => {
          const postGradesDialog = new PostGradesFrameDialog({
            returnFocusTo: this.props.actionMenuNode.querySelector('button'),
            baseUrl: lti.data_url,
          })
          // 10 ms delay left over from original coffeescript implementation
          setTimeout(() => postGradesDialog.open(), 10)
          handleExternalContentMessages({
            service: 'external_tool_redirect',
            ready: () => {
              postGradesDialog.close()
            },
            cancel: () => {
              postGradesDialog.close()
            },
          })
        },
      }
    })
  }

  updatePostGradesFeatureButton = () => {
    this.disablePostGradesFeature =
      !this.props.postGradesStore.hasAssignments() || !this.props.postGradesStore.selectedSISId()
    return this.gridReady.promise.then(() => {
      this.renderActionMenu()
    })
  }

  initHeader = () => {
    this.renderGradebookMenus()
    this.renderFilters()
    this.arrangeColumnsBy(
      getColumnOrder(this.props.modules, this.gradebookColumnOrderSettings),
      true
    )
    this.renderGradebookSettingsModal()
    // EVAL-3711 Remove Evaluate ICE feature flag
    if (!window.ENV.FEATURES.instui_nav) {
      return $('#keyboard-shortcuts').click(function () {
        const questionMarkKeyDown = $.Event('keydown', {
          keyCode: 191,
          shiftKey: true,
        })
        return $(document).trigger(questionMarkKeyDown)
      })
    }
  }

  renderGradebookMenus = () => {
    this.renderViewOptionsMenu()
    this.renderActionMenu()
  }

  getTeacherNotesViewOptionsMenuProps = () => {
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
        this.contentLoadStates.teacherNotesColumnUpdating || this.gridReady.state !== 'resolved',
      onSelect,
      selected: showingNotes,
    }
  }

  getColumnSortSettingsViewOptionsMenuProps = () => {
    const storedSortOrder = getColumnOrder(this.props.modules, this.gradebookColumnOrderSettings)
    const criterion = isDefaultSortOrder(storedSortOrder.sortType)
      ? 'default'
      : storedSortOrder.sortType
    return {
      criterion,
      direction: storedSortOrder.direction || 'ascending',
      disabled: !this.assignmentsLoadedForCurrentView(),
      modulesEnabled: this.courseContent.contextModules.length > 0,
      onSortByDefault: () =>
        this.arrangeColumnsBy(
          {
            sortType: 'default',
            direction: 'ascending',
          },
          false
        ),
      onSortByNameAscending: () =>
        this.arrangeColumnsBy(
          {
            sortType: 'name',
            direction: 'ascending',
          },
          false
        ),
      onSortByNameDescending: () =>
        this.arrangeColumnsBy(
          {
            sortType: 'name',
            direction: 'descending',
          },
          false
        ),
      onSortByDueDateAscending: () =>
        this.arrangeColumnsBy(
          {
            sortType: 'due_date',
            direction: 'ascending',
          },
          false
        ),
      onSortByDueDateDescending: () =>
        this.arrangeColumnsBy(
          {
            sortType: 'due_date',
            direction: 'descending',
          },
          false
        ),
      onSortByPointsAscending: () =>
        this.arrangeColumnsBy(
          {
            sortType: 'points',
            direction: 'ascending',
          },
          false
        ),
      onSortByPointsDescending: () =>
        this.arrangeColumnsBy(
          {
            sortType: 'points',
            direction: 'descending',
          },
          false
        ),
      onSortByModuleAscending: () =>
        this.arrangeColumnsBy(
          {
            sortType: 'module_position',
            direction: 'ascending',
          },
          false
        ),
      onSortByModuleDescending: () =>
        this.arrangeColumnsBy(
          {
            sortType: 'module_position',
            direction: 'descending',
          },
          false
        ),
    }
  }

  getFilterSettingsViewOptionsMenuProps = () => ({
    available: this.listAvailableViewOptionsFilters(),
    onSelect: this.updateFilterSettings,
    selected: this.listSelectedViewOptionsFilters(),
  })

  updateFilterSettings = (filters: string[]) => {
    this.setSelectedViewOptionsFilters(filters)
    this.renderViewOptionsMenu()
    this.renderFilters()
    this.saveSettings()
  }

  getViewOptionsMenuProps = () => {
    return {
      teacherNotes: this.getTeacherNotesViewOptionsMenuProps(),
      columnSortSettings: this.getColumnSortSettingsViewOptionsMenuProps(),
      filterSettings: this.getFilterSettingsViewOptionsMenuProps(),
      showUnpublishedAssignments: this.gridDisplaySettings.showUnpublishedAssignments,
      onSelectShowUnpublishedAssignments: this.toggleUnpublishedAssignments,
      allowShowSeparateFirstLastNames: this.options.allow_separate_first_last_names,
      showSeparateFirstLastNames: this.gridDisplaySettings.showSeparateFirstLastNames,
      onSelectShowSeparateFirstLastNames: this.toggleShowSeparateFirstLastNames,
      hideAssignmentGroupTotals: this.gridDisplaySettings.hideAssignmentGroupTotals,
      onSelectHideAssignmentGroupTotals: this.toggleHideAssignmentGroupTotals,
      hideTotal: this.gridDisplaySettings.hideTotal,
      onSelectHideTotal: this.toggleHideTotal,
      onSelectShowStatusesModal: () => this.setState({isStatusesModalOpen: true}),
      onSelectViewUngradedAsZero: () => {
        confirmViewUngradedAsZero({
          currentValue: this.gridDisplaySettings.viewUngradedAsZero,
          onAccepted: () => {
            this.toggleViewUngradedAsZero()
          },
        })
      },
      viewUngradedAsZero: this.gridDisplaySettings.viewUngradedAsZero,
      allowViewUngradedAsZero: this.courseFeatures.allowViewUngradedAsZero,
    }
  }

  renderViewOptionsMenu = () => {
    if (this.options.enhanced_gradebook_filters) return

    // TODO: if enhanced_gradebook_filters is enabled, we can skip rendering
    // this menu when we have the filters in place. Until then, keep rendering
    // it so we can still filter when we have the flag on.

    const mountPoint = this.props.viewOptionsMenuNode
    this.viewOptionsMenu = renderComponent(
      ViewOptionsMenu,
      mountPoint,
      this.getViewOptionsMenuProps()
    )
  }

  getAssignmentOrder = (assignmentGroupId?: string): string[] => {
    return this.gridData.columns.scrollable.reduce((acc: string[], column: string) => {
      const matches = column.match(/assignment_(\d+)/)
      if (matches) {
        if (
          assignmentGroupId === undefined ||
          this.assignments[parseInt(matches[1], 10)]?.assignment_group_id === assignmentGroupId
        ) {
          const assignmentId = matches[1]
          acc.push(assignmentId)
        }
      }
      return acc
    }, [])
  }

  getStudentOrder = (): string[] => this.gridData.rows.map(row => row.id)

  getActionMenuProps = () => {
    let attachmentData: AttachmentData
    const focusReturnPoint = this.props.actionMenuNode.querySelector('button')
    const actionMenuProps: ActionMenuProps = {
      gradebookIsEditable: this.options.gradebook_is_editable,
      contextAllowsGradebookUploads: this.options.context_allows_gradebook_uploads,
      gradebookImportUrl: this.options.gradebook_import_url,
      showStudentFirstLastName: this.gridDisplaySettings.showSeparateFirstLastNames,
      currentUserId: this.props.currentUserId,
      gradebookExportUrl: this.options.export_gradebook_csv_url,
      postGradesLtis: this.postGradesLtis,
      postGradesFeature: {
        enabled: this.options.post_grades_feature && !this.disablePostGradesFeature,
        returnFocusTo: focusReturnPoint,
        label: this.options.sis_name,
        store: this.props.postGradesStore,
      },
      publishGradesToSis: {
        isEnabled: this.options.publish_to_sis_enabled,
        publishToSisUrl: this.options.publish_to_sis_url,
      },
      gradingPeriodId: this.state.gradingPeriodId,
      getStudentOrder: this.getStudentOrder,
      getAssignmentOrder: this.getAssignmentOrder,
      updateExportState: (name?: string, val?: number) =>
        this.setState({
          exportState: {
            completion: val,
            filename: name,
          },
        }),
      setExportManager: (manager?: GradebookExportManager) =>
        this.setState({exportManager: manager}),
    }
    if (this.options.gradebook_csv_progress) {
      const progressData = this.options.gradebook_csv_progress
      actionMenuProps.lastExport = {
        progressId: `${progressData.progress.id}`,
        workflowState: progressData.progress.workflow_state,
      }
      attachmentData = this.options.attachment
      if (attachmentData) {
        actionMenuProps.attachment = {
          id: `${attachmentData.attachment.id}`,
          downloadUrl: this.options.attachment_url,
          updatedAt: attachmentData.attachment.updated_at,
          createdAt: attachmentData.attachment.created_at,
        }
      }
    }
    return actionMenuProps
  }

  renderActionMenu = () => {
    const props = this.getActionMenuProps()
    if (this.options.enhanced_gradebook_filters) {
      renderComponent(EnhancedActionMenu, this.props.enhancedActionMenuNode, props)
    } else {
      renderComponent(ActionMenu, this.props.actionMenuNode, props)
    }
  }

  renderFilters = () => {
    // Sections and grading periods are passed into the constructor, and therefore are always
    // available, whereas assignment groups and context modules are fetched via the DataLoader,
    // so we need to wait until they are loaded to set their filter visibility.
    this.updateSectionFilterVisibility()
    this.updateStudentGroupFilterVisibility()
    if (this.contentLoadStates.assignmentGroupsLoaded) {
      this.updateAssignmentGroupFilterVisibility()
    }
    this.updateGradingPeriodFilterVisibility()
    if (!this.props.isModulesLoading) {
      this.updateModulesFilterVisibility()
    }
  }

  renderGradebookSettingsModal = () => {
    const props: GradebookSettingsModalProps = {
      anonymousAssignmentsPresent: some(this.assignments, (assignment: Assignment) => {
        return assignment.anonymous_grading
      }),
      courseId: this.options.context_id,
      courseFeatures: this.courseFeatures,
      courseSettings: this.courseSettings,
      gradedLateSubmissionsExist: this.options.graded_late_submissions_exist,
      locale: this.props.locale,
      gradebookIsEditable: this.options.gradebook_is_editable,
      onClose: () => {
        return this.gradebookSettingsModalButton.current?.focus()
      },
      onCourseSettingsUpdated: (settings: {allowFinalGradeOverride: boolean}) =>
        this.courseSettings.handleUpdated(settings, this.props.fetchFinalGradeOverrides),
      onLatePolicyUpdate: this.onLatePolicyUpdate,
      postPolicies: this.postPolicies,
      ref: this.gradebookSettingsModal,
    }

    if (this.options.enhanced_gradebook_filters) {
      Object.assign(props, this.gradebookSettingsModalViewOptionsProps())
    }

    AsyncComponents.renderGradebookSettingsModal(props, this.props.gradebookSettingsModalContainer)
  }

  gradebookSettingsModalViewOptionsProps = () => {
    const {modulesEnabled} = this.getColumnSortSettingsViewOptionsMenuProps()

    return {
      allowSortingByModules: modulesEnabled,
      allowShowSeparateFirstLastNames: this.options.allow_separate_first_last_names,
      allowViewUngradedAsZero: this.courseFeatures.allowViewUngradedAsZero,
      loadCurrentViewOptions: (): GradebookViewOptions => {
        const {criterion, direction} = this.getColumnSortSettingsViewOptionsMenuProps()
        const {
          viewUngradedAsZero,
          showUnpublishedAssignments,
          showSeparateFirstLastNames,
          hideAssignmentGroupTotals,
          hideTotal,
        } = this.gridDisplaySettings

        return {
          columnSortSettings: {criterion, direction},
          hideTotal,
          showNotes: this.isTeacherNotesColumnShown(),
          showSeparateFirstLastNames,
          showUnpublishedAssignments,
          hideAssignmentGroupTotals,
          statusColors: this.state.gridColors,
          viewUngradedAsZero,
        }
      },
      onViewOptionsUpdated: this.handleViewOptionsUpdated,
    }
  }

  handleViewOptionsUpdated = ({
    columnSortSettings: {criterion, direction} = {
      criterion: 'assignment_group',
      direction: 'ascending',
    },
    hideAssignmentGroupTotals,
    hideTotal,
    showNotes,
    showUnpublishedAssignments,
    showSeparateFirstLastNames,
    statusColors: colors,
    viewUngradedAsZero,
  }: {
    columnSortSettings: {criterion: string; direction: SortDirection}
    hideAssignmentGroupTotals?: boolean
    hideTotal?: boolean
    showNotes: boolean
    showUnpublishedAssignments?: boolean
    showSeparateFirstLastNames?: boolean
    statusColors?: StatusColors
    viewUngradedAsZero?: boolean
  }): Promise<void | void[]> => {
    // We may have to save changes to more than one endpoint, depending on
    // which options have changed. Additionally, a couple options require us to
    // update the grid when they change. Let's sort out which endpoints we
    // actually need to call and return a single promise encapsulating all of
    // them.
    const promises: Promise<void>[] = []

    // Column sort settings have their own endpoint.
    const {criterion: oldCriterion, direction: oldDirection} =
      this.getColumnSortSettingsViewOptionsMenuProps()
    const columnSortSettingsChanged = criterion !== oldCriterion || direction !== oldDirection
    if (columnSortSettingsChanged) {
      promises.push(this.saveUpdatedColumnOrder({criterion, direction}))
    }

    // We save changes to the notes column using the custom column API.
    if (showNotes !== this.isTeacherNotesColumnShown()) {
      promises.push(this.saveUpdatedTeacherNotesSetting({showNotes}))
    }

    // Finally, the remaining options are saved to the user's settings.
    const {
      hideAssignmentGroupTotals: oldHideAssignmentGroupTotals,
      hideTotal: oldHideTotal,
      showUnpublishedAssignments: oldShowUnpublished,
      showSeparateFirstLastNames: oldShowSeparateFirstLastNames,
      viewUngradedAsZero: oldViewUngradedAsZero,
    } = this.gridDisplaySettings

    const viewUngradedAsZeroChanged =
      this.courseFeatures.allowViewUngradedAsZero && oldViewUngradedAsZero !== viewUngradedAsZero
    const showUnpublishedChanged = oldShowUnpublished !== showUnpublishedAssignments
    const showSeparateFirstLastNamesChanged =
      oldShowSeparateFirstLastNames !== showSeparateFirstLastNames
    const colorsChanged = !isEqual(this.state.gridColors, colors)
    const hideAssignmentGroupTotalsChanged =
      oldHideAssignmentGroupTotals !== hideAssignmentGroupTotals
    const hideTotalChanged = oldHideTotal !== hideTotal

    if (
      colorsChanged ||
      hideAssignmentGroupTotalsChanged ||
      hideTotalChanged ||
      showUnpublishedChanged ||
      viewUngradedAsZeroChanged ||
      showSeparateFirstLastNamesChanged
    ) {
      const changedSettings = {
        colors: colorsChanged ? colors : undefined,
        hideAssignmentGroupTotals: hideAssignmentGroupTotalsChanged
          ? hideAssignmentGroupTotals
          : undefined,
        hideTotal: hideTotalChanged ? hideTotal : undefined,
        showUnpublishedAssignments: showUnpublishedChanged ? showUnpublishedAssignments : undefined,
        showSeparateFirstLastNames: showSeparateFirstLastNamesChanged
          ? showSeparateFirstLastNames
          : undefined,
        viewUngradedAsZero: viewUngradedAsZeroChanged ? viewUngradedAsZero : undefined,
      }
      promises.push(this.saveUpdatedUserSettings(changedSettings))
    }

    return Promise.all(promises)
      .catch(FlashAlert.showFlashError(I18n.t('There was an error updating view options.')))
      .finally(() => {
        // Regardless of which options we changed, we most likely need to
        // update the columns and grid.
        this.updateColumns()
        this.updateGrid()
      })
  }

  saveUpdatedColumnOrder = ({
    criterion,
    direction,
  }: {
    criterion: string
    direction?: SortDirection
  }) => {
    const newSortOrder = {direction, sortType: criterion}
    const {freezeTotalGrade} = getColumnOrder(this.props.modules, this.gradebookColumnOrderSettings)

    return this.props
      .updateColumnOrder(this.options.context_id, {
        ...newSortOrder,
        freezeTotalGrade,
      })
      .then(() => {
        this.setColumnOrder(newSortOrder)
        const columns = this.gridData.columns.scrollable.map(
          columnId => this.gridData.columns.definitions[columnId]
        )
        const fn = this.makeColumnSortFn(newSortOrder)
        columns.sort(fn)
        this.gridData.columns.scrollable = columns.map(column => column.id)
      })
  }

  saveUpdatedUserSettings = ({
    colors,
    hideAssignmentGroupTotals,
    hideTotal,
    showUnpublishedAssignments,
    viewUngradedAsZero,
    showSeparateFirstLastNames,
  }: {
    colors?: StatusColors
    hideAssignmentGroupTotals?: boolean
    hideTotal?: boolean
    showUnpublishedAssignments?: boolean
    viewUngradedAsZero?: boolean
    showSeparateFirstLastNames?: boolean
  }) => {
    return this.saveSettings({
      colors,
      hideAssignmentGroupTotals,
      hideTotal,
      showUnpublishedAssignments,
      showSeparateFirstLastNames,
      viewUngradedAsZero,
    }).then(() => {
      // Make various updates to the grid depending on what changed.  These
      // triple-equals checks are deliberate: null could be an actual value for
      // the setting, so we use undefined to indicate that the setting hasn't
      // changed and hence we don't need to update it.

      if (colors !== undefined) {
        this.gridDisplaySettings.colors = colors
        this.setState({gridColors: statusColors(this.gridDisplaySettings.colors)})
      }

      if (hideAssignmentGroupTotals !== undefined) {
        this.gridDisplaySettings.hideAssignmentGroupTotals = hideAssignmentGroupTotals
      }

      if (hideTotal !== undefined) {
        this.gridDisplaySettings.hideTotal = hideTotal
        this.updateAllTotalColumns()
      }

      if (showUnpublishedAssignments !== undefined) {
        this.gridDisplaySettings.showUnpublishedAssignments = showUnpublishedAssignments
      }

      if (viewUngradedAsZero !== undefined) {
        this.gridDisplaySettings.viewUngradedAsZero = viewUngradedAsZero
        this.courseContent.students.listStudents().forEach(student => {
          this.calculateStudentGrade(student, true)
        })
        this.updateAllTotalColumns()
      }

      if (showSeparateFirstLastNames !== undefined) {
        this.gridDisplaySettings.showSeparateFirstLastNames = showSeparateFirstLastNames
        this.renderActionMenu()
      }
    })
  }

  saveUpdatedTeacherNotesSetting = ({showNotes}: {showNotes: boolean}) => {
    let promise

    const existingColumn = this.getTeacherNotesColumn()
    if (existingColumn != null) {
      promise = GradebookApi.updateTeacherNotesColumn(this.options.context_id, existingColumn.id, {
        hidden: !showNotes,
      })
    } else {
      promise = GradebookApi.createTeacherNotesColumn(this.options.context_id).then(response => {
        this.gradebookContent.customColumns.push(response.data)
        const teacherNotesColumn = buildCustomColumn(response.data)
        this.gridData.columns.definitions[teacherNotesColumn.id] = teacherNotesColumn
      })
    }

    return promise.then(() => {
      if (showNotes) {
        this.showNotesColumn()
        this.props.reorderCustomColumns(this.gradebookContent.customColumns.map(c => c.id))
      } else {
        this.hideNotesColumn()
      }
    })
  }

  checkForUploadComplete = () => {
    if (UserSettings.contextGet('gradebookUploadComplete')) {
      $.flashMessage(I18n.t('Upload successful'))
      return UserSettings.contextRemove('gradebookUploadComplete')
    }
  }

  weightedGroups = () => this.options.group_weighting_scheme === 'percent'

  weightedGrades = () => this.weightedGroups() || !!this.gradingPeriodSet?.weighted

  switchTotalDisplay = ({dontWarnAgain = false} = {}) => {
    if (dontWarnAgain) {
      UserSettings.contextSet('warned_about_totals_display', true)
    }
    this.options.show_total_grade_as_points = !this.options.show_total_grade_as_points
    $.ajaxJSON(this.options.setting_update_url, 'PUT', {
      show_total_grade_as_points: this.options.show_total_grade_as_points,
    })
    this.gradebookGrid?.invalidate()
    if (this.courseSettings.allowFinalGradeOverride) {
      return this.gradebookGrid?.gridSupport?.columns.updateColumnHeaders([
        'total_grade',
        'total_grade_override',
      ])
    } else {
      return this.gradebookGrid?.gridSupport?.columns.updateColumnHeaders(['total_grade'])
    }
  }

  togglePointsOrPercentTotals = (cb: () => void) => {
    let dialog_options
    if (UserSettings.contextGet<boolean>('warned_about_totals_display')) {
      this.switchTotalDisplay()
      if (typeof cb === 'function') {
        return cb()
      }
    } else {
      dialog_options = {
        showing_points: this.options.show_total_grade_as_points,
        save: this.switchTotalDisplay,
        onClose: cb,
      }
      return new GradeDisplayWarningDialog(dialog_options)
    }
  }

  onFilterToStudents = (studentIds: string[]) => {
    this.searchFilteredStudentIds = studentIds
    this.updateFilterAssignmentIds()
    const hasChanged = this.setVisibleGridColumns()
    if (hasChanged) {
      this.updateGrid()
    }
    this.updateRows()
  }

  onFilterToAssignments = (assignmentIds: string[]) => {
    this.searchFilteredAssignmentIds = assignmentIds
    const hasChanged = this.setVisibleGridColumns()
    if (hasChanged) {
      this.updateGrid()
      this.updateRows()
    }
  }

  studentSearchMatcher = (
    option: {
      id: string
      label: string
    },
    searchTerm: string
  ) => {
    const term = searchTerm?.toLowerCase() || ''
    const studentName = option.label?.toLowerCase() || ''

    if (studentName.includes(term)) {
      return true
    }

    const {sis_user_id: sisId} = this.courseContent.students.student(option.id)
    return !!sisId && sisId.toLowerCase() === term
  }

  getVisibleGridColumns = () => {
    let parentColumnIds = this.gridData.columns.frozen.filter(
      columnId => !/^custom_col_/.test(columnId) && !/^student/.test(columnId)
    )
    if (this.gridDisplaySettings.showSeparateFirstLastNames) {
      parentColumnIds = ['student_lastname', 'student_firstname'].concat(parentColumnIds)
    } else {
      parentColumnIds = ['student'].concat(parentColumnIds)
    }
    const visibleCustomColumns = this.gradebookContent.customColumns.filter(
      column => !column.hidden
    )
    const customColumnIds = visibleCustomColumns.map(column => getCustomColumnId(column.id))
    this.updateFilterAssignmentIds()
    const scrollableColumns = this.filteredAssignmentIds
      .map(assignmentId => this.gridData.columns.definitions[getAssignmentColumnId(assignmentId)])
      .filter(Boolean)
    if (!hideAggregateColumns(this.gradingPeriodSet, this.gradingPeriodId)) {
      for (const assignmentGroupId in this.assignmentGroups) {
        const column =
          this.gridData.columns.definitions[getAssignmentGroupColumnId(assignmentGroupId)]
        if (column) {
          if (
            this.options.enhanced_gradebook_filters &&
            this.gridDisplaySettings.hideAssignmentGroupTotals
          )
            continue
          scrollableColumns.push(column)
        }
      }
      if (getColumnOrder(this.props.modules, this.gradebookColumnOrderSettings).freezeTotalGrade) {
        if (!parentColumnIds.includes('total_grade')) {
          parentColumnIds.push('total_grade')
        }
      } else {
        const column = this.gridData.columns.definitions.total_grade
        if (
          column &&
          !(this.options.enhanced_gradebook_filters && this.gridDisplaySettings.hideTotal)
        ) {
          scrollableColumns.push(column)
        }
      }
      if (
        this.courseSettings.allowFinalGradeOverride &&
        !(this.options.enhanced_gradebook_filters && this.gridDisplaySettings.hideTotal)
      ) {
        const column = this.gridData.columns.definitions.total_grade_override
        if (column) {
          scrollableColumns.push(column)
        }
      }
    }
    if (this.gradebookColumnOrderSettings?.sortType) {
      scrollableColumns.sort(
        this.makeColumnSortFn(getColumnOrder(this.props.modules, this.gradebookColumnOrderSettings))
      )
    }
    return {
      frozen: [...parentColumnIds, ...customColumnIds],
      scrollable: scrollableColumns.map(column => column.id),
    }
  }

  setVisibleGridColumns = () => {
    const {frozen, scrollable} = this.getVisibleGridColumns()
    const hasChanged =
      !isEqual(frozen, this.gridData.columns.frozen) ||
      !isEqual(scrollable, this.gridData.columns.scrollable)
    this.gridData.columns.frozen = frozen
    this.gridData.columns.scrollable = scrollable
    this.updateFilterAssignmentIds()
    return hasChanged
  }

  updateGrid = () => {
    this.gradebookGrid?.updateColumns()
    this.gradebookGrid?.invalidate()
  }

  // # Grid Column Definitions

  // Assignment Column
  buildAssignmentColumn = (assignment: Assignment): GridColumn => {
    let assignmentWidth
    const shrinkForOutOfText =
      assignment && assignment.grading_type === 'points' && assignment.points_possible != null
    const minWidth = shrinkForOutOfText ? 140 : 90
    const columnId = getAssignmentColumnId(assignment.id)
    const fieldName = `assignment_${assignment.id}`
    if (this.gradebookColumnSizeSettings && this.gradebookColumnSizeSettings[fieldName]) {
      assignmentWidth = parseInt(this.gradebookColumnSizeSettings[fieldName], 10)
      if (Number.isNaN(assignmentWidth)) {
        assignmentWidth = testWidth(assignment.name, minWidth, columnWidths.assignment.default_max)
      }
    } else {
      assignmentWidth = testWidth(assignment.name, minWidth, columnWidths.assignment.default_max)
    }
    const columnDef = {
      id: columnId,
      field: fieldName,
      object: assignment,
      getGridSupport: () => this.gradebookGrid?.gridSupport,
      propFactory: new AssignmentRowCellPropFactory(this),
      minWidth: columnWidths.assignment.min,
      maxWidth: columnWidths.assignment.max,
      width: assignmentWidth,
      cssClass: `assignment ${columnId}`,
      headerCssClass: `assignment ${columnId}`,
      toolTip: assignment.name,
      type: 'assignment',
      assignmentId: assignment.id,
    }
    if (!(columnDef.width > columnDef.minWidth)) {
      columnDef.cssClass += ' minimized'
      columnDef.headerCssClass += ' minimized'
    }
    return columnDef
  }

  buildTotalGradeColumn = () => {
    let totalWidth
    const label = I18n.t('Total')
    if (this.gradebookColumnSizeSettings && this.gradebookColumnSizeSettings.total_grade) {
      totalWidth = parseInt(this.gradebookColumnSizeSettings.total_grade, 10)
    } else {
      totalWidth = testWidth(label, columnWidths.total.min, columnWidths.total.max)
    }
    return {
      cssClass: 'total-cell total_grade',
      field: 'total_grade',
      headerCssClass: 'total_grade',
      id: 'total_grade',
      maxWidth: columnWidths.total.max,
      minWidth: columnWidths.total.min,
      object: {},
      toolTip: label,
      type: 'total_grade',
      width: totalWidth,
    }
  }

  buildTotalGradeOverrideColumn = () => {
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
        return this.gradebookGrid?.gridSupport
      },
      headerCssClass: 'total-grade-override',
      id: 'total_grade_override',
      maxWidth: columnWidths.total_grade_override.max,
      minWidth: columnWidths.total_grade_override.min,
      object: {},
      propFactory: new TotalGradeOverrideCellPropFactory(this),
      toolTip: label,
      type: 'total_grade_override',
      width: totalWidth,
    }
  }

  initGrid = () => {
    let assignmentGroup, assignmentGroupColumn, id
    this.updateFilteredContentInfo()
    const studentColumn = buildStudentColumn(
      'student',
      this.gradebookColumnSizeSettings?.student,
      150
    )
    this.gridData.columns.definitions[studentColumn.id] = studentColumn
    this.gridData.columns.frozen.push(studentColumn.id)
    const studentColumnLastName = buildStudentColumn(
      'student_lastname',
      this.gradebookColumnSizeSettings?.student_lastname,
      155
    )
    this.gridData.columns.definitions[studentColumnLastName.id] = studentColumnLastName
    this.gridData.columns.frozen.push(studentColumnLastName.id)
    const studentColumnFirstName = buildStudentColumn(
      'student_firstname',
      this.gradebookColumnSizeSettings?.student_firstname,
      155
    )
    this.gridData.columns.definitions[studentColumnFirstName.id] = studentColumnFirstName
    this.gridData.columns.frozen.push(studentColumnFirstName.id)

    const ref2 = this.assignmentGroups
    const buildAssignmentGroupColumn = buildAssignmentGroupColumnFn(
      this.gradebookColumnSizeSettings
    )
    for (id in ref2) {
      assignmentGroup = ref2[id]
      assignmentGroupColumn = buildAssignmentGroupColumn(assignmentGroup)
      this.gridData.columns.definitions[assignmentGroupColumn.id] = assignmentGroupColumn
    }
    const totalGradeColumn = this.buildTotalGradeColumn()
    this.gridData.columns.definitions[totalGradeColumn.id] = totalGradeColumn
    const totalGradeOverrideColumn = this.buildTotalGradeOverrideColumn()
    this.gridData.columns.definitions[totalGradeOverrideColumn.id] = totalGradeOverrideColumn
    this.createGrid()
  }

  // Grid DOM Access/Reference Methods
  addAssignmentColumnDefinition = (assignment: Assignment) => {
    const assignmentColumn = this.buildAssignmentColumn(assignment)
    if (!this.gridData.columns.definitions[assignmentColumn.id]) {
      this.gridData.columns.definitions[assignmentColumn.id] = assignmentColumn
    }
  }

  createGrid = () => {
    this.setVisibleGridColumns()
    this.gradebookGrid?.initialize()
    if (!this.gradebookGrid?.gridSupport) throw new Error('grid did not initialize')
    // This is a faux blur event for SlickGrid.
    // Use capture to preempt SlickGrid's internal handlers.
    document.getElementById('application')?.addEventListener('click', this.onGridBlur, true)
    // Grid Events
    this.gradebookGrid.grid.onKeyDown.subscribe(onGridKeyDown)
    // Grid Body Cell Events
    this.gradebookGrid.grid.onBeforeEditCell.subscribe(this.onBeforeEditCell)
    this.gradebookGrid.grid.onCellChange.subscribe(this.onCellChange)
    this.keyboardNav = new GradebookKeyboardNav({
      gridSupport: this.gradebookGrid.gridSupport,
      getColumnTypeForColumnId,
      toggleDefaultSort: this.toggleDefaultSort,
      openSubmissionTray: this.openSubmissionTray,
    })
    this.gradebookGrid.gridSupport.initialize()
    this.gradebookGrid.gridSupport.events.onActiveLocationChanged.subscribe(
      (event: Event, location: GridLocation) => {
        if (
          ['student', 'student_lastname'].includes(location.columnId) &&
          location.region === 'body'
        ) {
          // In IE11, if we're navigating into the student column from a grade
          // input cell with no text, this focus() call will select the <body>
          // instead of the grades link.  Delaying the call (even with no actual
          // delay) fixes the issue.
          return setTimeout(() => {
            if (!this.gradebookGrid?.gridSupport) throw new Error('grid is not initialized')
            const ref1 = this.gradebookGrid?.gridSupport.state
              .getActiveNode()
              .querySelector('.student-grades-link')
            return ref1 != null ? ref1.focus() : undefined
          }, 0)
        }
      }
    )
    this.gradebookGrid.gridSupport.events.onKeyDown.subscribe(
      (event: React.KeyboardEvent<Element>, location: GridLocation) => {
        let ref1
        if (location.region === 'header') {
          return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
            ? ref1.handleKeyDown(event)
            : undefined
        }
      }
    )
    this.gradebookGrid.gridSupport.events.onNavigatePrev.subscribe(
      (event: Event, location: GridLocation) => {
        let ref1
        if (location.region === 'header') {
          return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
            ? ref1.focusAtStart()
            : undefined
        }
      }
    )
    this.gradebookGrid.gridSupport.events.onNavigateNext.subscribe(
      (event: Event, location: GridLocation) => {
        let ref1
        if (location.region === 'header') {
          return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
            ? ref1.focusAtStart()
            : undefined
        }
      }
    )
    this.gradebookGrid.gridSupport.events.onNavigateLeft.subscribe(
      (event: Event, location: GridLocation) => {
        let ref1
        if (location.region === 'header') {
          return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
            ? ref1.focusAtStart()
            : undefined
        }
      }
    )
    this.gradebookGrid.gridSupport.events.onNavigateRight.subscribe(
      (event: Event, location: GridLocation) => {
        let ref1
        if (location.region === 'header') {
          return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
            ? ref1.focusAtStart()
            : undefined
        }
      }
    )
    this.gradebookGrid.gridSupport.events.onNavigateUp.subscribe(
      (event: Event, location: GridLocation) => {
        if (location.region === 'header') {
          // As above, "delay" the call so that we properly focus the header cell
          // when navigating from a grade input cell with no text.
          return setTimeout(() => {
            let ref1
            return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
              ? ref1.focusAtStart()
              : undefined
          }, 0)
        }
      }
    )
    return this.onGridInit()
  }

  onGridInit = () => {
    $('#gradebook-grid-wrapper').show()
    this.uid = this.gradebookGrid?.grid.getUID()
    $('#accessibility_warning').focus(function () {
      $('#accessibility_warning').removeClass('screenreader-only')
      return $('#accessibility_warning').blur(function () {
        return $('#accessibility_warning').addClass('screenreader-only')
      })
    })
    this.$grid = $('#gradebook_grid').fillWindowWithMe({
      onResize: () => this.gradebookGrid?.grid.resizeCanvas(),
    })
    if (this.options.gradebook_is_editable) {
      this.$grid?.addClass('editable')
    }
    this.fixMaxHeaderWidth()
    this.keyboardNav?.init()
    const keyBindings = this.keyboardNav?.keyBindings
    this.kbDialog = new KeyboardNavDialog().render(KeyboardNavTemplate({keyBindings}))
    return $(document).trigger('gridready')
  }

  // The target cell will enter editing mode
  onBeforeEditCell = (_event: Event, obj: {item: Student; column: GridColumn}) => {
    let ref1
    if (
      obj.column.type === 'custom_column' &&
      obj.column.customColumnId &&
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

  // The current cell editor has been changed and is valid
  onCellChange = (_event: Event, obj: {item: GradebookStudent; column: GridColumn}) => {
    let col_id, url
    const {item, column} = obj
    if (column.type === 'custom_column' && column.field) {
      col_id = column.field.match(/^custom_col_(\d+)/)
      url = this.options.custom_column_datum_url
        .replace(/:id/, col_id?.[1] || '')
        .replace(/:user_id/, item.id)
      return $.ajaxJSON(url, 'PUT', {
        'column_data[content]': item[column.field],
      })
    } else {
      // this is the magic that actually updates group and final grades when you edit a cell
      this.calculateStudentGrade(item)
      return this.gradebookGrid?.invalidate()
    }
  }

  // Persisted Gradebook Settings
  saveColumnWidthPreference = (id: string, newWidth: number) => {
    const url = this.options.gradebook_column_size_settings_url
    return $.ajaxJSON(url, 'POST', {
      column_id: id,
      column_size: newWidth,
    })
  }

  saveSettings = ({
    hideAssignmentGroupTotals = this.gridDisplaySettings.hideAssignmentGroupTotals,
    hideTotal = this.gridDisplaySettings.hideTotal,
    selectedViewOptionsFilters = this.listSelectedViewOptionsFilters(),
    showConcludedEnrollments = this.getEnrollmentFilters().concluded,
    showInactiveEnrollments = this.getEnrollmentFilters().inactive,
    showUnpublishedAssignments = this.gridDisplaySettings.showUnpublishedAssignments,
    showSeparateFirstLastNames = this.gridDisplaySettings.showSeparateFirstLastNames,
    studentColumnDisplayAs = this.getSelectedPrimaryInfo(),
    studentColumnSecondaryInfo = this.getSelectedSecondaryInfo(),
    sortRowsBy = this.getSortRowsBySetting(),
    viewUngradedAsZero = this.gridDisplaySettings.viewUngradedAsZero,
    colors = this.state.gridColors,
  } = {}) => {
    if (!(selectedViewOptionsFilters.length > 0)) {
      selectedViewOptionsFilters.push('')
    }
    const gradebook_settings: GradebookSettings = {
      enter_grades_as: this.gridDisplaySettings.enterGradesAs,
      filter_columns_by: {
        assignment_group_id: this.gridDisplaySettings.filterColumnsBy.assignmentGroupId,
        context_module_id: this.gridDisplaySettings.filterColumnsBy.contextModuleId,
        grading_period_id: this.gridDisplaySettings.filterColumnsBy.gradingPeriodId,
        submissions: this.gridDisplaySettings.filterColumnsBy.submissions,
        start_date: this.gridDisplaySettings.filterColumnsBy.startDate,
        end_date: this.gridDisplaySettings.filterColumnsBy.endDate,
      },
      filter_rows_by: {
        section_id: this.gridDisplaySettings.filterRowsBy.sectionId,
        student_group_id: this.gridDisplaySettings.filterRowsBy.studentGroupId,
      },
      hide_assignment_group_totals: hideAssignmentGroupTotals ? 'true' : 'false',
      hide_total: hideTotal ? 'true' : 'false',
      selected_view_options_filters: selectedViewOptionsFilters,
      show_concluded_enrollments: showConcludedEnrollments ? 'true' : 'false',
      show_inactive_enrollments: showInactiveEnrollments ? 'true' : 'false',
      show_unpublished_assignments: showUnpublishedAssignments ? 'true' : 'false',
      show_separate_first_last_names: showSeparateFirstLastNames ? 'true' : 'false',
      student_column_display_as: studentColumnDisplayAs,
      student_column_secondary_info: studentColumnSecondaryInfo,
      sort_rows_by_column_id: sortRowsBy.columnId,
      sort_rows_by_setting_key: sortRowsBy.settingKey,
      sort_rows_by_direction: sortRowsBy.direction,
      view_ungraded_as_zero: viewUngradedAsZero ? 'true' : 'false',
      colors,
    }

    if (this.options.multiselect_gradebook_filters_enabled) {
      gradebook_settings.filter_rows_by.student_group_ids =
        this.gridDisplaySettings.filterRowsBy.studentGroupIds
      gradebook_settings.filter_rows_by.section_ids =
        this.gridDisplaySettings.filterRowsBy.sectionIds
      gradebook_settings.filter_columns_by.assignment_group_ids =
        this.gridDisplaySettings.filterColumnsBy.assignmentGroupIds
      gradebook_settings.filter_columns_by.context_module_ids =
        this.gridDisplaySettings.filterColumnsBy.contextModuleIds
      gradebook_settings.filter_columns_by.submission_filters =
        this.gridDisplaySettings.filterColumnsBy.submissionFilters
    }

    if (this.options.enhanced_gradebook_filters) {
      return GradebookApi.saveUserSettings(this.options.context_id, gradebook_settings)
    } else {
      return new Promise((resolve, reject) => {
        $.ajaxJSON(
          this.options.settings_update_url,
          'PUT',
          {
            gradebook_settings,
          },
          resolve,
          reject
        )
      })
    }
  }

  // Grid Sorting Methods
  sortRowsBy = (sortFn: (row1: GradebookStudent, row2: GradebookStudent) => number) => {
    const respectorOfPersonsSort = () => {
      if (Object.keys(this.studentViewStudents).length > 0) {
        return (a: GradebookStudent, b: GradebookStudent) => {
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
    this.gradebookGrid?.invalidate()
  }

  gradeSort = (
    a: Pick<Student, 'id' | 'sortable_name'>,
    b: Pick<Student, 'id' | 'sortable_name'>,
    field: string,
    asc: boolean
  ): number => {
    let result
    const scoreForSorting = (student: GradebookStudent) => {
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
      descending: !asc,
    })
    if (result === 0) {
      result = secondaryAndTertiarySort(a, b, {asc})
    }
    return result
  }

  // when fn is true, those rows get a -1 so they go to the top of the sort
  sortRowsWithFunction = (fn: (row: GradebookStudent) => number | boolean, {asc = true} = {}) => {
    this.sortRowsBy((a: GradebookStudent, b: GradebookStudent) => {
      let rowA = fn(a)
      let rowB = fn(b)
      if (!asc) {
        ;[rowA, rowB] = [rowB, rowA]
      }
      if (rowA > rowB) {
        return -1
      }
      if (rowA < rowB) {
        return 1
      }
      return secondaryAndTertiarySort(a, b, {asc})
    })
  }

  missingSort = (columnId: string) => {
    // @ts-ignore
    this.sortRowsWithFunction((row: Submission) => Boolean(row[columnId].missing))
  }

  lateSort = (columnId: string) => {
    // @ts-ignore
    this.sortRowsWithFunction((row: Submission) => Boolean(row[columnId].late))
  }

  sortByStudentColumn = (settingKey: SortRowsSettingKey, direction: SortDirection) => {
    this.sortRowsBy((a: GradebookStudent, b: GradebookStudent) => {
      let result
      const ascending = direction === 'ascending'
      result = localeSort(a[settingKey], b[settingKey], {
        asc: ascending,
        nullsLast: true,
      })
      if (result === 0) {
        result = idSort(a, b, ascending)
      }
      return result
    })
  }

  sortByCustomColumn = (columnId: string, direction: SortDirection) => {
    this.sortRowsBy((a: GradebookStudent, b: GradebookStudent) => {
      const asc = direction === 'ascending'
      let result = localeSort(a[columnId], b[columnId], {asc})
      if (result === 0) {
        result = secondaryAndTertiarySort(a, b, {asc})
      }
      return result
    })
  }

  sortByAssignmentColumn = (
    columnId: string,
    settingKey: SortRowsSettingKey,
    direction: SortDirection
  ) => {
    switch (settingKey) {
      case 'grade':
        this.sortRowsBy((a: GradebookStudent, b: GradebookStudent) =>
          this.gradeSort(a, b, columnId, direction === 'ascending')
        )
        break
      case 'late':
        this.lateSort(columnId)
        break
      case 'missing':
        this.missingSort(columnId)
        break
      case 'excused':
        this.sortRowsWithFunction((row: GradebookStudent) => row[columnId].excused, {
          asc: direction === 'ascending',
        })
        break
      case 'unposted':
        this.sortRowsWithFunction(
          (row: GradebookStudent) => {
            return isGradedOrExcusedSubmissionUnposted(row[columnId] as Submission)
          },
          {
            asc: direction === 'ascending',
          }
        )
        break
    }
  }

  // when 'unposted' # TODO: in a future milestone, unposted will be added
  sortByAssignmentGroupColumn = (
    columnId: string,
    settingKey: SortRowsSettingKey,
    direction: SortDirection
  ) => {
    if (settingKey === 'grade') {
      return this.sortRowsBy((a: GradebookStudent, b: GradebookStudent) =>
        this.gradeSort(a, b, columnId, direction === 'ascending')
      )
    }
  }

  sortByTotalGradeColumn = (direction: SortDirection) => {
    this.sortRowsBy((a: GradebookStudent, b: GradebookStudent) =>
      this.gradeSort(a, b, 'total_grade', direction === 'ascending')
    )
  }

  sortGridRows = () => {
    const {columnId, settingKey, direction} = this.getSortRowsBySetting()
    const columnType = getColumnTypeForColumnId(columnId)
    switch (columnType) {
      case 'custom_column':
        this.sortByCustomColumn(columnId, direction)
        break
      case 'assignment': // 'grade' | 'late' | 'missing' | 'excused' | 'unposted'
        this.sortByAssignmentColumn(columnId, settingKey, direction)
        break
      case 'assignment_group': // 'grade'
        this.sortByAssignmentGroupColumn(columnId, settingKey, direction)
        break
      case 'total_grade':
        this.sortByTotalGradeColumn(direction)
        break
      default:
        this.sortByStudentColumn(settingKey, direction)
    }
    this.updateColumnHeaders()
  }

  // Grid Update Methods
  updateStudentRow = (student: Student) => {
    const index = this.gridData.rows.findIndex(row => row.id === student.id)
    if (index !== -1) {
      this.gridData.rows[index] = student
      this.gradebookGrid?.invalidateRow(index)
    }
  }

  // Filtered Content Information Methods
  updateFilteredContentInfo = () => {
    let invalidAssignmentGroups: AssignmentGroup[]
    this.filteredContentInfo.totalPointsPossible = reduce(
      this.assignmentGroups,
      (sum: number, assignmentGroup: AssignmentGroup) =>
        sum + getAssignmentGroupPointsPossible(assignmentGroup),
      0
    )
    if (this.weightedGroups()) {
      invalidAssignmentGroups = filter(this.assignmentGroups, function (ag: AssignmentGroup) {
        return getAssignmentGroupPointsPossible(ag) === 0
      })
      return (this.filteredContentInfo.invalidAssignmentGroups = invalidAssignmentGroups)
    } else {
      return (this.filteredContentInfo.invalidAssignmentGroups = [])
    }
  }

  listInvalidAssignmentGroups = () => this.filteredContentInfo.invalidAssignmentGroups

  // This is called from TotalGradeCellFormatter upon scrolling the grid
  listHiddenAssignments = (studentId: string) => {
    if (!(this.contentLoadStates.submissionsLoaded && this.assignmentsLoadedForCurrentView())) {
      return []
    }

    const assignmentsToConsider = this.filteredAssignmentIds.map(
      assignmentId => this.assignments[assignmentId]
    )
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

  getTotalPointsPossible = () => this.filteredContentInfo.totalPointsPossible

  handleColumnHeaderMenuClose = () => this.keyboardNav?.handleMenuOrDialogClose()

  toggleNotesColumn = () => {
    const parentColumnIds = this.gridData.columns.frozen.filter(
      columnId => !/^custom_col_/.test(columnId)
    )
    const visibleCustomColumns = this.gradebookContent.customColumns.filter(
      column => !column.hidden
    )
    const customColumnIds = visibleCustomColumns.map(column => getCustomColumnId(column.id))
    this.gridData.columns.frozen = [...parentColumnIds, ...customColumnIds]
    this.updateGrid()
  }

  showNotesColumn = () => {
    let ref1
    if (this.teacherNotesNotYetLoaded) {
      this.teacherNotesNotYetLoaded = false
      const notesColumn = this.getTeacherNotesColumn()
      if (!notesColumn) throw new Error('error loading notes column')
      this.props.loadDataForCustomColumn(notesColumn.id)
    }
    if ((ref1 = this.getTeacherNotesColumn()) != null) {
      ref1.hidden = false
    }
    return this.toggleNotesColumn()
  }

  hideNotesColumn = () => {
    let ref1
    if ((ref1 = this.getTeacherNotesColumn()) != null) {
      ref1.hidden = true
    }
    this.toggleNotesColumn()
  }

  // SlickGrid Data Access Methods
  listRows = () => this.gridData.rows // currently the source of truth for filtered and sorted rows

  // SlickGrid Update Methods
  updateRowCellsForStudentIds = (studentIds: string[]) => {
    let columnIndex, j, k, len, len1, rowIndex
    if (!this.gradebookGrid?.grid) {
      return
    }
    // Update each row without entirely replacing the DOM elements.
    // This is needed to preserve the editor for the active cell, when present.
    const rowIndices = listRowIndicesForStudentIds(this.listRows(), studentIds)
    const columns = this.gradebookGrid?.grid.getColumns()
    for (j = 0, len = rowIndices.length; j < len; j++) {
      rowIndex = rowIndices[j]
      for (columnIndex = k = 0, len1 = columns.length; k < len1; columnIndex = ++k) {
        this.gradebookGrid?.grid.updateCell(rowIndex, columnIndex)
      }
    }
    return null // skip building an unused array return value
  }

  invalidateRowsForStudentIds = (studentIds: string[]) => {
    const rowIndices: number[] = listRowIndicesForStudentIds(this.listRows(), studentIds)
    if (rowIndices.length > 0) {
      for (const rowIndex of rowIndices) {
        this.gradebookGrid?.invalidateRow(rowIndex)
      }
      if (this.props.isSubmissionDataLoaded) {
        this.gradebookGrid?.render()
      }
    }
  }

  updateTotalGradeColumn = () => {
    this.updateColumnWithId('total_grade')
  }

  updateAllTotalColumns = () => {
    this.updateTotalGradeColumn()
    this.assignmentGroupColumnIds().forEach(columnId => this.updateColumnWithId(columnId))
  }

  updateColumnWithId = (id: string) => {
    let j, len, rowIndex
    if (this.gradebookGrid?.grid == null) {
      return
    }
    const columnIndex = this.gradebookGrid?.grid
      .getColumns()
      .findIndex((column: {id: string}) => column.id === id)
    if (columnIndex === -1) {
      return
    }
    const ref1 = listRowIndicesForStudentIds(
      this.listRows(),
      this.courseContent.students.listStudentIds()
    )
    for (j = 0, len = ref1.length; j < len; j++) {
      rowIndex = ref1[j]
      if (rowIndex != null) {
        this.gradebookGrid?.grid.updateCell(rowIndex, columnIndex)
      }
    }
    return null // skip building an unused array return value
  }

  // Gradebook Bulk UI Update Methods
  updateColumns = () => {
    const hasChanged = this.setVisibleGridColumns()
    if (hasChanged) {
      this.gradebookGrid?.updateColumns()
    }
    this.updateColumnHeaders()
  }

  updateColumnsAndRenderViewOptionsMenu = () => {
    this.updateColumns()
    this.renderViewOptionsMenu()
  }

  updateColumnsAndRenderGradebookSettingsModal = () => {
    this.updateColumns()
    this.renderGradebookSettingsModal()
  }

  // React Header Component Ref Methods
  setHeaderComponentRef = (columnId: string, ref: TotalGradeColumnHeader | null) => {
    this.headerComponentRefs[columnId] = ref
  }

  getHeaderComponentRef = (columnId: string) => this.headerComponentRefs[columnId]

  removeHeaderComponentRef = (columnId: string) => {
    return delete this.headerComponentRefs[columnId]
  }

  // React Grid Component Rendering Methods
  updateColumnHeaders = (columnIds: string[] = []) => {
    this.gradebookGrid?.gridSupport?.columns.updateColumnHeaders(columnIds)
  }

  updateStudentColumnHeaders = () => {
    const columnIds: string[] = this.gridDisplaySettings.showSeparateFirstLastNames
      ? ['student_lastname', 'student_firstname']
      : ['student']
    this.updateColumnHeaders(columnIds)
  }

  // Column Header Helpers
  handleHeaderKeyDown = (e: React.KeyboardEvent, columnId: string) => {
    this.gradebookGrid?.gridSupport?.navigation.handleHeaderKeyDown(e, {
      region: 'header',
      cell: this.gradebookGrid?.grid.getColumnIndex(columnId),
      columnId,
    })
  }

  // Total Grade Column Header
  freezeTotalGradeColumn = () => {
    if (!this.gradebookColumnOrderSettings) throw new Error('gradebookColumnOrderSettings not set')
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
    this.gradebookGrid?.gridSupport?.columns.scrollToStart()
  }

  moveTotalGradeColumnToEnd = () => {
    if (!this.gradebookColumnOrderSettings) throw new Error('gradebookColumnOrderSettings not set')
    this.totalColumnPositionChanged = true
    this.gradebookColumnOrderSettings.freezeTotalGrade = false
    this.gridData.columns.frozen = this.gridData.columns.frozen.filter(function (columnId) {
      return columnId !== 'total_grade'
    })
    this.gridData.columns.scrollable = this.gridData.columns.scrollable.filter(function (columnId) {
      return columnId !== 'total_grade'
    })
    this.gridData.columns.scrollable.push('total_grade')
    if (
      getColumnOrder(this.props.modules, this.gradebookColumnOrderSettings).sortType === 'custom'
    ) {
      this.saveCustomColumnOrder()
    } else {
      this.saveColumnOrder()
    }
    this.updateGrid()
    this.updateColumnHeaders()
    return this.gradebookGrid?.gridSupport?.columns.scrollToEnd()
  }

  totalColumnShouldFocus = () => {
    if (this.totalColumnPositionChanged) {
      this.totalColumnPositionChanged = false
      return true
    } else {
      return false
    }
  }

  // Submission Tray
  assignmentColumns = (): GridColumn[] => {
    if (!this.gradebookGrid?.gridSupport) throw new Error('grid not initialized')
    return this.gradebookGrid?.gridSupport.grid.getColumns().filter((column: {type: string}) => {
      return column.type === 'assignment'
    })
  }

  navigateAssignment = (direction: 'previous' | 'next' = 'next'): GridColumn | undefined => {
    if (!this.gradebookGrid?.gridSupport) throw new Error('grid not initialized')
    let assignment, i, ref1, ref3
    let curAssignment: GridColumn
    const location = this.gradebookGrid.gridSupport.state.getActiveLocation()
    const columns: GridColumn[] = this.gradebookGrid.grid.getColumns()
    const range =
      direction === 'next'
        ? function () {
            const results: number[] = []
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
            const results: number[] = []
            for (
              let j = (ref3 = location.cell - 1);
              ref3 <= 0 ? j < 0 : j > 0;
              ref3 <= 0 ? j++ : j--
            ) {
              results.push(j)
            }
            return results
          }.apply(this)

    for (let j = 0; j < range.length; j++) {
      i = range[j]
      curAssignment = columns[i]
      if (curAssignment.id.match(/^assignment_(?!group)/)) {
        this.gradebookGrid.gridSupport.state.setActiveLocation('body', {
          row: location.row,
          cell: i,
        })
        assignment = curAssignment
        break
      }
    }
    return assignment
  }

  loadTrayStudent = (direction: 'previous' | 'next') => {
    if (!this.gradebookGrid?.gridSupport) throw new Error('grid is not initialized')
    const location = this.gradebookGrid?.gridSupport.state.getActiveLocation()
    const rowDelta = direction === 'next' ? 1 : -1
    const newRowIdx = location.row + rowDelta
    const student = this.listRows()[newRowIdx]
    if (!student) {
      return
    }
    this.gradebookGrid.gridSupport.state.setActiveLocation('body', {
      row: newRowIdx,
      cell: location.cell,
    })
    this.setSubmissionTrayState(true, student.id)
    return this.updateRowAndRenderSubmissionTray(student.id)
  }

  loadTrayAssignment = (direction: 'previous' | 'next') => {
    const studentId = this.getSubmissionTrayState().studentId
    if (studentId === null) {
      return
    }
    const assignment = this.navigateAssignment(direction)
    if (!assignment) {
      return
    }
    this.setSubmissionTrayState(true, studentId, assignment.assignmentId)
    return this.updateRowAndRenderSubmissionTray(studentId)
  }

  getSubmissionTrayProps = (student: null | Student = null): SubmissionTrayProps => {
    if (!this.gradebookGrid?.gridSupport) throw new Error('grid is not initialized')
    const {open, studentId, assignmentId, editedCommentId} = this.getSubmissionTrayState()
    if (!studentId) {
      throw new Error('studentId missing')
    }
    if (!student) {
      student = this.student(studentId)
    }
    if (!student) {
      throw new Error('student missing')
    }
    // get the student's submission, or use a fake submission object in case the
    // submission has not yet loaded
    const fakeSubmission = {
      assignment_id: assignmentId,
      late: false,
      missing: false,
      excused: false,
      late_policy_status: null,
      seconds_late: 0,
    }
    // TODO: remove cast
    const submission = this.getSubmission(studentId, assignmentId) || (fakeSubmission as Submission)
    if (!assignmentId) {
      throw new Error('assignmentId missing')
    }
    const assignment = this.getAssignment(assignmentId)
    const activeLocation = this.gradebookGrid.gridSupport.state.getActiveLocation()
    const cell = activeLocation.cell
    const columns = this.gradebookGrid?.gridSupport.grid.getColumns()
    const currentColumn = columns[cell]
    const assignmentColumns = this.assignmentColumns()
    const currentAssignmentIdx = assignmentColumns.indexOf(currentColumn)
    const isFirstAssignment = currentAssignmentIdx === 0
    const isLastAssignment = currentAssignmentIdx === assignmentColumns.length - 1
    const isFirstStudent = activeLocation.row === 0
    const isLastStudent = activeLocation.row === this.listRows().length - 1
    const submissionState = this.submissionStateMap.getSubmissionState({
      user_id: studentId,
      assignment_id: assignmentId,
    })
    const isGroupWeightZero =
      this.assignmentGroups[assignment.assignment_group_id].group_weight === 0
    return {
      assignment: camelizeProperties(assignment),
      colors: this.state.gridColors,
      courseId: this.options.context_id,
      currentUserId: this.props.currentUserId,
      enterGradesAs: this.getEnterGradesAsSetting(assignmentId),
      gradingDisabled: Boolean(
        !!(submissionState != null ? submissionState.locked : undefined) || student.isConcluded
      ),
      gradingScheme: this.getAssignmentGradingScheme(assignmentId)?.data || null,
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
      latePolicy: this.courseContent.latePolicy,
      locale: this.props.locale,
      onAnonymousSpeedGraderClick: this.showAnonymousSpeedGraderAlertForURL,
      onClose: () => this.gradebookGrid?.gridSupport?.helper.focus(),
      onGradeSubmission: this.gradeSubmission,
      onRequestClose: this.closeSubmissionTray,
      pendingGradeInfo: this.getPendingGradeInfo({
        assignmentId,
        userId: studentId,
      }),
      requireStudentGroupForSpeedGrader: this.requireStudentGroupForSpeedGrader(assignment),
      selectNextAssignment: () => this.loadTrayAssignment('next'),
      selectPreviousAssignment: () => this.loadTrayAssignment('previous'),
      selectNextStudent: () => this.loadTrayStudent('next'),
      selectPreviousStudent: () => this.loadTrayStudent('previous'),
      showSimilarityScore: this.options.show_similarity_score,
      speedGraderEnabled: this.options.speed_grader_enabled,
      student: {
        id: student.id,
        name: htmlDecode(student.name),
        avatarUrl: htmlDecode(student.avatar_url),
        gradesUrl: `${student.enrollments[0].grades.html_url}#tab-assignments`,
        isConcluded: Boolean(student.isConcluded),
      },
      submission: camelizeProperties(submission),
      submissionUpdating: this.submissionIsUpdating({
        assignmentId,
        userId: studentId,
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
      editedCommentId,
      proxySubmissionsAllowed: ENV.GRADEBOOK_OPTIONS.proxy_submissions_allowed,
      reloadSubmission: proxyDetails => this.reloadSubmission(submission, student, proxyDetails),
      customGradeStatuses: this.options.custom_grade_statuses?.filter(
        status => status.applies_to_submissions
      ),
      customGradeStatusesEnabled: this.options.custom_grade_statuses_enabled,
    }
  }

  reloadSubmission = (
    submission: Submission,
    student: Student | null,
    proxyDetails: ProxyDetails
  ) => {
    Object.assign(submission, proxyDetails)
    this.updateSubmissionsFromExternal([submission])
    if (this.getSubmissionTrayState().open) {
      this.renderSubmissionTray(student)
    }
  }

  renderSubmissionTray = (student: Student | null = null) => {
    const {open, studentId, assignmentId} = this.getSubmissionTrayState()
    if (!assignmentId) throw new Error('assignmentId missing')
    if (!studentId) throw new Error('studentId missing')
    const mountPoint = document.getElementById('StudentTray__Container')
    const props = this.getSubmissionTrayProps(student)
    if (!this.getSubmissionCommentsLoaded() && open) {
      this.loadSubmissionComments(assignmentId, studentId)
    }
    AsyncComponents.renderGradeDetailTray(props, mountPoint)
  }

  loadSubmissionComments = (assignmentId: string, studentId: string) => {
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

  updateRowAndRenderSubmissionTray = (studentId: string) => {
    this.unloadSubmissionComments()
    this.updateRowCellsForStudentIds([studentId])
    return this.renderSubmissionTray(this.student(studentId))
  }

  toggleSubmissionTrayOpen = (studentId: string, assignmentId: string) => {
    this.setSubmissionTrayState(!this.getSubmissionTrayState().open, studentId, assignmentId)
    return this.updateRowAndRenderSubmissionTray(studentId)
  }

  openSubmissionTray = (studentId: string, assignmentId: string) => {
    this.setSubmissionTrayState(true, studentId, assignmentId)
    this.updateRowAndRenderSubmissionTray(studentId)
  }

  closeSubmissionTray = () => {
    this.setSubmissionTrayState(false)
    const rowIndex = this.gradebookGrid?.grid.getActiveCell().row
    const studentId = this.gridData.rows[rowIndex].id
    this.updateRowAndRenderSubmissionTray(studentId)
    return this.gradebookGrid?.gridSupport?.helper.beginEdit()
  }

  getSubmissionTrayState = () => this.gridDisplaySettings.submissionTray

  setSubmissionTrayState = (
    open: boolean,
    studentId: string | null = null,
    assignmentId: string | null = null
  ) => {
    this.gridDisplaySettings.submissionTray.open = open
    if (studentId) {
      this.gridDisplaySettings.submissionTray.studentId = studentId
    }
    if (assignmentId) {
      this.gridDisplaySettings.submissionTray.assignmentId = assignmentId
    }
    if (open) {
      return this.gradebookGrid?.gridSupport?.helper.commitCurrentEdit()
    }
  }

  setCommentsUpdating = (status: boolean) => {
    this.gridDisplaySettings.submissionTray.commentsUpdating = !!status
  }

  getCommentsUpdating = () => this.gridDisplaySettings.submissionTray.commentsUpdating

  setSubmissionComments = (comments: SerializedComment[]) => {
    this.gridDisplaySettings.submissionTray.comments = comments
  }

  updateSubmissionComments = (comments: SerializedComment[]) => {
    this.setSubmissionComments(comments)
    this.setEditedCommentId(null)
    this.setCommentsUpdating(false)
    this.renderSubmissionTray()
  }

  unloadSubmissionComments = () => {
    this.setSubmissionComments([])
    return this.setSubmissionCommentsLoaded(false)
  }

  apiCreateSubmissionComment = (comment: string) => {
    const {assignmentId, studentId} = this.getSubmissionTrayState()
    if (!assignmentId) throw new Error('assignmentId missing')
    const assignment = this.getAssignment(assignmentId)
    const groupComment = assignmentHelper.gradeByGroup(assignment) ? 1 : 0
    const commentData: SubmissionCommentData = {
      group_comment: groupComment,
      text_comment: comment,
    }
    const {attempt} = this.getSubmission(studentId, assignmentId) || {}
    if (attempt) {
      commentData.attempt = attempt
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

  apiUpdateSubmissionComment = (updatedComment: string, commentId: string) => {
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

  apiDeleteSubmissionComment = (commentId: string) => {
    return SubmissionCommentApi.deleteSubmissionComment(commentId)
      .then(() => this.removeSubmissionComment(commentId))
      .then(FlashAlert.showFlashSuccess(I18n.t('Successfully deleted the comment')))
      .catch(FlashAlert.showFlashError(I18n.t('There was a problem deleting the comment')))
  }

  editSubmissionComment = (commentId: string | null) => {
    this.setEditedCommentId(commentId)
    this.renderSubmissionTray()
  }

  setEditedCommentId = (id: string | null) => {
    return (this.gridDisplaySettings.submissionTray.editedCommentId = id)
  }

  getSubmissionComments = () => this.gridDisplaySettings.submissionTray.comments

  removeSubmissionComment = (commentId: string) => {
    const comments = reject(this.getSubmissionComments(), (c: SerializedComment) => {
      return c.id === commentId
    })
    return this.updateSubmissionComments(comments)
  }

  setSubmissionCommentsLoaded = (loaded: boolean) => {
    this.gridDisplaySettings.submissionTray.commentsLoaded = loaded
  }

  getSubmissionCommentsLoaded = () => this.gridDisplaySettings.submissionTray.commentsLoaded

  initShowUnpublishedAssignments = (showUnpublishedAssignments = 'true') => {
    this.gridDisplaySettings.showUnpublishedAssignments = showUnpublishedAssignments === 'true'
  }

  toggleUnpublishedAssignments = () => {
    const toggleableAction = () => {
      this.gridDisplaySettings.showUnpublishedAssignments =
        !this.gridDisplaySettings.showUnpublishedAssignments
      this.updateColumnsAndRenderViewOptionsMenu()
    }
    toggleableAction()
    // on success, do nothing since the render happened earlier
    return this.saveSettings({
      showUnpublishedAssignments: this.gridDisplaySettings.showUnpublishedAssignments,
    }).catch(toggleableAction)
  }

  // Gradebook Application State Methods
  initHideAssignmentGroupTotals = (hideAssignmentGroupTotals = false) => {
    this.gridDisplaySettings.hideAssignmentGroupTotals = hideAssignmentGroupTotals
  }

  toggleHideAssignmentGroupTotals = () => {
    const toggleableAction = () => {
      this.gridDisplaySettings.hideAssignmentGroupTotals =
        !this.gridDisplaySettings.hideAssignmentGroupTotals
      this.updateColumnsAndRenderViewOptionsMenu()
    }
    toggleableAction()
    // on success, do nothing since the render happened earlier
    return this.saveSettings({
      hideAssignmentGroupTotals: this.gridDisplaySettings.hideAssignmentGroupTotals,
    }).catch(toggleableAction)
    // this pattern keeps the ui snappier rather than waiting for ajax call to complete
  }

  initHideTotal = (hideTotal = false) => {
    this.gridDisplaySettings.hideTotal = hideTotal
  }

  toggleHideTotal = () => {
    const toggleableAction = () => {
      this.gridDisplaySettings.hideTotal = !this.gridDisplaySettings.hideTotal
      this.updateColumnsAndRenderViewOptionsMenu()
    }
    toggleableAction()
    // on success, do nothing since the render happened earlier
    return this.saveSettings({
      hideTotal: this.gridDisplaySettings.hideTotal,
    }).catch(toggleableAction)
    // this pattern keeps the ui snappier rather than waiting for ajax call to complete
  }

  initShowSeparateFirstLastNames = (showSeparateFirstLastNames = false) => {
    this.gridDisplaySettings.showSeparateFirstLastNames = showSeparateFirstLastNames
  }

  toggleShowSeparateFirstLastNames = () => {
    const toggleableAction = () => {
      this.gridDisplaySettings.showSeparateFirstLastNames =
        !this.gridDisplaySettings.showSeparateFirstLastNames
      this.updateColumnsAndRenderViewOptionsMenu()
      this.renderActionMenu()
    }
    toggleableAction()
    // on success, do nothing since the render happened earlier
    return this.saveSettings({
      showSeparateFirstLastNames: this.gridDisplaySettings.showSeparateFirstLastNames,
    }).catch(toggleableAction)
    // this pattern keeps the ui snappier rather than waiting for ajax call to complete
  }

  toggleViewUngradedAsZero = () => {
    const toggleableAction = () => {
      this.gridDisplaySettings.viewUngradedAsZero = !this.gridDisplaySettings.viewUngradedAsZero
      this.updateColumnsAndRenderViewOptionsMenu()

      this.courseContent.students.listStudents().forEach(student => {
        this.calculateStudentGrade(student, true)
      })
      this.updateAllTotalColumns()
    }
    toggleableAction()
    // on success, do nothing since the render happened earlier
    return this.saveSettings({
      viewUngradedAsZero: this.gridDisplaySettings.viewUngradedAsZero,
    }).catch(toggleableAction)
  }

  // Grading Period Assignment Data & Lifecycle Methods
  assignmentsLoadedForCurrentView = () => {
    const gradingPeriodId = this.gradingPeriodId
    const loadStates = this.contentLoadStates.assignmentsLoaded
    if (loadStates.all || gradingPeriodId === '0') {
      return loadStates.all
    }

    return loadStates.gradingPeriod[gradingPeriodId]
  }

  setAssignmentsLoaded = (gradingPeriodIds?: string[]) => {
    const {assignmentsLoaded} = this.contentLoadStates
    if (!gradingPeriodIds) {
      assignmentsLoaded.all = true
      Object.keys(assignmentsLoaded.gradingPeriod).forEach((periodId: string) => {
        assignmentsLoaded.gradingPeriod[periodId] = true
      })
      return
    }

    gradingPeriodIds.forEach(id => (assignmentsLoaded.gradingPeriod[id] = true))
    if (Object.values(assignmentsLoaded.gradingPeriod).every(loaded => loaded)) {
      assignmentsLoaded.all = true
    }
  }

  setAssignmentGroupsLoaded = (loaded: boolean) => {
    this.contentLoadStates.assignmentGroupsLoaded = loaded
  }

  setGradingPeriodAssignmentsLoaded = (loaded: boolean) => {
    this.contentLoadStates.gradingPeriodAssignmentsLoaded = loaded
  }

  setStudentIdsLoaded = (loaded: boolean) => {
    this.contentLoadStates.studentIdsLoaded = loaded
  }

  setStudentsLoaded = (loaded: boolean) => {
    this.contentLoadStates.studentsLoaded = loaded
  }

  setSubmissionsLoaded = (loaded: boolean) => {
    this.contentLoadStates.submissionsLoaded = loaded
  }

  isGradeEditable = (studentId: string, assignmentId: string) => {
    if (!this.isStudentGradeable(studentId)) {
      return false
    }
    const submissionState = this.submissionStateMap.getSubmissionState({
      assignment_id: assignmentId,
      user_id: studentId,
    })
    return submissionState != null && !submissionState.locked
  }

  isGradeVisible = (studentId: string, assignmentId: string) => {
    const submissionState = this.submissionStateMap.getSubmissionState({
      assignment_id: assignmentId,
      user_id: studentId,
    })
    return submissionState != null && !submissionState.hideGrade
  }

  isStudentGradeable = (studentId: string) => {
    const student = this.student(studentId)
    return !(!student || student.isConcluded)
  }

  studentCanReceiveGradeOverride = (studentId: string) => {
    return this.isStudentGradeable(studentId) && this.studentHasGradedSubmission(studentId)
  }

  studentHasGradedSubmission = (studentId: string) => {
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

  addPendingGradeInfo = (
    submission: {
      assignmentId: string
      userId: string
      excuse?: boolean | undefined
      late_policy_status?: string | undefined
      posted_grade?: string | number | null | undefined
    },
    gradeInfo: {excused: boolean; grade: string | null; score: number | null; valid: boolean}
  ) => {
    if (!this.actionStates) throw new Error('actionStates not initialized')
    const {userId, assignmentId} = submission
    const pendingGradeInfo: PendingGradeInfo = {assignmentId, userId, ...gradeInfo}
    this.removePendingGradeInfo(submission)
    this.actionStates.pendingGradeInfo.push(pendingGradeInfo)
  }

  removePendingGradeInfo = (submission: {
    assignmentId: string
    userId: string
    excuse?: boolean | undefined
    late_policy_status?: string | undefined
    posted_grade?: string | number | null | undefined
  }) => {
    if (!this.actionStates) throw new Error('actionStates missing')
    this.actionStates.pendingGradeInfo = reject(
      this.actionStates.pendingGradeInfo,
      function (info: PendingGradeInfo) {
        return info.userId === submission.userId && info.assignmentId === submission.assignmentId
      }
    )
    return this.actionStates.pendingGradeInfo
  }

  getPendingGradeInfo = ({
    assignmentId,
    userId,
  }: {
    assignmentId: string
    userId: string
  }): PendingGradeInfo | null => {
    if (!this.actionStates) throw new Error('actionStates missing')
    return (
      this.actionStates.pendingGradeInfo.find(
        info => info.userId === userId && info.assignmentId === assignmentId
      ) || null
    )
  }

  submissionIsUpdating = (submission: {assignmentId: string; userId: string}) => {
    const ref1 = this.getPendingGradeInfo(submission)
    return Boolean(ref1 != null ? ref1.valid : undefined)
  }

  setTeacherNotesColumnUpdating = (updating: boolean) => {
    return (this.contentLoadStates.teacherNotesColumnUpdating = updating)
  }

  // Grid Display Settings Access Methods
  getFilterColumnsBySetting = <K extends keyof FilterColumnsOptions>(
    filterKey: K
  ): FilterColumnsOptions[K] => {
    return this.gridDisplaySettings?.filterColumnsBy[filterKey]
  }

  // Grid Display Settings Access Methods
  // Kept only for tests
  // TODO: Remove when moving tests to Jest
  setFilterColumnsBySetting = <K extends keyof FilterColumnsOptions>(
    filterKey: K,
    value: FilterColumnsOptions[K]
  ) => {
    this.gridDisplaySettings.filterColumnsBy[filterKey] = value
    this.updateFilterAssignmentIds()
  }

  getFilterRowsBySetting = <K extends keyof FilterRowsBy>(filterKey: K): FilterRowsBy[K] => {
    return this.gridDisplaySettings.filterRowsBy[filterKey]
  }

  setFilterRowsBySetting = <K extends keyof FilterRowsBy>(filterKey: K, value: FilterRowsBy[K]) => {
    this.gridDisplaySettings.filterRowsBy[filterKey] = value
  }

  isFilteringColumnsByAssignmentGroup = () => this.getAssignmentGroupToShow() !== '0'

  getModuleToShow = (): string => {
    const moduleId = this.getFilterColumnsBySetting('contextModuleId')
    if (
      moduleId == null ||
      !this.courseContent.contextModules.some(module => module.id === moduleId)
    ) {
      return '0'
    }
    return moduleId
  }

  getAssignmentGroupToShow = (): string => {
    const groupId = this.getFilterColumnsBySetting('assignmentGroupId') || '0'
    if (map(this.assignmentGroups, 'id').indexOf(groupId) >= 0) {
      return groupId
    } else {
      return '0'
    }
  }

  isFilteringColumnsByGradingPeriod = () => this.gradingPeriodId !== '0'

  isFilteringRowsBySearchTerm = () => this.searchFilteredStudentIds.length > 0

  setCurrentGradingPeriod = () => {
    if (this.gradingPeriodSet == null) {
      this.gradingPeriodId = '0'
      this.setState({gradingPeriodId: this.gradingPeriodId})
      return
    }

    const periodId =
      this.getFilterColumnsBySetting('gradingPeriodId') || this.options.current_grading_period_id

    if (this.gradingPeriodSet.gradingPeriods.some(period => period.id === periodId)) {
      this.gradingPeriodId = periodId
    } else {
      this.gradingPeriodId = '0'
    }
    this.setState({gradingPeriodId: this.gradingPeriodId})
  }

  getCurrentGradingPeriod = (): string => {
    if (this.gradingPeriodSet == null) {
      return '0'
    }

    const periodId =
      this.getFilterColumnsBySetting('gradingPeriodId') || this.options.current_grading_period_id

    return this.gradingPeriodSet.gradingPeriods.some(period => period.id === periodId)
      ? periodId
      : '0'
  }

  getGradingPeriod = (gradingPeriodId: string) => {
    return (this.gradingPeriodSet?.gradingPeriods || []).find(
      gradingPeriod => gradingPeriod.id === gradingPeriodId
    )
  }

  setSelectedPrimaryInfo = (primaryInfo: 'last_first' | 'first_last', skipRedraw: boolean) => {
    this.gridDisplaySettings.selectedPrimaryInfo = primaryInfo
    this.saveSettings()
    if (!skipRedraw) {
      this.buildRows()
      this.updateStudentColumnHeaders()
    }
  }

  toggleDefaultSort = (columnId: string) => {
    let direction: SortDirection
    const sortSettings = this.getSortRowsBySetting()
    const columnType = getColumnTypeForColumnId(columnId)
    const settingKey = getDefaultSettingKeyForColumnType(columnType)
    direction = 'ascending'
    if (
      sortSettings.columnId === columnId &&
      sortSettings.settingKey === settingKey &&
      sortSettings.direction === 'ascending'
    ) {
      direction = 'descending'
    }
    this.setSortRowsBySetting(columnId, settingKey, direction)
  }

  getSelectedPrimaryInfo = () => this.gridDisplaySettings.selectedPrimaryInfo

  setSelectedSecondaryInfo = (secondaryInfo: string, skipRedraw: boolean) => {
    this.gridDisplaySettings.selectedSecondaryInfo = secondaryInfo
    this.saveSettings()
    if (!skipRedraw) {
      this.buildRows()
      this.updateStudentColumnHeaders()
    }
  }

  getSelectedSecondaryInfo = () => this.gridDisplaySettings.selectedSecondaryInfo

  setSortRowsBySetting = (
    columnId: string,
    settingKey: SortRowsSettingKey,
    direction: SortDirection
  ) => {
    this.gridDisplaySettings.sortRowsBy.columnId = columnId
    this.gridDisplaySettings.sortRowsBy.settingKey = settingKey
    this.gridDisplaySettings.sortRowsBy.direction = direction
    this.saveSettings()
    this.sortGridRows()
  }

  getSortRowsBySetting = () => this.gridDisplaySettings.sortRowsBy

  updateGridColors = (colors: StatusColors, successFn: () => void, errorFn: () => void) => {
    const setAndRenderColors = () => {
      this.gridDisplaySettings.colors = colors
      this.setState({gridColors: statusColors(this.gridDisplaySettings.colors)})
      return successFn()
    }
    return this.saveSettings({colors}).then(setAndRenderColors).catch(errorFn)
  }

  listAvailableViewOptionsFilters = () => {
    const filters: (
      | 'assignmentGroups'
      | 'gradingPeriods'
      | 'modules'
      | 'sections'
      | 'studentGroups'
    )[] = []
    if (Object.keys(this.assignmentGroups || {}).length > 1) {
      filters.push('assignmentGroups')
    }
    if (this.gradingPeriodSet != null) {
      filters.push('gradingPeriods')
    }
    if (this.courseContent.contextModules.length > 0) {
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

  setSelectedViewOptionsFilters = (filters: string[]) => {
    this.gridDisplaySettings.selectedViewOptionsFilters = filters
  }

  listSelectedViewOptionsFilters = () => this.gridDisplaySettings.selectedViewOptionsFilters

  toggleEnrollmentFilter = (enrollmentFilter: 'inactive' | 'concluded', skipApply = false) => {
    if (enrollmentFilter === 'inactive') {
      this.getEnrollmentFilters().inactive = !this.getEnrollmentFilters().inactive
    } else if (enrollmentFilter === 'concluded') {
      this.getEnrollmentFilters().concluded = !this.getEnrollmentFilters().concluded
    }
    if (!skipApply) {
      this.applyEnrollmentFilter()
    }
  }

  updateStudentHeadersAndReloadData = () => {
    this.updateStudentColumnHeaders()
    this.props.reloadStudentData()
    this.props.fetchGradingPeriodAssignments()
  }

  applyEnrollmentFilter = () => {
    const showInactiveEnrollments = this.getEnrollmentFilters().inactive
    const showConcludedEnrollments = this.getEnrollmentFilters().concluded
    return this.saveSettings({showInactiveEnrollments, showConcludedEnrollments}).then(
      this.updateStudentHeadersAndReloadData
    )
  }

  getEnrollmentFilters = () => this.gridDisplaySettings.showEnrollments

  getSelectedEnrollmentFilters = () => {
    const filters = this.getEnrollmentFilters()
    const selectedFilters: ('concluded' | 'inactive')[] = []
    if (filters.concluded) {
      selectedFilters.push('concluded')
    }
    if (filters.inactive) {
      selectedFilters.push('inactive')
    }
    return selectedFilters
  }

  setEnterGradesAsSetting = (assignmentId: string, setting: GradeEntryMode) => {
    return (this.gridDisplaySettings.enterGradesAs[assignmentId] = setting)
  }

  getEnterGradesAsSetting = (assignmentId: string) => {
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

  updateEnterGradesAsSetting = (assignmentId: string, value: GradeEntryMode) => {
    this.setEnterGradesAsSetting(assignmentId, value)
    return this.saveSettings({}).then(() => {
      if (!this.gradebookGrid?.gridSupport) {
        throw new Error('grid not initialized')
      }
      this.gradebookGrid.gridSupport.columns.updateColumnHeaders([
        getAssignmentColumnId(assignmentId),
      ])
      return this.gradebookGrid.invalidate()
    })
  }

  postAssignmentGradesTrayOpenChanged = ({
    assignmentId,
    isOpen,
  }: {
    assignmentId: string
    isOpen: boolean
  }) => {
    const columnId = getAssignmentColumnId(assignmentId)
    const definition = this.gridData.columns.definitions[columnId]
    if (!(definition && definition.type === 'assignment')) {
      return
    }
    definition.postAssignmentGradesTrayOpenForAssignmentId = isOpen
    this.updateGrid()
  }

  // # Course Settings Access Methods
  getCourseGradingScheme = (): DeprecatedGradingScheme | null =>
    this.courseContent.courseGradingScheme

  getDefaultGradingScheme = () => this.courseContent.defaultGradingScheme

  getGradingScheme = (gradingSchemeId: string | null): DeprecatedGradingScheme | undefined =>
    this.courseContent.gradingSchemes.find(scheme => scheme.id === gradingSchemeId)

  getAssignmentGradingScheme = (assignmentId: string): DeprecatedGradingScheme | null => {
    const assignment = this.getAssignment(assignmentId)
    return this.getGradingScheme(assignment.grading_standard_id) || this.getDefaultGradingScheme()
  }

  // Gradebook Content Access Methods
  getSections = () => Object.values(this.sections)

  setSections = (sections: Section[]) => {
    this.sections = keyBy(sections, 'id')
    this.sections_enabled = sections.length > 1
  }

  setStudentGroups = (studentGroupCategories: StudentGroupCategory[]) => {
    this.studentGroupCategoriesById = keyBy(studentGroupCategories, 'id')
    const studentGroupList: StudentGroup[] = flatten(map(studentGroupCategories, 'groups'))

    studentGroupList.forEach(studentGroup => {
      for (const key in studentGroup) {
        if (Object.prototype.hasOwnProperty.call(studentGroup, key)) {
          studentGroup[key as keyof StudentGroup] = htmlEscape(studentGroup[key])
        }
      }
    })

    this.studentGroups = keyBy(studentGroupList, 'id')
    this.studentGroupsEnabled = studentGroupList.length > 0
  }

  setAssignments = (assignmentMap: AssignmentMap) => {
    this.assignments = assignmentMap
  }

  setAssignmentGroups = (assignmentGroupMap: AssignmentGroupMap) => {
    this.assignmentGroups = assignmentGroupMap
  }

  getAssignment = (assignmentId: string): Assignment => this.assignments[assignmentId]

  getAssignmentGroup = (assignmentGroupId: string) => this.assignmentGroups[assignmentGroupId]

  getCustomColumn = (customColumnId: string) => {
    return this.gradebookContent.customColumns.find(column => column.id === customColumnId)
  }

  getTeacherNotesColumn = () => {
    return this.gradebookContent.customColumns.find(column => column.teacher_notes)
  }

  isTeacherNotesColumnShown = () => {
    const column = this.getTeacherNotesColumn()
    return column != null && !column.hidden
  }

  // Context Module Data & Lifecycle Methods
  updateContextModules = (contextModules: Module[]) => {
    this.setContextModules(contextModules)
    this.setState({modules: contextModules})
    this.renderViewOptionsMenu()
    this.renderFilters()
    this._updateEssentialDataLoaded()
  }

  setContextModules = (contextModules: Module[]) => {
    this.courseContent.contextModules = contextModules
    this.courseContent.modulesById = {}
    if (contextModules != null ? contextModules.length : undefined) {
      for (const contextModule of contextModules) {
        this.courseContent.modulesById[contextModule.id] = contextModule
      }
    }
    return contextModules
  }

  onLatePolicyUpdate = (latePolicy: LatePolicyCamelized) => {
    this.setLatePolicy(latePolicy)
    this.applyLatePolicy()
  }

  setLatePolicy = (latePolicy: LatePolicyCamelized) => {
    this.courseContent.latePolicy = latePolicy
  }

  applyLatePolicy = () => {
    let ref1
    const latePolicy = (ref1 = this.courseContent) != null ? ref1.latePolicy : undefined
    const gradingStandard = this.options.grading_standard || this.options.default_grading_standard
    const studentsToInvalidate: {
      [userId: string]: boolean
    } = {}
    forEachSubmission(this.students, submission => {
      let ref2
      const assignment = this.assignments[submission.assignment_id]
      const student = this.student(submission.user_id)
      if (!assignment || student?.isConcluded) {
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
        studentsToInvalidate[submission.user_id] = true
      }
    })
    const studentIds = [...new Set(Object.keys(studentsToInvalidate))]
    studentIds.forEach(studentId => {
      return this.calculateStudentGrade(this.students[studentId])
    })
    this.invalidateRowsForStudentIds(studentIds)
  }

  getContextModule = (contextModuleId?: string): Module | undefined =>
    this.courseContent.modulesById[contextModuleId]

  // Assignment UI Action Methods
  getDownloadSubmissionsAction = (assignmentId: string) => {
    const assignment = this.getAssignment(assignmentId)
    const manager = new DownloadSubmissionsDialogManager(
      assignment,
      this.options.download_assignment_submissions_url,
      this.handleSubmissionsDownloading
    )
    return {
      hidden: !manager.isDialogEnabled(),
      onSelect: manager.showDialog,
    }
  }

  getReuploadSubmissionsAction = (assignmentId: string) => {
    const assignment = this.getAssignment(assignmentId)
    const manager = new ReuploadSubmissionsDialogManager(
      assignment,
      this.options.re_upload_submissions_url,
      this.options.user_asset_string,
      this.downloadedSubmissionsMap
    )
    return {
      hidden: !manager.isDialogEnabled(),
      onSelect: manager.showDialog,
    }
  }

  getSetDefaultGradeAction = (assignmentId: string) => {
    const assignment = this.getAssignment(assignmentId)
    const manager = new SetDefaultGradeDialogManager(
      assignment,
      this.visibleStudentsThatCanSeeAssignment,
      this.options.context_id,
      this.options.assignment_missing_shortcut,
      this.getFilterRowsBySetting('sectionId'),
      isAdmin(),
      this.contentLoadStates.submissionsLoaded
    )
    return {
      disabled: !manager.isDialogEnabled(),
      onSelect: manager.showDialog,
    }
  }

  getCurveGradesAction = (assignmentId: string) => {
    const assignment = this.getAssignment(assignmentId)
    return CurveGradesDialogManager.createCurveGradesAction(
      assignment,
      this.studentsThatCanSeeAssignment(assignmentId),
      {
        isAdmin: isAdmin(),
        contextUrl: this.options.context_url,
        submissionsLoaded: this.contentLoadStates.submissionsLoaded,
      }
    )
  }

  // Gradebook Content Api Methods
  createTeacherNotes = () => {
    this.setTeacherNotesColumnUpdating(true)
    this.renderViewOptionsMenu()
    return GradebookApi.createTeacherNotesColumn(this.options.context_id)
      .then(response => {
        this.gradebookContent.customColumns.push(response.data)
        const teacherNotesColumn = buildCustomColumn(response.data)
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

  setTeacherNotesHidden = (hidden: boolean) => {
    this.setTeacherNotesColumnUpdating(true)
    this.renderViewOptionsMenu()
    const teacherNotes = this.getTeacherNotesColumn()
    if (!teacherNotes) throw new Error('teacherNotes missing')
    return GradebookApi.updateTeacherNotesColumn(this.options.context_id, teacherNotes.id, {
      hidden,
    })
      .then(() => {
        if (hidden) {
          this.hideNotesColumn()
        } else {
          this.showNotesColumn()
          this.props.reorderCustomColumns(this.gradebookContent.customColumns.map(c => c.id))
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

  apiUpdateSubmission(
    submission: {
      assignmentId: string
      userId: string
      excuse?: boolean | undefined
      late_policy_status?: string | undefined
      posted_grade?: string | number | null | undefined
    },
    gradeInfo: {excused: boolean; grade: string | null; score: number | null; valid: boolean},
    enterGradesAs?: string
  ) {
    const {userId, assignmentId} = submission
    const student = this.student(userId)
    this.addPendingGradeInfo(submission, gradeInfo)
    if (this.getSubmissionTrayState().open) {
      this.renderSubmissionTray(student)
    }
    return GradebookApi.updateSubmission(
      this.options.context_id,
      assignmentId,
      userId,
      submission,
      enterGradesAs
    )
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
        // eslint-disable-next-line promise/no-return-wrap
        return Promise.reject(response)
      })
  }

  gradeSubmission = (submission: CamelizedSubmission, gradeInfo: GradeResult) => {
    let gradeChangeOptions
    let submissionData: {
      assignmentId: string
      userId: string
      excuse?: boolean
      late_policy_status?: string
      posted_grade?: string | number | null
    }
    if (gradeInfo.valid) {
      gradeChangeOptions = {
        enterGradesAs: this.getEnterGradesAsSetting(submission.assignmentId),
        gradingScheme: this.getAssignmentGradingScheme(submission.assignmentId)?.data,
        pointsPossible: this.getAssignment(submission.assignmentId).points_possible,
      }
      if (GradeInputHelper.hasGradeChanged(submission, gradeInfo, gradeChangeOptions)) {
        submissionData = {
          assignmentId: submission.assignmentId,
          userId: submission.userId,
        }
        if (gradeInfo.excused) {
          submissionData.excuse = true
        } else if (
          ENV.GRADEBOOK_OPTIONS.assignment_missing_shortcut &&
          gradeInfo.late_policy_status === 'missing'
        ) {
          submissionData.late_policy_status = gradeInfo.late_policy_status
        } else if (gradeInfo.enteredAs === null) {
          submissionData.posted_grade = ''
        } else if (['passFail', 'gradingScheme'].includes(gradeInfo.enteredAs)) {
          submissionData.posted_grade = gradeInfo.grade
        } else {
          submissionData.posted_grade = gradeInfo.score
        }
        return this.apiUpdateSubmission(
          submissionData,
          gradeInfo,
          gradeChangeOptions.enterGradesAs
        ).then(response => {
          const assignment = this.getAssignment(submission.assignmentId)
          const outlierScoreHelper = new OutlierScoreHelper(
            response.data.score,
            assignment.points_possible
          )
          if (outlierScoreHelper.hasWarning()) {
            const message = outlierScoreHelper.warningMessage()
            if (message) {
              return $.flashWarning(message)
            }
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
        type: 'error',
        err: undefined,
      })
      this.addPendingGradeInfo(submission, gradeInfo)
      this.updateRowCellsForStudentIds([submission.userId])
      if (this.getSubmissionTrayState().open) {
        return this.renderSubmissionTray()
      }
    }
  }

  updateSubmissionAndRenderSubmissionTray = (data: CamelizedSubmission) => {
    const {studentId, assignmentId} = this.getSubmissionTrayState()
    const submissionData = {
      ...data,
      assignmentId,
      userId: studentId,
    }
    const submission = this.getSubmission(studentId, assignmentId)
    if (submission == null) {
      throw new Error('submission is not loaded')
    }
    const gradeInfo = {
      excused: submission.excused,
      grade: submission.entered_grade,
      score: submission.entered_score,
      valid: true,
    }
    return this.apiUpdateSubmission(submissionData, gradeInfo)
  }

  renderAnonymousSpeedGraderAlert = (props: {speedGraderUrl: string; onClose: () => void}) => {
    return renderComponent(
      AnonymousSpeedGraderAlert,
      this.props.anonymousSpeedGraderAlertNode,
      props
    )
  }

  showAnonymousSpeedGraderAlertForURL = (speedGraderUrl: string) => {
    const props = {
      speedGraderUrl,
      onClose: this.hideAnonymousSpeedGraderAlert,
    }
    this.anonymousSpeedGraderAlert = this.renderAnonymousSpeedGraderAlert(props)
    this.anonymousSpeedGraderAlert.open()
  }

  hideAnonymousSpeedGraderAlert = () => {
    // React throws an error if we try to unmount while the event is being handled
    return setTimeout(() => {
      const node = this.props.anonymousSpeedGraderAlertNode
      if (node) ReactDOM.unmountComponentAtNode(node)
    }, 0)
  }

  requireStudentGroupForSpeedGrader = (assignment: Assignment) => {
    if (assignmentHelper.gradeByGroup(assignment)) {
      // Assignments that grade by group (not by student) don't require a group selection
      return false
    }
    return (
      this.options.course_settings.filter_speed_grader_by_student_group &&
      this.getStudentGroupToShow() === '0'
    )
  }

  showSimilarityScore = (_assignment?: Assignment) => !!this.options.show_similarity_score

  viewUngradedAsZero = () => {
    return !!(
      this.courseFeatures.allowViewUngradedAsZero && this.gridDisplaySettings.viewUngradedAsZero
    )
  }

  allowApplyScoreToUngraded = () => this.options.allow_apply_score_to_ungraded

  onApplyScoreToUngradedRequested = (assignmentGroup: AssignmentGroup | null) => {
    const mountPoint = this.props.applyScoreToUngradedModalNode
    if (!this.allowApplyScoreToUngraded() || mountPoint == null) {
      return null
    }

    const close = () => {
      ReactDOM.unmountComponentAtNode(mountPoint)
    }

    const props = {
      assignmentGroup,
      onApply: (args: {
        assignmentGroupId?: string
        markAsMissing: boolean
        onlyPastDue: boolean
        value: number | 'excused'
      }) => {
        this.executeApplyScoreToUngraded(args)
        close()
      },
      onClose: close,
      open: true,
    }

    renderComponent(ApplyScoreToUngradedModal, mountPoint, props)
  }

  assignmentGroupColumnIds = () => {
    return Object.keys(this.assignmentGroups).map(id => `assignment_group_${id}`)
  }

  refreshScoreToUngradedColumnHeaders() {
    let columnIds: string[] = []
    if (!this.gridDisplaySettings.hideAssignmentGroupTotals) {
      columnIds = [...this.assignmentGroupColumnIds()]
    }
    if (!this.gridDisplaySettings.hideTotal) {
      columnIds.push('total_grade')
    }
    this.gradebookGrid?.gridSupport?.columns.updateColumnHeaders(columnIds)
  }

  executeApplyScoreToUngraded = (args: {
    assignmentGroupId?: string
    markAsMissing: boolean
    onlyPastDue: boolean
    value: number | 'excused'
  }) => {
    const {value, ...options} = args

    const optionsWithAssignmentsAndStudentIds: {
      assignment_ids: string[]
      excused?: boolean
      mark_as_missing?: boolean
      only_past_due?: boolean
      percent?: number
      student_ids: string[]
    } = {
      ...options,
      assignment_ids: this.getAssignmentOrder(args.assignmentGroupId),
      student_ids: this.getStudentOrder(),
    }

    if (value === 'excused') {
      optionsWithAssignmentsAndStudentIds.excused = true
    } else {
      optionsWithAssignmentsAndStudentIds.percent = value
    }

    this.isRunningScoreToUngraded = true
    this.refreshScoreToUngradedColumnHeaders()

    return Promise.resolve()
      .then(
        FlashAlert.showFlashSuccess(
          I18n.t(
            'Request successfully sent. Note that applying scores may take a while and changes will not appear until you reload the page.'
          )
        )
      )
      .then(() => {
        if (this.scoreToUngradedManager == null) {
          throw new Error('ScoreToUngradedManager is not initialized')
        }
        this.scoreToUngradedManager
          .startProcess(this.options.context_id, optionsWithAssignmentsAndStudentIds)
          .then(
            FlashAlert.showFlashSuccess(I18n.t('Score to ungraded process finished successfully'))
          )
          .finally(() => {
            this.isRunningScoreToUngraded = false
            this.refreshScoreToUngradedColumnHeaders()
          })
          .catch(FlashAlert.showFlashError(I18n.t('Score to ungraded process failed')))
      })
  }

  sendMessageStudentsWho = ({
    recipientsIds,
    subject,
    body,
    mediaFile,
    attachmentIds,
  }: SendMessageArgs) => {
    return MessageStudentsWhoHelper.sendMessageStudentsWho(
      recipientsIds,
      subject,
      body,
      `course_${this.options.context_id}`,
      mediaFile,
      attachmentIds
    )
      .then(FlashAlert.showFlashSuccess(I18n.t('Message sent successfully')))
      .catch(FlashAlert.showFlashError(I18n.t('There was an error sending the message')))
  }

  destroy = () => {
    $(window).unbind('resize.fillWindowWithMe')
    $(document).unbind('gridready')
    this.gradebookGrid?.destroy()
    this.scoreToUngradedManager?.clearMonitor()
    return this.postPolicies?.destroy()
  }

  // "PRIVILEGED" methods
  // The methods here are intended to support specs, but not intended to be a
  // permanent part of the API for this class. The existence of these methods
  // suggests that the behavior they provide does not yet have a more suitable
  // home elsewhere in the code. They are prefixed with '_' to suggest this
  // aspect of their presence here.
  _gridHasRendered = () => this.gridReady.state === 'resolved'

  _updateEssentialDataLoaded = () => {
    if (
      this.contentLoadStates.studentIdsLoaded &&
      !this.props.isModulesLoading &&
      this.props.isCustomColumnsLoaded &&
      this.contentLoadStates.assignmentGroupsLoaded &&
      this.assignmentsLoadedForCurrentView() &&
      (!this.gradingPeriodSet || this.contentLoadStates.gradingPeriodAssignmentsLoaded)
    ) {
      this.setState({isEssentialDataLoaded: true})
    }
  }

  componentDidMount() {
    this.onShow()
  }

  componentDidUpdate(prevProps: GradebookProps, prevState: GradebookState) {
    // Here we keep track of data loading states
    //   and filter changes until we use hooks

    // studentIds
    if (
      prevProps.isStudentIdsLoading !== this.props.isStudentIdsLoading &&
      !this.props.isStudentIdsLoading
    ) {
      this.updateStudentIds(this.props.studentIds)
    }

    // grading period assignments
    if (prevProps.gradingPeriodAssignments !== this.props.gradingPeriodAssignments) {
      this.updateGradingPeriodAssignments(this.props.gradingPeriodAssignments)
    }

    // assignment groups
    if (prevProps.recentlyLoadedAssignmentGroups !== this.props.recentlyLoadedAssignmentGroups) {
      this.updateAssignmentGroups(
        this.props.recentlyLoadedAssignmentGroups.assignmentGroups,
        this.props.recentlyLoadedAssignmentGroups.gradingPeriodIds
      )
    }

    // students
    if (prevProps.recentlyLoadedStudents !== this.props.recentlyLoadedStudents) {
      this.gotChunkOfStudents(this.props.recentlyLoadedStudents)
    }

    // submissions
    if (prevProps.recentlyLoadedSubmissions !== this.props.recentlyLoadedSubmissions) {
      this.gotSubmissionsChunk(this.props.recentlyLoadedSubmissions)
    }

    // students are done loading
    if (prevProps.isStudentDataLoaded !== this.props.isStudentDataLoaded) {
      this.updateStudentsLoaded(this.props.isStudentDataLoaded)
    }

    // updateSubmissionsLoaded
    if (prevProps.isSubmissionDataLoaded !== this.props.isSubmissionDataLoaded) {
      this.updateSubmissionsLoaded(this.props.isSubmissionDataLoaded)
    }

    // final grade overrides
    if (
      prevProps.finalGradeOverrides !== this.props.finalGradeOverrides &&
      this.props.finalGradeOverrides
    ) {
      this.finalGradeOverrides?.setGrades(this.props.finalGradeOverrides)
    }

    // sis overrides
    if (prevProps.sisOverrides !== this.props.sisOverrides) {
      this.addOverridesToPostGradesStore(this.props.sisOverrides)
    }

    // modules
    if (
      prevProps.isModulesLoading !== this.props.isModulesLoading &&
      !this.props.isModulesLoading
    ) {
      this.updateContextModules(this.props.modules)
    }

    // custom columns
    if (
      prevProps.isCustomColumnsLoaded !== this.props.isCustomColumnsLoaded &&
      this.props.isCustomColumnsLoaded
    ) {
      this.gotCustomColumns(this.props.customColumns)
    }

    // custom column data
    if (
      prevProps.recentlyLoadedCustomColumnData !== this.props.recentlyLoadedCustomColumnData &&
      this.props.recentlyLoadedCustomColumnData
    ) {
      this.gotCustomColumnDataChunk(
        this.props.recentlyLoadedCustomColumnData.customColumnId,
        this.props.recentlyLoadedCustomColumnData.columnData
      )
    }

    const didAppliedFilterValuesChange =
      prevProps.appliedFilters.map(c => c.value).join(',') !==
      this.props.appliedFilters.map(c => c.value).join(',')
    if (didAppliedFilterValuesChange) {
      // section
      const prevSectionIds = findFilterValuesOfType('section', prevProps.appliedFilters)
      const sectionIds = findFilterValuesOfType('section', this.props.appliedFilters)
      if (
        this.options.multiselect_gradebook_filters_enabled &&
        !idArraysEqual(prevSectionIds, sectionIds)
      ) {
        this.updateCurrentSections(sectionIds)
      } else if (prevSectionIds[0] !== sectionIds[0]) {
        if (sectionIds.length === 0) {
          this.updateCurrentSection(null)
        } else {
          this.updateCurrentSection(sectionIds[0] || null)
        }
      }

      // modules
      const prevModulesIds = findFilterValuesOfType('module', prevProps.appliedFilters)
      const moduleIds = findFilterValuesOfType('module', this.props.appliedFilters)
      if (
        this.options.multiselect_gradebook_filters_enabled &&
        !idArraysEqual(prevModulesIds, moduleIds)
      ) {
        this.updateCurrentModules(moduleIds)
      } else if (prevModulesIds[0] !== moduleIds[0]) {
        if (moduleIds.length === 0 || !moduleIds[0]) {
          this.updateCurrentModule(null)
        } else {
          this.updateCurrentModule(moduleIds[0])
        }
      }

      // assignment groups
      const prevAssignmentGroupIds = findFilterValuesOfType(
        'assignment-group',
        prevProps.appliedFilters
      )
      const assignmentGroupIds = findFilterValuesOfType(
        'assignment-group',
        this.props.appliedFilters
      )
      if (
        this.options.multiselect_gradebook_filters_enabled &&
        !idArraysEqual(prevAssignmentGroupIds, assignmentGroupIds)
      ) {
        this.updateCurrentAssignmentGroups(assignmentGroupIds)
      } else if (prevAssignmentGroupIds[0] !== assignmentGroupIds[0]) {
        if (assignmentGroupIds.length === 0 || !assignmentGroupIds[0]) {
          this.updateCurrentAssignmentGroup(null)
        } else {
          this.updateCurrentAssignmentGroup(assignmentGroupIds[0])
        }
      }

      // student groups
      const prevStudentGroupIds = findFilterValuesOfType('student-group', prevProps.appliedFilters)
      const studentGroupIds = findFilterValuesOfType('student-group', this.props.appliedFilters)
      if (this.options.multiselect_gradebook_filters_enabled) {
        if (!idArraysEqual(prevStudentGroupIds, studentGroupIds)) {
          this.updateCurrentStudentGroups(studentGroupIds)
        }
      } else if (prevStudentGroupIds[0] !== studentGroupIds[0]) {
        if (studentGroupIds.length === 0 || !studentGroupIds[0]) {
          this.updateCurrentStudentGroup(null)
        } else {
          this.updateCurrentStudentGroup(studentGroupIds[0])
        }
      }

      // grading period
      const prevGradingPeriodId = findFilterValuesOfType(
        'grading-period',
        prevProps.appliedFilters
      )[0]
      const gradingPeriodId = findFilterValuesOfType('grading-period', this.props.appliedFilters)[0]
      if (prevGradingPeriodId !== gradingPeriodId) {
        if (!gradingPeriodId) {
          this.updateCurrentGradingPeriod(null)
        } else {
          this.updateCurrentGradingPeriod(gradingPeriodId)
        }
      }

      // start-date
      const prevStartDate = findFilterValuesOfType('start-date', prevProps.appliedFilters)
      const startDate = findFilterValuesOfType('start-date', this.props.appliedFilters)
      if (prevStartDate[0] !== startDate[0]) {
        if (startDate.length === 0 || !startDate[0]) {
          this.updateCurrentStartDate(null)
        } else {
          this.updateCurrentStartDate(startDate[0])
        }
      }

      // end-date
      const prevEndDate = findFilterValuesOfType('end-date', prevProps.appliedFilters)
      const endDate = findFilterValuesOfType('end-date', this.props.appliedFilters)
      if (prevEndDate[0] !== endDate[0]) {
        if (startDate.length === 0 || !endDate[0]) {
          this.updateCurrentEndDate(null)
        } else {
          this.updateCurrentEndDate(endDate[0])
        }
      }

      // submissions
      const prevSubmissionsFilters = findFilterValuesOfType('submissions', prevProps.appliedFilters)
      const submissionFilters = findFilterValuesOfType('submissions', this.props.appliedFilters)
      if (
        this.options.multiselect_gradebook_filters_enabled &&
        !idArraysEqual(prevSubmissionsFilters, submissionFilters)
      ) {
        this.updateSubmissionsFilters(submissionFilters as SubmissionFilterValue[])
      } else if (prevSubmissionsFilters[0] !== submissionFilters[0]) {
        this.updateSubmissionsFilter(submissionFilters[0] as SubmissionFilterValue)
      }

      this.updateColumns()
      this.updateRows()
    }

    // Until GradebookGrid is rendered reactively, it will need to be rendered
    // once and only once. It depends on all essential data from the initial
    // data load. When all of that data has loaded, this deferred promise will
    // resolve and render the grid. As a promise, it only resolves once.
    if (
      !(prevState.isEssentialDataLoaded && prevState.isGridLoaded) &&
      this.state.isEssentialDataLoaded &&
      this.state.isGridLoaded
    ) {
      this.finishRenderingUI()
    }
  }

  handleGridLoad = (gradebookGrid: GradebookGridType) => {
    this.gradebookGrid = gradebookGrid
    this.bindGridEvents()

    this.setState({isGridLoaded: true})

    // eslint-disable-next-line promise/catch-or-return
    this.gridReady.promise.then(() => {
      // Preload the Grade Detail Tray
      AsyncComponents.loadGradeDetailTray()
      this.renderViewOptionsMenu()
      this.renderGradebookSettingsModal()
    })
  }

  render() {
    const students = this.courseContent.students.listStudents({includePlaceholders: false})
    const assignments = Object.values(this.assignments)

    return (
      <>
        <Portal node={this.props.flashMessageContainer}>
          {this.props.flashAlerts.map(alert => (
            <div key={alert.key} id={alert.key} className="Gradebook__FlashMessage">
              {/* eslint-disable-next-line react/jsx-pascal-case */}
              <FlashAlert.default
                message={alert.message}
                onClose={() => document.getElementById(alert.key)?.remove()}
                timeout={5000}
                variant={alert.variant}
              />
            </div>
          ))}
        </Portal>

        {this.state.isStatusesModalOpen && (
          <StatusesModal
            onClose={() => {
              this.viewOptionsMenu?.focus()
              this.setState({isStatusesModalOpen: false})
            }}
            colors={this.state.gridColors}
            afterUpdateStatusColors={this.updateGridColors}
          />
        )}

        <Portal node={this.props.settingsModalButtonContainer}>
          <IconButton
            renderIcon={IconSettingsSolid}
            ref={this.gradebookSettingsModalButton}
            data-testid="gradebook-settings-button"
            color="secondary"
            onClick={() => this.gradebookSettingsModal?.current?.open()}
            screenReaderLabel={I18n.t('Gradebook Settings')}
          />
        </Portal>
        <Portal node={this.props.gradebookMenuNode}>
          <GradebookMenu
            courseUrl={this.options.context_url}
            enhancedIndividualGradebookEnabled={this.options.individual_gradebook_enhancements}
            learningMasteryEnabled={this.options.outcome_gradebook_enabled}
            variant="DefaultGradebook"
          />
        </Portal>
        <ExportProgressBar
          exportState={this.state.exportState}
          exportManager={this.state.exportManager}
        />
        {(!this.state.isGridLoaded || !this.state.isEssentialDataLoaded) && (
          <div
            style={{
              width: '100%',
              position: 'absolute',
              top: '200px',
              textAlign: 'center',
            }}
          >
            <View as="div">
              <Spinner renderTitle={I18n.t('Loading Gradebook')} margin="large auto 0 auto" />
            </View>
          </div>
        )}
        <ErrorBoundary
          errorComponent={
            <GenericErrorPage imageUrl={errorShipUrl} errorCategory="GradebookGrid" />
          }
        >
          <Suspense fallback={<></>}>
            <GradebookGrid
              gradebook={this}
              gridData={this.gridData}
              gradebookGridNode={this.props.gradebookGridNode}
              gradebookIsEditable={this.options.gradebook_is_editable}
              onLoad={this.handleGridLoad}
            />
          </Suspense>
        </ErrorBoundary>
        <Portal node={this.props.gridColorNode}>
          <GridColor
            colors={this.state.gridColors}
            customStatuses={
              this.options.custom_grade_statuses_enabled ? this.options.custom_grade_statuses : []
            }
          />
        </Portal>

        <div style={{display: 'flex'}}>
          <div
            id="gradebook-student-search"
            style={{
              flex: 1,
              paddingInlineEnd: '12px',
            }}
          >
            <MultiSelectSearchInput
              id="student-names-filter"
              data-testid="students-filter-select"
              disabled={students.length === 0 || !this._gridHasRendered()}
              label={I18n.t('Student Names')}
              customMatcher={this.studentSearchMatcher}
              onChange={this.onFilterToStudents}
              options={students.map(student => ({id: student.id, text: student.displayName}))}
              placeholder={I18n.t('Search Students')}
            />
          </div>
          <div id="gradebook-assignment-search" style={{flex: 1}}>
            <MultiSelectSearchInput
              id="assignments-filter"
              data-testid="assignments-filter-select"
              disabled={assignments.length === 0 || !this._gridHasRendered()}
              label={I18n.t('Assignment Names')}
              customMatcher={assignmentSearchMatcher}
              onChange={this.onFilterToAssignments}
              options={assignments.map((assignment: Assignment) => ({
                id: assignment.id,
                text: assignment.name,
              }))}
              placeholder={I18n.t('Search Assignments')}
            />
          </div>
        </div>
        <div>
          {this.options.enhanced_gradebook_filters &&
            !this.props.isFiltersLoading &&
            this.state.isEssentialDataLoaded && (
              <FilterNav
                gradingPeriods={this.gradingPeriodSet?.gradingPeriods || []}
                modules={this.state.modules}
                assignmentGroups={this.state.assignmentGroups}
                sections={this.state.sections}
                studentGroupCategories={this.options.student_groups}
                customStatuses={
                  this.options.custom_grade_statuses_enabled
                    ? this.options.custom_grade_statuses
                    : []
                }
                multiselectGradebookFiltersEnabled={
                  this.options.multiselect_gradebook_filters_enabled
                }
              />
            )}
        </div>
        {this.state.isGridLoaded &&
          !this.props.isSubmissionDataLoaded &&
          Object.keys(this.props.assignmentMap).length * this.props.totalStudentsToLoad > 200 && (
            <div
              style={{
                position: 'absolute',
                bottom: '0',
                width: '100%',
                zIndex: 10, // over SlickGrid
                left: '0',
                right: '0',
              }}
            >
              <ProgressBar
                data-testid="gradebook-submission-progress-bar"
                margin="0"
                screenReaderLabel={I18n.t('Loading Gradebook submissions')}
                size="x-small"
                valueMax={
                  Object.keys(this.props.assignmentMap).length * this.props.totalStudentsToLoad
                }
                valueNow={this.props.totalSubmissionsLoaded}
              />
            </div>
          )}

        {this.options.custom_grade_statuses_enabled && (
          <TotalGradeOverrideTrayProvider
            customGradeStatuses={this.options.custom_grade_statuses}
            handleDismiss={(manualDismiss: boolean) => {
              this.gradebookGrid?.gridSupport?.helper.focus()
              if (manualDismiss) {
                this.gradebookGrid?.gridSupport?.helper.beginEdit()
              }
            }}
            handleOnGradeChange={(studentId, grade) =>
              this.finalGradeOverrides?.updateGrade(studentId, grade)
            }
            navigateDown={() => {
              this.gradebookGrid?.grid?.navigateDown()
              this.gradebookGrid?.gridSupport?.helper.commitCurrentEdit()
            }}
            navigateUp={() => {
              this.gradebookGrid?.grid?.navigateUp()
              this.gradebookGrid?.gridSupport?.helper.commitCurrentEdit()
            }}
            selectedGradingPeriodId={this.gradingPeriodId}
          />
        )}
      </>
    )
  }
}

export default Gradebook
