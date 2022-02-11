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
import {intersection} from 'lodash'
import tz from '@canvas/timezone'
import React from 'react'
import ReactDOM from 'react-dom'
import type {RequestDispatch} from '@canvas/network'
import type PerformanceControls from './PerformanceControls'
import type {ActionMenuProps} from './components/ActionMenu'
import type {
  Assignment,
  AttachmentData,
  AssignmentDueDate,
  AssignmentGroup,
  AssignmentGroupMap,
  AssignmentMap,
  ColumnSizeSettings,
  ContentLoadStates,
  Course,
  CourseContent,
  EffectiveDueDateAssignmentUserMap,
  Filter,
  FilteredContentInfo,
  FlashAlertType,
  GradebookOptions,
  GradingPeriodSet,
  InitialActionStates,
  Module,
  Section,
  SectionMap,
  Student,
  StudentMap,
  StudentGroup,
  StudentGroupMap,
  StudentGroupCategory,
  StudentGroupCategoryMap,
  Submission,
  UserSubmissionGroup
} from './gradebook.d'
import type {GridColumn, GridData, GridDisplaySettings} from './grid.d'

import LongTextEditor from '../../jquery/slickgrid.long_text_editor'
// @ts-ignore
import KeyboardNavDialog from '@canvas/keyboard-nav-dialog'
// @ts-ignore
import KeyboardNavTemplate from '@canvas/keyboard-nav-dialog/jst/KeyboardNavDialog.handlebars'
import GradingPeriodSetsApi from '@canvas/grading/jquery/gradingPeriodSetsApi'
// @ts-ignore
import InputFilterView from 'backbone-input-filter-view'
// @ts-ignore
import I18n from 'i18n!gradebook'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import * as EffectiveDueDates from '@canvas/grading/EffectiveDueDates'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import AssignmentOverrideHelper from '@canvas/due-dates/AssignmentOverrideHelper'
// @ts-ignore
import UserSettings from '@canvas/user-settings'
import Spinner from 'spin.js'
// @ts-ignore
import GradeDisplayWarningDialog from '../../jquery/GradeDisplayWarningDialog.coffee'
import PostGradesFrameDialog from '../../jquery/PostGradesFrameDialog'
import NumberCompare from '../../util/NumberCompare'
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
import FinalGradeOverrides from './FinalGradeOverrides/index'
import GradebookGrid from './GradebookGrid/index'
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
import type {StatusColors} from './constants/colors'
import StudentDatastore from './stores/StudentDatastore'
import PostGradesStore from '../SISGradePassback/PostGradesStore'
import SubmissionStateMap from '@canvas/grading/SubmissionStateMap'
import DownloadSubmissionsDialogManager from '../shared/DownloadSubmissionsDialogManager'
import ReuploadSubmissionsDialogManager from '../shared/ReuploadSubmissionsDialogManager'
import GradebookKeyboardNav from '../../jquery/GradebookKeyboardNav'
import assignmentHelper from '../shared/helpers/assignmentHelper'
import {getWidth as getTextWidth} from '../shared/helpers/TextMeasure'
import * as GradeInputHelper from '@canvas/grading/GradeInputHelper'
import OutlierScoreHelper from '@canvas/grading/OutlierScoreHelper'
import {isPostable} from '@canvas/grading/SubmissionHelper'
import LatePolicyApplicator from '../LatePolicyApplicator'
import {Button} from '@instructure/ui-buttons'
import {IconSettingsSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import {deferPromise} from 'defer-promise'
import MultiSelectSearchInput from './components/MultiSelectSearchInput'
import ApplyScoreToUngradedModal from './components/ApplyScoreToUngradedModal'
import ScoreToUngradedManager from '../shared/ScoreToUngradedManager'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/datetime'
import 'jqueryui/dialog'
import 'jqueryui/tooltip'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import 'jquery-tinypubsub'
import 'jqueryui/position'
import '@canvas/util/jquery/fixDialogButtons'

import {
  compareAssignmentDueDates,
  confirmViewUngradedAsZero,
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
  renderComponent,
  hiddenStudentIdsForAssignment,
  getDefaultSettingKeyForColumnType,
  sectionList,
  getCustomColumnId,
  getAssignmentColumnId,
  getAssignmentGroupColumnId,
  findAllAppliedFilterValuesOfType,
  getAllAppliedFilterValues
} from './Gradebook.utils'
import {
  compareAssignmentPointsPossible,
  compareAssignmentPositions,
  isDefaultSortOrder,
  localeSort,
  wrapColumnSortFn
} from './Gradebook.sorting'

import {
  getInitialGradebookContent,
  getInitialGridDisplaySettings,
  getInitialCourseContent,
  getInitialContentLoadStates,
  getInitialActionStates,
  columnWidths
} from './initialState'

const ASSIGNMENT_KEY_REGEX = /^assignment_(?!group)/

const HEADER_START_AND_END_WIDTHS_IN_PIXELS = 36
const testWidth = function (text: string, minWidth: number, maxWidth: number) {
  const padding = HEADER_START_AND_END_WIDTHS_IN_PIXELS * 2
  const textWidth = getTextWidth(text) || 0
  const width = Math.max(textWidth + padding, minWidth)
  return Math.min(width, maxWidth)
}
const anonymousSpeedGraderAlertMountPoint = function () {
  return document.querySelector("[data-component='AnonymousSpeedGraderAlert']")
}

export function Portal({node, children}) {
  return ReactDOM.createPortal(children, node)
}

type GradebookProps = {
  applyScoreToUngradedModalNode: HTMLElement
  colors: StatusColors
  dispatch: RequestDispatch
  filterNavNode: HTMLElement
  filters: Filter[]
  flashAlerts: FlashAlertType[]
  flashMessageContainer: HTMLElement
  gradebookEnv: any
  gradebookMenuNode: HTMLElement
  gradingPeriodsFilterContainer: HTMLElement
  gridColorNode: HTMLElement
  isFiltersLoading: boolean
  isModulesLoading: boolean
  modules: Module[]
  performanceControls: PerformanceControls
  settingsModalButtonContainer: HTMLElement
  viewOptionsMenuNode: HTMLElement
}

type GradebookState = {
  assignmentGroups: AssignmentGroup[]
  gridColors: StatusColors
  isEssentialDataLoaded: boolean
  modules: Module[]
  sections: Section[]
  gradingPeriodId: string
}

class Gradebook extends React.Component<GradebookProps, GradebookState> {
  kbDialog: KeyboardNavDialog

  anonymousSpeedGraderAlert?: any

  userFilter: InputFilterView

  assignmentStudentVisibility: any = {}

  teacherNotesNotYetLoaded: any

  headerComponentRefs: any = {}

  hasSections: any = $.Deferred()

  calculatedGradesByStudentId: any = {}

  effectiveDueDates: EffectiveDueDateAssignmentUserMap = {}

  $grid: any

  postGradesLtis: {id: string; name: string; onSelect: any}[] = []

  disablePostGradesFeature: boolean = false

  viewOptionsMenu?: HTMLElement

  studentViewStudents: StudentMap = {}

  keyboardNav?: GradebookKeyboardNav

  filteredContentInfo: FilteredContentInfo = {
    invalidAssignmentGroups: [],
    totalPointsPossible: 0
  }

  sections: SectionMap = {}

  userFilterTerm?: string

  filteredStudentIds: string[] = []

  assignmentGroups: AssignmentGroupMap = {}

  contentLoadStates: ContentLoadStates

  course: Course

  filteredAssignmentIds: string[] = []

  gradebookEnv: any

  gradebookSettingsModal?: React.RefObject<HTMLElement & {open: () => void}>

  isRunningScoreToUngraded: boolean

  gradebookSettingsModalButton: React.RefObject<any> = React.createRef()

  gradingPeriodSet: GradingPeriodSet | null = null

  gradingPeriodId: string = '0'

  options: GradebookOptions

  sections_enabled: boolean = false

  show_attendance?: boolean

  statusesModal?: HTMLElement & {open?: () => void}

  studentGroups: StudentGroupMap = {}

  studentGroupsEnabled?: boolean

  students: StudentMap = {}

  totalColumnPositionChanged?: boolean

  uid?: string

  courseFeatures: {
    finalGradeOverrideEnabled: boolean
    allowViewUngradedAsZero: boolean
  }

  courseSettings: CourseSettings

  dataLoader: DataLoader

  gridData: GridData = {
    columns: {
      definitions: {},
      frozen: [],
      scrollable: []
    },
    rows: []
  }

  gradebookGrid: GradebookGrid

  finalGradeOverrides: FinalGradeOverrides | null

  postPolicies: PostPolicies

  gridReady: any = $.Deferred()

  _essentialDataLoaded: any = deferPromise()

  courseContent: CourseContent

  gradebookContent: {
    customColumns: GridColumn[]
  }

  actionStates?: InitialActionStates

  gradebookColumnOrderSettings?: {
    direction: string
    freezeTotalGrade?: boolean
    sortType: string | undefined
    customOrder?: any
  }

  defaultSortType: string = 'assignment_group'

  spinner?: Spinner

  gridDisplaySettings: GridDisplaySettings

  startedInitializing?: boolean

  assignments: AssignmentMap = {}

  postGradesStore?: any

  submissionStateMap!: SubmissionStateMap

  studentGroupCategories: StudentGroupCategoryMap = {}

  gradebookColumnSizeSettings: ColumnSizeSettings = {}

  scoreToUngradedManager: ScoreToUngradedManager | null

  constructor(props: GradebookProps) {
    super(props)
    this.options = {...(props.gradebookEnv || {}), ...props}
    this.gradingPeriodSet = this.options.grading_period_set
      ? GradingPeriodSetsApi.deserializeSet(this.options.grading_period_set)
      : null
    this.gradingPeriodId = this.getCurrentGradingPeriod()

    this.state = {
      gridColors: statusColors(this.options.colors),
      modules: [],
      assignmentGroups: [],
      sections: this.options.sections.length > 1 ? this.options.sections : [],
      isEssentialDataLoaded: false,
      gradingPeriodId: this.getCurrentGradingPeriod()
    }
    this.course = getCourseFromOptions(this.options)
    this.courseFeatures = getCourseFeaturesFromOptions(this.options)
    this.courseSettings = new CourseSettings(this, {
      allowFinalGradeOverride: this.options.course_settings.allow_final_grade_override
    })
    this.dataLoader = new DataLoader({
      gradebook: this,
      dispatch: props.dispatch,
      performanceControls: props.performanceControls,
      loadAssignmentsByGradingPeriod: this.options.load_assignments_by_grading_period_enabled
    })
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
    this.isRunningScoreToUngraded = false
    if (this.allowApplyScoreToUngraded()) {
      const progressData = this.options.gradebook_score_to_ungraded_progress
      let lastProgress
      if (progressData) {
        lastProgress = {
          progressId: `${progressData.progress.id}`,
          workflowState: progressData.progress.workflow_state
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
    this.gridDisplaySettings = getInitialGridDisplaySettings(
      this.options.settings,
      this.props.colors
    )
    this.contentLoadStates = getInitialContentLoadStates(this.options)
    this.actionStates = getInitialActionStates()
    this.setAssignments({})
    this.setAssignmentGroups({})
    this.courseContent.students = new StudentDatastore(this.students, this.studentViewStudents)
    this.initPostGradesStore()
    this.initPostGradesLtis()
    this.checkForUploadComplete()

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
    this.initShowSeparateFirstLastNames(
      this.options.settings.show_separate_first_last_names === 'true' &&
        this.options.allow_separate_first_last_names
    )
    this.initSubmissionStateMap()
    this.gradebookColumnSizeSettings = this.options.gradebook_column_size_settings
    this.setColumnOrder({
      ...this.options.gradebook_column_order_settings,
      // TODO: resolve boolean vs. string (e.g. 'true') mismatch for freezeTotalGrade
      freezeTotalGrade:
        (this.options.gradebook_column_order_settings != null
          ? this.options.gradebook_column_order_settings.freezeTotalGrade
          : undefined) === 'true'
    })
    this.teacherNotesNotYetLoaded =
      this.getTeacherNotesColumn() == null || this.getTeacherNotesColumn()!.hidden
    this.gotSections(this.options.sections)
    // eslint-disable-next-line promise/catch-or-return
    this.hasSections.then(() => {
      if (!this.getSelectedSecondaryInfo()) {
        if (this.sections_enabled) {
          return (this.gridDisplaySettings.selectedSecondaryInfo = 'section')
        } else {
          return (this.gridDisplaySettings.selectedSecondaryInfo = 'none')
        }
      }
    })
    this.setStudentGroups(this.options.student_groups)

    this.bindGridEvents()
  }

  bindGridEvents = () => {
    this.gradebookGrid.events.onColumnsReordered.subscribe((_event, columns) => {
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
      if (!_.isEqual(currentFrozenIds, updatedFrozenIds)) {
        currentFrozenColumns = currentFrozenIds.map(columnId => {
          return this.gridData.columns.definitions[columnId]
        })
        currentCustomColumnIds = (function () {
          let j, len
          const results: string[] = []
          for (j = 0, len = currentFrozenColumns.length; j < len; j++) {
            const column = currentFrozenColumns[j]
            if (column.type === 'custom_column' && column.customColumnId) {
              results.push(column.customColumnId)
            }
          }
          return results
        })()
        updatedCustomColumnIds = (function () {
          let j, len
          const ref1 = columns.frozen
          const results: string[] = []
          for (j = 0, len = ref1.length; j < len; j++) {
            const column = ref1[j]
            if (column.type === 'custom_column') {
              results.push(column.customColumnId)
            }
          }
          return results
        })()
        if (!_.isEqual(currentCustomColumnIds, updatedCustomColumnIds)) {
          // eslint-disable-next-line promise/catch-or-return
          this.reorderCustomColumns(updatedCustomColumnIds).then(() => {
            const colsById = _(this.gradebookContent.customColumns).indexBy(function (c) {
              return c.id
            })
            if (this?.gradebookContent.customColumns) {
              this.gradebookContent.customColumns = _(updatedCustomColumnIds).map(function (id) {
                return colsById[id]
              })
            }
            return this?.gradebookContent.customColumns
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

  initialize = () => {
    this.dataLoader.loadInitialData()
    // Until GradebookGrid is rendered reactively, it will need to be rendered
    // once and only once. It depends on all essential data from the initial
    // data load. When all of that data has loaded, this deferred promise will
    // resolve and render the grid. As a promise, it only resolves once.

    // eslint-disable-next-line promise/catch-or-return
    this._essentialDataLoaded.promise.then(() => {
      return this.finishRenderingUI()
    })
    return this.gridReady.then(() => {
      // Preload the Grade Detail Tray
      AsyncComponents.loadGradeDetailTray()
      this.renderViewOptionsMenu()
      this.renderGradebookSettingsModal()
      this.renderSearchFilters()
    })
  }

  // called from ui/bundles/gradebook.js
  onShow = () => {
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

  loadOverridesForSIS = () => {
    if (this.options.post_grades_feature) {
      return this.dataLoader.loadOverridesForSIS()
    }
  }

  addOverridesToPostGradesStore = assignmentGroups => {
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
  setAssignmentVisibility = studentIds => {
    let a, assignmentId, hiddenStudentIds, j, k, len, len1, student, studentId
    const studentsWithHiddenAssignments: string[] = []
    const ref1 = this.assignments
    for (assignmentId in ref1) {
      a = ref1[assignmentId]
      if (a.only_visible_to_overrides) {
        hiddenStudentIds = hiddenStudentIdsForAssignment(studentIds, a)
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
    const ref2: string[] = _.uniq(studentsWithHiddenAssignments)
    for (k = 0, len1 = ref2.length; k < len1; k++) {
      studentId = ref2[k]
      student = this.student(studentId)
      this.calculateStudentGrade(student)
    }
  }

  updateAssignmentVisibilities = hiddenSub => {
    const assignment = this.assignments[hiddenSub.assignment_id]
    const filteredVisibility = assignment.assignment_visibility.filter(function (id) {
      return id !== hiddenSub.user_id
    })
    return (assignment.assignment_visibility = filteredVisibility)
  }

  gotCustomColumns = columns => {
    this.gradebookContent.customColumns = columns
    columns.forEach(column => {
      const customColumn = this.buildCustomColumn(column)
      return (this.gridData.columns.definitions[customColumn.id] = customColumn)
    })
    this.setCustomColumnsLoaded(true)
    this._updateEssentialDataLoaded()
  }

  gotCustomColumnDataChunk = (customColumnId: string, columnData) => {
    let datum, j, len, student
    const studentIds: string[] = []
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

  // Assignment Group Data & Lifecycle Methods
  updateAssignmentGroups = (assignmentGroups: AssignmentGroup[], gradingPeriodIds: string[]) => {
    this.gotAllAssignmentGroups(assignmentGroups)
    this.setState({assignmentGroups})
    this.setAssignmentsLoaded(gradingPeriodIds)
    this.renderViewOptionsMenu()
    this.renderFilters()
    this.updateColumnHeaders()
    this._updateEssentialDataLoaded()
  }

  gotAllAssignmentGroups = assignmentGroups => {
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

  updateGradingPeriodAssignments = gradingPeriodAssignments => {
    this.gotGradingPeriodAssignments({
      grading_period_assignments: gradingPeriodAssignments
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

  gotGradingPeriodAssignments = ({grading_period_assignments: gradingPeriodAssignments}) => {
    return (this.courseContent.gradingPeriodAssignments = gradingPeriodAssignments)
  }

  gotSections = sections => {
    this.setSections(sections.map(htmlEscape))
    this.hasSections.resolve()
    return this.postGradesStore.setSections(this.sections)
  }

  gotChunkOfStudents = (students: Student[]) => {
    this.courseContent.assignmentStudentVisibility = {}
    const escapeStudentContent = student => {
      const unescapedName = student.name
      const unescapedSortableName = student.sortable_name
      const unescapedFirstName = student.first_name
      const unescapedLastName = student.last_name

      // TODO: selectively escape fields
      const escapedStudent = htmlEscape(student)
      escapedStudent.name = unescapedName
      escapedStudent.sortable_name = unescapedSortableName
      escapedStudent.first_name = unescapedFirstName
      escapedStudent.last_name = unescapedLastName

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
    AssignmentOverrideHelper.setStudentDisplayNames([
      ...Object.values(this.students),
      ...Object.values(this.studentViewStudents)
    ])
    // eslint-disable-next-line promise/catch-or-return
    this.gridReady.then(() => {
      return this.setupGrading(students)
    })
    if (this.isFilteringRowsBySearchTerm()) {
      // When filtering, students cannot be matched until loaded. The grid must
      // be re-rendered more aggressively to ensure new rows are inserted.
      this.buildRows()
    } else {
      this.gradebookGrid.render()
    }

    const searchFilterStudents = this.courseContent.students.listStudents({
      includePlaceholders: false
    })
    if (this._gridHasRendered() && searchFilterStudents.length > 0) {
      this.renderStudentSearchFilter(searchFilterStudents)
    }
  }

  // # Post-Data Load Initialization
  finishRenderingUI = () => {
    this.initGrid()
    this.initHeader()
    this.gridReady.resolve()
    return this.loadOverridesForSIS()
  }

  setupGrading = students => {
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

  resetGrading = () => {
    this.initSubmissionStateMap()
    return this.setupGrading(this.courseContent.students.listStudents())
  }

  getSubmission = (studentId, assignmentId) => {
    const student = this.student(studentId)
    return student != null ? student[`assignment_${assignmentId}`] : undefined
  }

  updateEffectiveDueDatesFromSubmissions = submissions => {
    return EffectiveDueDates.updateWithSubmissions(
      this.effectiveDueDates,
      submissions,
      this.gradingPeriodSet?.gradingPeriods
    )
  }

  updateAssignmentEffectiveDueDates = (assignment: Assignment) => {
    assignment.effectiveDueDates = this.effectiveDueDates[assignment.id] || {}
    return (assignment.inClosedGradingPeriod = _.some(assignment.effectiveDueDates, date => {
      return date.in_closed_grading_period
    }))
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

  studentsThatCanSeeAssignment = (assignmentId: string) => {
    const {assignmentStudentVisibility} = this.courseContent
    if (assignmentStudentVisibility[assignmentId] == null) {
      const allStudentsById = {...this.students, ...this.studentViewStudents}

      const assignment = this.getAssignment(assignmentId)
      assignmentStudentVisibility[assignmentId] = assignment.only_visible_to_overrides
        ? _.pick(allStudentsById, ...assignment.assignment_visibility)
        : allStudentsById
    }

    return assignmentStudentVisibility[assignmentId]
  }

  // This is like studentsThatCanSeeAssignment, but returns only students
  // visible with the current filters, instead of all the students the
  // Gradebook knows about.
  visibleStudentsThatCanSeeAssignment = (assignmentId: string) => {
    const visibleStudentsIgnoringSearch: {[key: string]: Student} = _.pick(
      this.studentsThatCanSeeAssignment(assignmentId),
      this.courseContent.students.listStudentIds()
    )

    return Object.fromEntries(
      Object.entries(visibleStudentsIgnoringSearch).filter(([_id, student]) =>
        this.rowFilter(student)
      )
    )
  }

  isInvalidSort = () => {
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
      this.courseContent.contextModules.length === 0
    ) {
      // This course was sorted by module_position at some point but no longer contains modules
      // let's mark it invalid so it reverts to default sort
      return true
    }
    return false
  }

  setColumnOrder = order => {
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

  getColumnOrder = () => {
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

  saveColumnOrder = () => {
    let url
    if (!this.isInvalidSort()) {
      url = this.options.gradebook_column_order_settings_url
      return $.ajaxJSON(url, 'POST', {
        column_order: this.getColumnOrder()
      })
    }
  }

  reorderCustomColumns = ids => {
    return $.ajaxJSON(this.options.reorder_custom_columns_url, 'POST', {
      order: ids
    })
  }

  saveCustomColumnOrder = () => {
    this.setColumnOrder({
      customOrder: this.gridData.columns.scrollable,
      sortType: 'custom'
    })
    return this.saveColumnOrder()
  }

  arrangeColumnsBy = (newSortOrder, isFirstArrangement) => {
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

  makeColumnSortFn = sortOrder => {
    switch (sortOrder.sortType) {
      case 'due_date':
        return wrapColumnSortFn(compareAssignmentDueDates, sortOrder.direction)
      case 'module_position':
        return wrapColumnSortFn(this.compareAssignmentModulePositions, sortOrder.direction)
      case 'name':
        return wrapColumnSortFn(this.compareAssignmentNames, sortOrder.direction)
      case 'points':
        return wrapColumnSortFn(compareAssignmentPointsPossible, sortOrder.direction)
      case 'custom':
        return this.makeCompareAssignmentCustomOrderFn(sortOrder)
      default:
        return wrapColumnSortFn(compareAssignmentPositions, sortOrder.direction)
    }
  }

  compareAssignmentModulePositions = (a, b) => {
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
      return compareAssignmentPositions(a, b)
    }
  }

  compareAssignmentNames = (a, b) => {
    return localeSort(a.object.name, b.object.name)
  }

  makeCompareAssignmentCustomOrderFn = sortOrder => {
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
        return wrapColumnSortFn(compareAssignmentPositions)(a, b)
      }
    }
  }

  // Filtering
  rowFilter = (student: Student) => {
    if (!this.isFilteringRowsBySearchTerm()) {
      return true
    }

    if (this.options.gradebook_assignment_search_and_redesign) {
      return this.filteredStudentIds?.includes(student.id)
    }

    const propertiesToMatch = ['name', 'login_id', 'short_name', 'sortable_name', 'sis_user_id']
    const pattern = new RegExp(this.userFilterTerm || '', 'i')
    return _.some(propertiesToMatch, function (prop) {
      let ref1
      return (ref1 = student[prop]) != null ? ref1.match(pattern) : undefined
    })
  }

  filterAssignments = (assignments: Assignment[]) => {
    const assignmentFilters = [
      this.filterAssignmentBySubmissionTypes,
      this.filterAssignmentByPublishedStatus,
      this.filterAssignmentByAssignmentGroup,
      this.filterAssignmentByGradingPeriod,
      this.filterAssignmentByModule,
      this.filterAssignmentBySearchInput,
      this.filterAssignmentByStartDate,
      this.filterAssignmentByEndDate,
      this.filterAssignmentsBySubmissions
    ]
    const matchesAllFilters = assignment => assignmentFilters.every(filter => filter(assignment))

    return assignments.filter(matchesAllFilters)
  }

  filterAssignmentBySearchInput = (assignment: Assignment) => {
    if (this.filteredAssignmentIds?.length) {
      return this.filteredAssignmentIds.includes(assignment.id)
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

    const assignmentGroupIds = findAllAppliedFilterValuesOfType(
      'assignment-group',
      this.props.filters
    )
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
        (assignment.module_ids || []).indexOf(this.getFilterColumnsBySetting('contextModuleId')) >=
        0
      )
    }

    const moduleIds = findAllAppliedFilterValuesOfType('module', this.props.filters)
    return moduleIds.length === 0 || intersection(assignment.module_ids, moduleIds).length > 0
  }

  filterAssignmentsBySubmissions = (assignment: Assignment) => {
    const submissions = this.submissionStateMap.getSubmissions(assignment.id)
    const submissionFilters = findAllAppliedFilterValuesOfType('submissions', this.props.filters)
    const wasSubmitted = s => !['unsubmitted', 'deleted'].includes(s.workflow_state)
    const isGraded = s => s.excused || (!!s.score && s.workflow_state === 'graded')

    return (
      submissionFilters.length === 0 ||
      submissionFilters.some(filter => {
        if (filter === 'has-ungraded-submissions') {
          return submissions.some(s => wasSubmitted(s) && !isGraded(s))
        } else if (filter === 'has-submissions') {
          return submissions.some(wasSubmitted)
        } else {
          return true
        }
      })
    )
  }

  filterAssignmentByStartDate = (assignment: Assignment) => {
    const date = findAllAppliedFilterValuesOfType('start-date', this.props.filters)[0]
    if (!date) {
      return true
    }
    return Object.values(assignment.effectiveDueDates).some(
      (effectiveDueDateObject: AssignmentDueDate) =>
        tz.parse(effectiveDueDateObject.due_at) >= tz.parse(date)
    )
  }

  filterAssignmentByEndDate = (assignment: Assignment) => {
    const date = findAllAppliedFilterValuesOfType('end-date', this.props.filters)[0]
    if (!date) {
      return true
    }
    return Object.values(assignment.effectiveDueDates).some(
      (effectiveDueDateObject: AssignmentDueDate) =>
        tz.parse(effectiveDueDateObject.due_at) <= tz.parse(date)
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
        'total_grade_override'
      ]
      if (anonymousColumnIds.indexOf(this.getSortRowsBySetting().columnId) >= 0) {
        this.setSortRowsBySetting('student', 'sortable_name', 'ascending')
      }
    }
    this.gradebookGrid.gridSupport?.columns.updateColumnHeaders([
      getAssignmentColumnId(assignment.id)
    ])
    this.updateFilteredContentInfo()
    return this.resetGrading()
  }

  handleSubmissionsDownloading = (assignmentId: string) => {
    this.getAssignment(assignmentId).hasDownloadedSubmissions = true
    return this.gradebookGrid.gridSupport?.columns.updateColumnHeaders([
      getAssignmentColumnId(assignmentId)
    ])
  }

  // filter, sort, and build the dataset for slickgrid to read from, then
  // force a full redraw
  buildRows = () => {
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

  buildRow = (student: Student) => {
    // because student is current mutable, we need to retain the reference
    return student
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
    for (let j = 0, len = student_submission_groups.length; j < len; j++) {
      const studentSubmissionGroup = student_submission_groups[j]
      changedStudentIds.push(studentSubmissionGroup.user_id)
      const student = this.student(studentSubmissionGroup.user_id)
      const ref1 = studentSubmissionGroup.submissions
      for (let k = 0, len1 = ref1.length; k < len1; k++) {
        const submission = ref1[k]
        submission.posted_at = tz.parse(submission.posted_at)
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

  student = (id: string) => {
    return this.students[id] || this.studentViewStudents[id]
  }

  updateSubmission = (
    submission: Partial<Submission> & Pick<Submission, 'user_id' | 'assignment_id'>
  ) => {
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

  // this is used after the CurveGradesDialog submit xhr comes back.  it does not use the api
  // because there is no *bulk* submissions#update endpoint in the api.
  // It is different from gotSubmissionsChunk in that gotSubmissionsChunk expects an array of students
  // where each student has an array of submissions.  This one just expects an array of submissions,
  // they are not grouped by student.
  updateSubmissionsFromExternal = (submissions: Submission[]) => {
    let cell, column, idToMatch, index, k, len1, student, submissionState
    const columns = this.gradebookGrid.grid.getColumns()
    const changedColumnHeaders = {}
    const changedStudentIds: string[] = []
    for (let j = 0, len = submissions.length; j < len; j++) {
      const submission = submissions[j]
      submission.posted_at = tz.parse(submission.posted_at)
      student = this.student(submission.user_id)
      if (!student) {
        // if the student isn't loaded, we don't need to update it
        continue
      }
      idToMatch = getAssignmentColumnId(submission.assignment_id)
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
    const changedColumnIds = Object.keys(changedColumnHeaders).map(getAssignmentColumnId)
    this.gradebookGrid.gridSupport?.columns.updateColumnHeaders(changedColumnIds)
    return this.updateRowCellsForStudentIds(_.uniq(changedStudentIds))
  }

  submissionsForStudent = (student: Student) => {
    const allSubmissions = (function () {
      const results: any = []
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
    return _.filter(allSubmissions, submission => {
      const studentPeriodInfo =
        this.effectiveDueDates[submission.assignment_id]?.[submission.user_id]
      return studentPeriodInfo && studentPeriodInfo.grading_period_id === this.gradingPeriodId
    })
  }

  getStudentGrades = (student: Student, preferCachedGrades) => {
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

  calculateStudentGrade = (student: Student, preferCachedGrades = false): null | void => {
    if (!(student.loaded && student.initialized)) {
      return null
    }

    let grades = this.getStudentGrades(student, preferCachedGrades)
    if (this.isFilteringColumnsByGradingPeriod() && this.gradingPeriodId) {
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
  fixMaxHeaderWidth = () => {
    return this.$grid.find('.slick-header-columns').width(1000000)
  }

  // SlickGrid doesn't have a blur event for the grid, so this mimics it in
  // conjunction with a click listener on <body />. When we 'blur' the grid
  // by clicking outside of it, save the current field.
  onGridBlur = e => {
    let className
    if (this.getSubmissionTrayState().open) {
      this.closeSubmissionTray()
    }
    // Prevent exiting the cell editor when clicking in the cell being edited.
    const editingNode = this.gradebookGrid.gridSupport?.state.getEditingNode()
    if (editingNode != null ? editingNode.contains(e.target) : undefined) {
      return
    }
    const activeNode = this.gradebookGrid.gridSupport?.state.getActiveNode()
    if (!activeNode) {
      return
    }
    if (activeNode.contains(e.target)) {
      // SlickGrid does not re-engage the editor for the active cell upon single click
      this.gradebookGrid.gridSupport?.helper.beginEdit()
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
    return this.gradebookGrid.gridSupport?.state.blur()
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
        disabled: !this.contentLoadStates.studentsLoaded
      }
      return renderComponent(SectionFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentSection(null)
      return ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  updateCurrentSection = (sectionId: string | null) => {
    sectionId = sectionId === '0' ? null : sectionId
    const currentSection = this.getFilterRowsBySetting('sectionId')
    if (currentSection !== sectionId) {
      this.setFilterRowsBySetting('sectionId', sectionId)
      this.postGradesStore.setSelectedSection(sectionId)
      return this.saveSettings({}).then(() => {
        this.updateSectionFilterVisibility()
        return this.dataLoader.reloadStudentDataForSectionFilterChange()
      })
    }
  }

  showSections = () => {
    return this.sections_enabled
  }

  showStudentGroups = () => {
    return this.studentGroupsEnabled
  }

  updateStudentGroupFilterVisibility = () => {
    if (this.options.enhanced_gradebook_filters) return
    let studentGroupSets
    const mountPoint = document.getElementById('student-group-filter-container')
    if (
      this.showStudentGroups() &&
      this.gridDisplaySettings.selectedViewOptionsFilters.indexOf('studentGroups') >= 0
    ) {
      studentGroupSets = Object.values(this.studentGroupCategories).sort(
        (a: StudentGroupCategory, b: StudentGroupCategory) => {
          return a.id.localeCompare(b.id)
        }
      )
      const props = {
        studentGroupSets,
        onSelect: this.updateCurrentStudentGroup,
        selectedStudentGroupId: this.getStudentGroupToShow(),
        disabled: !this.contentLoadStates.studentsLoaded
      }
      renderComponent(StudentGroupFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentStudentGroup(null)
      ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  getStudentGroupToShow = () => {
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
        return this.dataLoader.reloadStudentDataForStudentGroupFilterChange()
      })
    }
  }

  assignmentGroupList = () => {
    if (!this.assignmentGroups) {
      return []
    }
    return Object.values(this.assignmentGroups).sort((a: AssignmentGroup, b: AssignmentGroup) => {
      return a.position - b.position
    })
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
        selectedAssignmentGroupId: this.getAssignmentGroupToShow()
      }
      renderComponent(AssignmentGroupFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentAssignmentGroup(null)
      ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  updateCurrentAssignmentGroup = group => {
    if (this.getFilterColumnsBySetting('assignmentGroupId') !== group) {
      this.setFilterColumnsBySetting('assignmentGroupId', group)
      this.saveSettings()
      this.resetGrading()
      this.updateFilteredContentInfo()
      this.updateColumnsAndRenderViewOptionsMenu()
      return this.updateAssignmentGroupFilterVisibility()
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
          (a, b) => a.startDate - b.startDate
        ),
        onSelect: this.updateCurrentGradingPeriod,
        selectedGradingPeriodId: this.gradingPeriodId
      }
      return renderComponent(GradingPeriodFilter, mountPoint, props)
    } else if (mountPoint != null) {
      this.updateCurrentGradingPeriod(null)
      ReactDOM.unmountComponentAtNode(mountPoint)
    }
  }

  updateCurrentGradingPeriod = period => {
    if (this.getFilterColumnsBySetting('gradingPeriodId') !== period) {
      this.setFilterColumnsBySetting('gradingPeriodId', period)
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
      this.setFilterColumnsBySetting('contextModuleId', moduleId)
      this.saveSettings()
      this.updateFilteredContentInfo()
      this.updateColumnsAndRenderViewOptionsMenu()
      return this.updateModulesFilterVisibility()
    }
  }

  moduleList = () => {
    return this.courseContent.contextModules.sort((a: Module, b: Module) => {
      return a.position - b.position
    })
  }

  updateModulesFilterVisibility = () => {
    if (this.options.enhanced_gradebook_filters) return
    let ref1
    const mountPoint = document.getElementById('modules-filter-container')
    if (
      ((ref1 = this.courseContent.contextModules) != null ? ref1.length : undefined) > 0 &&
      this.gridDisplaySettings.selectedViewOptionsFilters.indexOf('modules') >= 0
    ) {
      const props = {
        disabled: false,
        modules: this.moduleList(),
        onSelect: this.updateCurrentModule,
        selectedModuleId: this.getModuleToShow()
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
      isAdmin: isAdmin()
    })
  }

  initPostGradesStore = () => {
    this.postGradesStore = PostGradesStore({
      course: {
        id: this.options.context_id,
        sis_id: this.options.context_sis_id
      }
    })
    this.postGradesStore.addChangeListener(this.updatePostGradesFeatureButton)
    const sectionId = this.getFilterRowsBySetting('sectionId')
    this.postGradesStore.setSelectedSection(sectionId)
  }

  initPostGradesLtis = () => {
    return (this.postGradesLtis = this.options.post_grades_ltis.map(lti => {
      return {
        id: lti.id,
        name: lti.name,
        onSelect: () => {
          const postGradesDialog = new PostGradesFrameDialog({
            returnFocusTo: document.querySelector("[data-component='ActionMenu'] button"),
            baseUrl: lti.data_url
          })
          setTimeout(() => {
            return postGradesDialog.open()
          })
          return (
            (window.external_tool_redirect = {
              ready: postGradesDialog.close,
              cancel: postGradesDialog.close
            }),
            10
          )
        }
      }
    }))
  }

  updatePostGradesFeatureButton = () => {
    this.disablePostGradesFeature =
      !this.postGradesStore.hasAssignments() || !this.postGradesStore.selectedSISId()
    return this.gridReady.then(() => {
      return this.renderActionMenu()
    })
  }

  initHeader = () => {
    this.renderGradebookMenus()
    this.renderFilters()
    this.arrangeColumnsBy(this.getColumnOrder(), true)
    this.renderGradebookSettingsModal()
    this.renderStatusesModal()
    return $('#keyboard-shortcuts').click(function () {
      const questionMarkKeyDown = $.Event('keydown', {
        keyCode: 191,
        shiftKey: true
      })
      return $(document).trigger(questionMarkKeyDown)
    })
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
        this.contentLoadStates.teacherNotesColumnUpdating || this.gridReady.state() !== 'resolved',
      onSelect,
      selected: showingNotes
    }
  }

  getColumnSortSettingsViewOptionsMenuProps = () => {
    const storedSortOrder = this.getColumnOrder()
    const criterion = isDefaultSortOrder(storedSortOrder.sortType)
      ? 'default'
      : storedSortOrder.sortType
    return {
      criterion,
      direction: storedSortOrder.direction || 'ascending',
      disabled: !this.assignmentsLoadedForCurrentView(),
      modulesEnabled: this.courseContent.contextModules.length > 0,
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

  getFilterSettingsViewOptionsMenuProps = () => {
    return {
      available: this.listAvailableViewOptionsFilters(),
      onSelect: this.updateFilterSettings,
      selected: this.listSelectedViewOptionsFilters()
    }
  }

  updateFilterSettings = filters => {
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
      onSelectShowStatusesModal: () => {
        this.statusesModal?.open?.()
      },
      onSelectViewUngradedAsZero: () => {
        confirmViewUngradedAsZero({
          currentValue: this.gridDisplaySettings.viewUngradedAsZero,
          onAccepted: () => {
            this.toggleViewUngradedAsZero()
          }
        })
      },
      viewUngradedAsZero: this.gridDisplaySettings.viewUngradedAsZero,
      allowViewUngradedAsZero: this.courseFeatures.allowViewUngradedAsZero
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

  getAssignmentOrder = () => {
    return this.gridData.columns.scrollable.reduce((acc: string[], column) => {
      const matches = column.match(/assignment_(\d+)/)
      if (matches) {
        const assignmentId = matches[1]
        acc.push(assignmentId)
      }
      return acc
    }, [])
  }

  getActionMenuProps = () => {
    let attachmentData: AttachmentData
    const focusReturnPoint = document.querySelector("[data-component='ActionMenu'] button")
    const actionMenuProps: ActionMenuProps = {
      gradebookIsEditable: this.options.gradebook_is_editable,
      contextAllowsGradebookUploads: this.options.context_allows_gradebook_uploads,
      gradebookImportUrl: this.options.gradebook_import_url,
      showStudentFirstLastName: this.gridDisplaySettings.showSeparateFirstLastNames,
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
      gradingPeriodId: this.state.gradingPeriodId,
      getAssignmentOrder: this.getAssignmentOrder
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

  renderActionMenu = () => {
    const componentId = this.options.enhanced_gradebook_filters
      ? 'EnhancedActionMenu'
      : 'ActionMenu'
    const component = this.options.enhanced_gradebook_filters ? EnhancedActionMenu : ActionMenu
    const mountPoint = document.querySelector(`[data-component='${componentId}']`)
    const props = this.getActionMenuProps()
    return renderComponent(component, mountPoint, props)
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
    this.renderSearchFilters()
  }

  renderSearchFilters = () => {
    this.renderStudentSearchFilter(
      this.courseContent.students.listStudents({includePlaceholders: false})
    )
    this.renderAssignmentSearchFilter(this.assignments)
  }

  renderGradebookSettingsModal = () => {
    this.gradebookSettingsModal = React.createRef()
    const props = {
      anonymousAssignmentsPresent: _.some(this.assignments, assignment => {
        return assignment.anonymous_grading
      }),
      courseId: this.options.context_id,
      courseFeatures: this.courseFeatures,
      courseSettings: this.courseSettings,
      gradedLateSubmissionsExist: this.options.graded_late_submissions_exist,
      locale: this.options.locale,
      gradebookIsEditable: this.options.gradebook_is_editable,
      onClose: () => {
        return this.gradebookSettingsModalButton.current?.focus()
      },
      onCourseSettingsUpdated: settings => {
        return this.courseSettings.handleUpdated(settings)
      },
      onLatePolicyUpdate: this.onLatePolicyUpdate,
      postPolicies: this.postPolicies,
      ref: this.gradebookSettingsModal
    }

    if (this.options.enhanced_gradebook_filters) {
      _.extend(props, this.gradebookSettingsModalViewOptionsProps())
    }

    const $container = document.querySelector("[data-component='GradebookSettingsModal']")
    return AsyncComponents.renderGradebookSettingsModal(props, $container)
  }

  gradebookSettingsModalViewOptionsProps = () => {
    const {modulesEnabled} = this.getColumnSortSettingsViewOptionsMenuProps()

    return {
      allowSortingByModules: modulesEnabled,
      allowShowSeparateFirstLastNames: this.options.allow_separate_first_last_names,
      allowViewUngradedAsZero: this.courseFeatures.allowViewUngradedAsZero,
      loadCurrentViewOptions: () => {
        const {criterion, direction} = this.getColumnSortSettingsViewOptionsMenuProps()
        const {viewUngradedAsZero, showUnpublishedAssignments, showSeparateFirstLastNames} =
          this.gridDisplaySettings

        return {
          columnSortSettings: {criterion, direction},
          showNotes: this.isTeacherNotesColumnShown(),
          showSeparateFirstLastNames,
          showUnpublishedAssignments,
          statusColors: this.state.gridColors,
          viewUngradedAsZero
        }
      },
      onViewOptionsUpdated: this.handleViewOptionsUpdated
    }
  }

  handleViewOptionsUpdated = ({
    columnSortSettings: {criterion, direction} = {criterion: undefined, direction: undefined},
    showNotes,
    showUnpublishedAssignments,
    showSeparateFirstLastNames,
    statusColors: colors,
    viewUngradedAsZero
  }) => {
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
      showUnpublishedAssignments: oldShowUnpublished,
      showSeparateFirstLastNames: oldShowSeparateFirstLastNames,
      viewUngradedAsZero: oldViewUngradedAsZero
    } = this.gridDisplaySettings

    const viewUngradedAsZeroChanged =
      this.courseFeatures.allowViewUngradedAsZero && oldViewUngradedAsZero !== viewUngradedAsZero
    const showUnpublishedChanged = oldShowUnpublished !== showUnpublishedAssignments
    const showSeparateFirstLastNamesChanged =
      oldShowSeparateFirstLastNames !== showSeparateFirstLastNames
    const colorsChanged = !_.isEqual(this.state.gridColors, colors)

    if (
      colorsChanged ||
      showUnpublishedChanged ||
      viewUngradedAsZeroChanged ||
      showSeparateFirstLastNamesChanged
    ) {
      const changedSettings = {
        colors: colorsChanged ? colors : undefined,
        showUnpublishedAssignments: showUnpublishedChanged ? showUnpublishedAssignments : undefined,
        showSeparateFirstLastNames: showSeparateFirstLastNamesChanged
          ? showSeparateFirstLastNames
          : undefined,
        viewUngradedAsZero: viewUngradedAsZeroChanged ? viewUngradedAsZero : undefined
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

  saveUpdatedColumnOrder = ({criterion, direction}) => {
    const newSortOrder = {direction, sortType: criterion}
    const {freezeTotalGrade} = this.getColumnOrder()

    return GradebookApi.updateColumnOrder(this.options.context_id, {
      ...newSortOrder,
      freezeTotalGrade
    }).then(() => {
      this.setColumnOrder(newSortOrder)
      const columns = this.gridData.columns.scrollable.map(
        columnId => this.gridData.columns.definitions[columnId]
      )
      columns.sort(this.makeColumnSortFn(newSortOrder))
      this.gridData.columns.scrollable = columns.map(column => column.id)
    })
  }

  saveUpdatedUserSettings = ({
    colors,
    showUnpublishedAssignments,
    viewUngradedAsZero,
    showSeparateFirstLastNames
  }) => {
    return this.saveSettings({
      colors,
      showUnpublishedAssignments,
      showSeparateFirstLastNames,
      viewUngradedAsZero
    }).then(() => {
      // Make various updates to the grid depending on what changed.  These
      // triple-equals checks are deliberate: null could be an actual value for
      // the setting, so we use undefined to indicate that the setting hasn't
      // changed and hence we don't need to update it.

      if (colors !== undefined) {
        this.gridDisplaySettings.colors = colors
        this.setState({gridColors: statusColors(this.gridDisplaySettings.colors)})
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

  saveUpdatedTeacherNotesSetting = ({showNotes}) => {
    let promise

    const existingColumn = this.getTeacherNotesColumn()
    if (existingColumn != null) {
      promise = GradebookApi.updateTeacherNotesColumn(this.options.context_id, existingColumn.id, {
        hidden: !showNotes
      })
    } else {
      promise = GradebookApi.createTeacherNotesColumn(this.options.context_id).then(response => {
        this.gradebookContent.customColumns.push(response.data)
        const teacherNotesColumn = this.buildCustomColumn(response.data)
        this.gridData.columns.definitions[teacherNotesColumn.id] = teacherNotesColumn
      })
    }

    return promise.then(() => {
      if (showNotes) {
        this.showNotesColumn()
        this.reorderCustomColumns(this.gradebookContent.customColumns.map(c => c.id))
      } else {
        this.hideNotesColumn()
      }
    })
  }

  renderStatusesModal = () => {
    const statusesModalMountPoint = document.querySelector("[data-component='StatusesModal']")
    const statusesModalProps = {
      onClose: () => {
        return this.viewOptionsMenu?.focus()
      },
      colors: this.state.gridColors,
      afterUpdateStatusColors: this.updateGridColors
    }
    this.statusesModal = renderComponent(StatusesModal, statusesModalMountPoint, statusesModalProps)
    return this.statusesModal
  }

  checkForUploadComplete = () => {
    if (UserSettings.contextGet('gradebookUploadComplete')) {
      $.flashMessage(I18n.t('Upload successful'))
      return UserSettings.contextRemove('gradebookUploadComplete')
    }
  }

  weightedGroups = () => {
    return this.options.group_weighting_scheme === 'percent'
  }

  weightedGrades = () => {
    return this.weightedGroups() || !!this.gradingPeriodSet?.weighted
  }

  switchTotalDisplay = ({dontWarnAgain = false} = {}) => {
    if (dontWarnAgain) {
      UserSettings.contextSet('warned_about_totals_display', true)
    }
    this.options.show_total_grade_as_points = !this.options.show_total_grade_as_points
    $.ajaxJSON(this.options.setting_update_url, 'PUT', {
      show_total_grade_as_points: this.options.show_total_grade_as_points
    })
    this.gradebookGrid.invalidate()
    if (this.courseSettings.allowFinalGradeOverride) {
      return this.gradebookGrid.gridSupport?.columns.updateColumnHeaders([
        'total_grade',
        'total_grade_override'
      ])
    } else {
      return this.gradebookGrid.gridSupport?.columns.updateColumnHeaders(['total_grade'])
    }
  }

  togglePointsOrPercentTotals = cb => {
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

  onUserFilterInputStudents = (term: string) => {
    this.userFilterTerm = term
    return this.buildRows()
  }

  onFilterToAssignments = (assignmentIds: string[]) => {
    this.filteredAssignmentIds = assignmentIds
    this.setVisibleGridColumns()
    this.updateGrid()
  }

  onFilterToStudents = (studentIds: string[]) => {
    this.filteredStudentIds = studentIds
    this.buildRows()
  }

  studentSearchMatcher = (option, searchTerm: string) => {
    const term = searchTerm?.toLowerCase() || ''
    const studentName = option.label?.toLowerCase() || ''

    if (studentName.includes(term)) {
      return true
    }

    const {sis_user_id: sisId} = this.courseContent.students.student(option.id)
    return !!sisId && sisId.toLowerCase() === term
  }

  assignmentSearchMatcher = (option, searchTerm: string) => {
    const term = searchTerm?.toLowerCase() || ''
    const assignmentName = option.label?.toLowerCase() || ''
    return assignmentName.includes(term)
  }

  renderStudentSearchFilter = (students: Student[]) => {
    if (this.options.gradebook_assignment_search_and_redesign) {
      const props = {
        id: 'student-names-filter',
        disabled: students.length === 0 || !this._gridHasRendered(),
        label: I18n.t('Student Names'),
        customMatcher: this.studentSearchMatcher,
        onChange: this.onFilterToStudents,
        options: students.map(student => ({id: student.id, text: student.displayName})),
        placeholder: I18n.t('Search Students')
      }

      const mountPoint = document.getElementById('gradebook-student-search')
      renderComponent(MultiSelectSearchInput, mountPoint, props)
    } else {
      if (!this.userFilter) {
        const opts: any = {el: '#search-filter-container input'}
        if (this.options.remove_gradebook_student_search_delay_enabled) {
          opts.onInputDelay = 0
        }

        this.userFilter = new InputFilterView(opts)
        this.userFilter.on('input', this.onUserFilterInputStudents)
      }

      const disabled =
        !this.contentLoadStates.studentsLoaded || !this.contentLoadStates.submissionsLoaded
      this.userFilter.el.disabled = disabled
      this.userFilter.el.setAttribute('aria-disabled', disabled)
    }
  }

  renderAssignmentSearchFilter = (assignmentsById: AssignmentMap) => {
    if (this.options.gradebook_assignment_search_and_redesign) {
      const assignments = Object.values(assignmentsById)
      const props = {
        id: 'assignments-filter',
        disabled: assignments.length === 0 || !this._gridHasRendered(),
        label: I18n.t('Assignment Names'),
        customMatcher: this.assignmentSearchMatcher,
        onChange: this.onFilterToAssignments,
        options: assignments.map((assignment: Assignment) => ({
          id: assignment.id,
          text: assignment.name
        })),
        placeholder: I18n.t('Search Assignments')
      }

      const mountPoint = document.getElementById('gradebook-assignment-search')
      renderComponent(MultiSelectSearchInput, mountPoint, props)
    }
  }

  setVisibleGridColumns = () => {
    let assignmentGroupId, ref1
    let parentColumnIds = this.gridData.columns.frozen.filter(function (columnId) {
      return !/^custom_col_/.test(columnId) && !/^student/.test(columnId)
    })
    if (this.gridDisplaySettings.showSeparateFirstLastNames) {
      parentColumnIds = ['student_lastname', 'student_firstname'].concat(parentColumnIds)
    } else {
      parentColumnIds = ['student'].concat(parentColumnIds)
    }
    const customColumnIds = this.listVisibleCustomColumns().map(column => {
      return getCustomColumnId(column.id)
    })
    const assignments = this.filterAssignments(Object.values(this.assignments))
    const scrollableColumns = assignments.map(assignment => {
      return this.gridData.columns.definitions[getAssignmentColumnId(assignment.id)]
    })
    if (!this.hideAggregateColumns()) {
      for (assignmentGroupId in this.assignmentGroups) {
        const column =
          this.gridData.columns.definitions[getAssignmentGroupColumnId(assignmentGroupId)]
        if (column) {
          scrollableColumns.push(column)
        }
      }
      if (this.getColumnOrder().freezeTotalGrade) {
        if (!parentColumnIds.includes('total_grade')) {
          parentColumnIds.push('total_grade')
        }
      } else {
        const column = this.gridData.columns.definitions.total_grade
        if (column) {
          scrollableColumns.push(column)
        }
      }
      if (this.courseSettings.allowFinalGradeOverride) {
        const column = this.gridData.columns.definitions.total_grade_override
        if (column) {
          scrollableColumns.push(column)
        }
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

  updateGrid = () => {
    this.gradebookGrid.updateColumns()
    return this.gradebookGrid.invalidate()
  }

  // # Grid Column Definitions

  // Student Columns
  buildStudentColumn = (
    columnId: string,
    gradebookColumnSizeSetting: string,
    defaultWidth: number
  ) => {
    const studentColumnWidth = gradebookColumnSizeSetting
      ? parseInt(gradebookColumnSizeSetting, 10)
      : defaultWidth
    return {
      id: columnId,
      type: columnId,
      width: studentColumnWidth,
      cssClass: 'meta-cell primary-column student',
      headerCssClass: 'primary-column student',
      resizable: true
    }
  }

  // Custom Column
  buildCustomColumn = (customColumn: GridColumn) => {
    const columnId = getCustomColumnId(customColumn.id)
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
  buildAssignmentColumn = (assignment: Assignment) => {
    let assignmentWidth
    const shrinkForOutOfText =
      assignment && assignment.grading_type === 'points' && assignment.points_possible != null
    const minWidth = shrinkForOutOfText ? 140 : 90
    const columnId = getAssignmentColumnId(assignment.id)
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

  buildAssignmentGroupColumn = (assignmentGroup: AssignmentGroup) => {
    let width
    const columnId = getAssignmentGroupColumnId(assignmentGroup.id)
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

  buildTotalGradeColumn = () => {
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

  initGrid = () => {
    let assignmentGroup, assignmentGroupColumn, id
    this.updateFilteredContentInfo()
    const studentColumn = this.buildStudentColumn(
      'student',
      this.gradebookColumnSizeSettings?.student,
      150
    )
    this.gridData.columns.definitions[studentColumn.id] = studentColumn
    this.gridData.columns.frozen.push(studentColumn.id)
    const studentColumnLastName = this.buildStudentColumn(
      'student_lastname',
      this.gradebookColumnSizeSettings?.student_lastname,
      155
    )
    this.gridData.columns.definitions[studentColumnLastName.id] = studentColumnLastName
    this.gridData.columns.frozen.push(studentColumnLastName.id)
    const studentColumnFirstName = this.buildStudentColumn(
      'student_firstname',
      this.gradebookColumnSizeSettings?.student_firstname,
      155
    )
    this.gridData.columns.definitions[studentColumnFirstName.id] = studentColumnFirstName
    this.gridData.columns.frozen.push(studentColumnFirstName.id)

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
    this.gradebookGrid.initialize()
    if (!this.gradebookGrid.gridSupport) throw new Error('grid did not initialize')
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
      getColumnTypeForColumnId: this.getColumnTypeForColumnId,
      toggleDefaultSort: this.toggleDefaultSort,
      openSubmissionTray: this.openSubmissionTray
    })
    this.gradebookGrid.gridSupport.initialize()
    this.gradebookGrid.gridSupport.events.onActiveLocationChanged.subscribe((event, location) => {
      if (
        ['student', 'student_lastname'].includes(location.columnId) &&
        location.region === 'body'
      ) {
        // In IE11, if we're navigating into the student column from a grade
        // input cell with no text, this focus() call will select the <body>
        // instead of the grades link.  Delaying the call (even with no actual
        // delay) fixes the issue.
        return setTimeout(() => {
          if (!this.gradebookGrid.gridSupport) throw new Error('grid is not initialized')
          const ref1 = this.gradebookGrid.gridSupport.state
            .getActiveNode()
            .querySelector('.student-grades-link')
          return ref1 != null ? ref1.focus() : undefined
        }, 0)
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
        return setTimeout(() => {
          let ref1
          return (ref1 = this.getHeaderComponentRef(location.columnId)) != null
            ? ref1.focusAtStart()
            : undefined
        }, 0)
      }
    })
    return this.onGridInit()
  }

  onGridInit = () => {
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
    this.keyboardNav?.init()
    const keyBindings = this.keyboardNav?.keyBindings
    this.kbDialog = new KeyboardNavDialog().render(KeyboardNavTemplate({keyBindings}))
    return $(document).trigger('gridready')
  }

  // The target cell will enter editing mode
  onBeforeEditCell = (_event, obj: {item: Student; column: GridColumn}) => {
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
  onCellChange = (_event, obj: {item: Student; column: GridColumn}) => {
    let col_id, url
    const {item, column} = obj
    if (column.type === 'custom_column' && column.field) {
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
  saveColumnWidthPreference = (id, newWidth) => {
    const url = this.options.gradebook_column_size_settings_url
    return $.ajaxJSON(url, 'POST', {
      column_id: id,
      column_size: newWidth
    })
  }

  saveSettings = ({
    selectedViewOptionsFilters = this.listSelectedViewOptionsFilters(),
    showConcludedEnrollments = this.getEnrollmentFilters().concluded,
    showInactiveEnrollments = this.getEnrollmentFilters().inactive,
    showUnpublishedAssignments = this.gridDisplaySettings.showUnpublishedAssignments,
    showSeparateFirstLastNames = this.gridDisplaySettings.showSeparateFirstLastNames,
    studentColumnDisplayAs = this.getSelectedPrimaryInfo(),
    studentColumnSecondaryInfo = this.getSelectedSecondaryInfo(),
    sortRowsBy = this.getSortRowsBySetting(),
    viewUngradedAsZero = this.gridDisplaySettings.viewUngradedAsZero,
    colors = this.state.gridColors
  } = {}) => {
    if (!(selectedViewOptionsFilters.length > 0)) {
      selectedViewOptionsFilters.push('')
    }
    const data = {
      gradebook_settings: {
        enter_grades_as: this.gridDisplaySettings.enterGradesAs,
        filter_columns_by: underscore(this.gridDisplaySettings.filterColumnsBy),
        selected_view_options_filters: selectedViewOptionsFilters,
        show_concluded_enrollments: showConcludedEnrollments ? 'true' : 'false',
        show_inactive_enrollments: showInactiveEnrollments ? 'true' : 'false',
        show_unpublished_assignments: showUnpublishedAssignments ? 'true' : 'false',
        show_separate_first_last_names: showSeparateFirstLastNames ? 'true' : 'false',
        student_column_display_as: studentColumnDisplayAs,
        student_column_secondary_info: studentColumnSecondaryInfo,
        filter_rows_by: underscore(this.gridDisplaySettings.filterRowsBy),
        sort_rows_by_column_id: sortRowsBy.columnId,
        sort_rows_by_setting_key: sortRowsBy.settingKey,
        sort_rows_by_direction: sortRowsBy.direction,
        view_ungraded_as_zero: viewUngradedAsZero ? 'true' : 'false',
        colors
      }
    }

    if (this.options.enhanced_gradebook_filters) {
      return GradebookApi.saveUserSettings(this.options.context_id, data.gradebook_settings)
    } else {
      return new Promise((resolve, reject) => {
        $.ajaxJSON(this.options.settings_update_url, 'PUT', data, resolve, reject)
      })
    }
  }

  // Grid Sorting Methods
  sortRowsBy = (sortFn: (row1: Student, row2: Student) => number) => {
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

  getColumnTypeForColumnId = (columnId: string) => {
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

  idSort(a, b, {asc = true}) {
    return NumberCompare(Number(a.id), Number(b.id), {
      descending: !asc
    })
  }

  secondaryAndTertiarySort = (a, b, {asc = true}) => {
    let result
    result = localeSort(a.sortable_name, b.sortable_name, {asc})
    if (result === 0) {
      result = this.idSort(a, b, {asc})
    }
    return result
  }

  gradeSort = (a, b, field: string, asc) => {
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
  sortRowsWithFunction = (fn: (row: Student) => boolean | number, {asc = true} = {}) => {
    return this.sortRowsBy((a, b) => {
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
      return this.secondaryAndTertiarySort(a, b, {asc})
    })
  }

  missingSort = (columnId: string) => {
    return this.sortRowsWithFunction(row => {
      let ref1
      return !!((ref1 = row[columnId]) != null ? ref1.missing : undefined)
    })
  }

  lateSort = columnId => {
    return this.sortRowsWithFunction(row => {
      return row[columnId].late
    })
  }

  sortByStudentColumn = (settingKey: string, direction: 'ascending' | 'descending') => {
    return this.sortRowsBy((a, b) => {
      let result
      const asc = direction === 'ascending'
      result = localeSort(a[settingKey], b[settingKey], {
        asc,
        nullsLast: true
      })
      if (result === 0) {
        result = this.idSort(a, b, {asc})
      }
      return result
    })
  }

  sortByCustomColumn = (columnId: string, direction: 'ascending' | 'descending') => {
    return this.sortRowsBy((a, b) => {
      let result
      const asc = direction === 'ascending'
      result = localeSort(a[columnId], b[columnId], {asc})
      if (result === 0) {
        result = this.secondaryAndTertiarySort(a, b, {asc})
      }
      return result
    })
  }

  sortByAssignmentColumn = (
    columnId: string,
    settingKey: string,
    direction: 'ascending' | 'descending'
  ) => {
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

  // when 'unposted' # TODO: in a future milestone, unposted will be added
  sortByAssignmentGroupColumn = (
    columnId: string,
    settingKey: string,
    direction: 'ascending' | 'descending'
  ) => {
    if (settingKey === 'grade') {
      return this.sortRowsBy((a, b) => {
        return this.gradeSort(a, b, columnId, direction === 'ascending')
      })
    }
  }

  sortByTotalGradeColumn = (direction: 'ascending' | 'descending') => {
    return this.sortRowsBy((a, b) => {
      return this.gradeSort(a, b, 'total_grade', direction === 'ascending')
    })
  }

  sortGridRows = () => {
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

  // Grid Update Methods
  updateStudentRow = student => {
    const index = this.gridData.rows.findIndex(row => {
      return row.id === student.id
    })
    if (index !== -1) {
      this.gridData.rows[index] = this.buildRow(student)
      return this.gradebookGrid.invalidateRow(index)
    }
  }

  // Filtered Content Information Methods
  updateFilteredContentInfo = () => {
    let invalidAssignmentGroups: AssignmentGroup[]
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

  listInvalidAssignmentGroups = () => {
    return this.filteredContentInfo.invalidAssignmentGroups
  }

  listHiddenAssignments = (studentId: string) => {
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

  getTotalPointsPossible = () => {
    return this.filteredContentInfo.totalPointsPossible
  }

  handleColumnHeaderMenuClose = () => {
    return this.keyboardNav?.handleMenuOrDialogClose()
  }

  toggleNotesColumn = () => {
    const parentColumnIds = this.gridData.columns.frozen.filter(function (columnId) {
      return !/^custom_col_/.test(columnId)
    })
    const customColumnIds = this.listVisibleCustomColumns().map(column => {
      return getCustomColumnId(column.id)
    })
    this.gridData.columns.frozen = [...parentColumnIds, ...customColumnIds]
    return this.updateGrid()
  }

  showNotesColumn = () => {
    let ref1
    if (this.teacherNotesNotYetLoaded) {
      this.teacherNotesNotYetLoaded = false
      const notesColumn = this.getTeacherNotesColumn()
      if (!notesColumn) throw new Error('error loading notes column')
      this.dataLoader.loadCustomColumnData(notesColumn.id)
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
    return this.toggleNotesColumn()
  }

  hideAggregateColumns = () => {
    if (this.gradingPeriodSet == null) {
      return false
    }
    if (this.gradingPeriodSet.displayTotalsForAllGradingPeriods) {
      return false
    }
    return !this.isFilteringColumnsByGradingPeriod()
  }

  // SlickGrid Data Access Methods
  listRows = () => {
    return this.gridData.rows // currently the source of truth for filtered and sorted rows
  }

  listRowIndicesForStudentIds = studentIds => {
    const rowIndicesByStudentId = this.listRows().reduce((map, row, index) => {
      map[row.id] = index
      return map
    }, {})
    return studentIds.map(studentId => {
      return rowIndicesByStudentId[studentId]
    })
  }

  // SlickGrid Update Methods
  updateRowCellsForStudentIds = studentIds => {
    let columnIndex, j, k, len, len1, rowIndex
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
        this.gradebookGrid.grid.updateCell(rowIndex, columnIndex)
      }
    }
    return null // skip building an unused array return value
  }

  invalidateRowsForStudentIds = studentIds => {
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

  updateTotalGradeColumn = () => {
    this.updateColumnWithId('total_grade')
  }

  updateAllTotalColumns = () => {
    this.updateTotalGradeColumn()

    Object.keys(this.assignmentGroups).forEach(assignmentGroupId => {
      this.updateColumnWithId(`assignment_group_${assignmentGroupId}`)
    })
  }

  updateColumnWithId = (id: string) => {
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

  // Gradebook Bulk UI Update Methods
  updateColumns = () => {
    this.setVisibleGridColumns()
    this.gradebookGrid.updateColumns()
    return this.updateColumnHeaders()
  }

  updateColumnsAndRenderViewOptionsMenu = () => {
    this.updateColumns()
    return this.renderViewOptionsMenu()
  }

  updateColumnsAndRenderGradebookSettingsModal = () => {
    this.updateColumns()
    return this.renderGradebookSettingsModal()
  }

  // React Header Component Ref Methods
  setHeaderComponentRef = (columnId, ref) => {
    return (this.headerComponentRefs[columnId] = ref)
  }

  getHeaderComponentRef = (columnId: string) => {
    return this.headerComponentRefs[columnId]
  }

  removeHeaderComponentRef = (columnId: string) => {
    return delete this.headerComponentRefs[columnId]
  }

  // React Grid Component Rendering Methods
  updateColumnHeaders = (columnIds: string[] = []) => {
    const ref1 = this.gradebookGrid.gridSupport
    return ref1 != null ? ref1.columns.updateColumnHeaders(columnIds) : undefined
  }

  updateStudentColumnHeaders = () => {
    const columnIds: string[] = this.gridDisplaySettings.showSeparateFirstLastNames
      ? ['student_lastname', 'student_firstname']
      : ['student']
    return this.updateColumnHeaders(columnIds)
  }

  // Column Header Helpers
  handleHeaderKeyDown = (e, columnId: string) => {
    this.gradebookGrid.gridSupport?.navigation.handleHeaderKeyDown(e, {
      region: 'header',
      cell: this.gradebookGrid.grid.getColumnIndex(columnId),
      columnId
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
    this.gradebookGrid.gridSupport?.columns.scrollToStart()
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
    if (this.getColumnOrder().sortType === 'custom') {
      this.saveCustomColumnOrder()
    } else {
      this.saveColumnOrder()
    }
    this.updateGrid()
    this.updateColumnHeaders()
    return this.gradebookGrid.gridSupport?.columns.scrollToEnd()
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
  assignmentColumns = () => {
    if (!this.gradebookGrid.gridSupport) throw new Error('grid not initialized')
    return this.gradebookGrid.gridSupport.grid.getColumns().filter(column => {
      return column.type === 'assignment'
    })
  }

  navigateAssignment = (direction = 'next') => {
    if (!this.gradebookGrid?.gridSupport) throw new Error('grid not initialized')
    let assignment, curAssignment, i, ref1, ref3
    const location = this.gradebookGrid.gridSupport.state.getActiveLocation()
    const columns: GridColumn[] = this.gradebookGrid.grid.getColumns()
    const range =
      direction === 'next'
        ? function () {
            const results: GridColumn[] = []
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
          cell: i
        })
        assignment = curAssignment
        break
      }
    }
    return assignment
  }

  loadTrayStudent = direction => {
    if (!this.gradebookGrid.gridSupport) throw new Error('grid is not initialized')
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

  loadTrayAssignment = direction => {
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

  getSubmissionTrayProps = (student: null | Student = null) => {
    if (!this.gradebookGrid.gridSupport) throw new Error('grid is not initialized')
    const {open, studentId, assignmentId, comments, editedCommentId} = this.getSubmissionTrayState()
    if (!studentId) {
      throw new Error('studentId missing')
    }
    if (!student) {
      student = this.student(studentId)
    }
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
    if (!assignmentId) {
      throw new Error('assignmentId missing')
    }
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
      colors: this.state.gridColors,
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
        return this.gradebookGrid.gridSupport?.helper.focus()
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

  renderSubmissionTray = (student: Student | null = null) => {
    const {open, studentId, assignmentId} = this.getSubmissionTrayState()
    if (!assignmentId) throw new Error('assignmentId missing')
    if (!studentId) throw new Error('studentId missing')
    const mountPoint = document.getElementById('StudentTray__Container')
    const props = this.getSubmissionTrayProps(student)
    if (!this.getSubmissionCommentsLoaded() && open) {
      this.loadSubmissionComments(assignmentId, studentId)
    }
    return AsyncComponents.renderGradeDetailTray(props, mountPoint)
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
    return this.updateRowAndRenderSubmissionTray(studentId)
  }

  closeSubmissionTray = () => {
    this.setSubmissionTrayState(false)
    const rowIndex = this.gradebookGrid.grid.getActiveCell().row
    const studentId = this.gridData.rows[rowIndex].id
    this.updateRowAndRenderSubmissionTray(studentId)
    return this.gradebookGrid.gridSupport?.helper.beginEdit()
  }

  getSubmissionTrayState = () => {
    return this.gridDisplaySettings.submissionTray
  }

  setSubmissionTrayState = (
    open,
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
      return this.gradebookGrid.gridSupport?.helper.commitCurrentEdit()
    }
  }

  setCommentsUpdating = status => {
    return (this.gridDisplaySettings.submissionTray.commentsUpdating = !!status)
  }

  getCommentsUpdating = () => {
    return this.gridDisplaySettings.submissionTray.commentsUpdating
  }

  setSubmissionComments = comments => {
    return (this.gridDisplaySettings.submissionTray.comments = comments)
  }

  updateSubmissionComments = comments => {
    this.setSubmissionComments(comments)
    this.setEditedCommentId(null)
    this.setCommentsUpdating(false)
    this.renderSubmissionTray()
  }

  unloadSubmissionComments = () => {
    this.setSubmissionComments([])
    return this.setSubmissionCommentsLoaded(false)
  }

  apiCreateSubmissionComment = comment => {
    const {assignmentId, studentId} = this.getSubmissionTrayState()
    if (!assignmentId) throw new Error('assignmentId missing')
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

  apiUpdateSubmissionComment = (updatedComment, commentId) => {
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

  editSubmissionComment = (commentId: string) => {
    this.setEditedCommentId(commentId)
    return this.renderSubmissionTray()
  }

  setEditedCommentId = (id: string | null) => {
    return (this.gridDisplaySettings.submissionTray.editedCommentId = id)
  }

  getSubmissionComments = () => {
    return this.gridDisplaySettings.submissionTray.comments
  }

  removeSubmissionComment = (commentId: string) => {
    const comments = _.reject(this.getSubmissionComments(), c => {
      return c.id === commentId
    })
    return this.updateSubmissionComments(comments)
  }

  setSubmissionCommentsLoaded = loaded => {
    return (this.gridDisplaySettings.submissionTray.commentsLoaded = loaded)
  }

  getSubmissionCommentsLoaded = () => {
    return this.gridDisplaySettings.submissionTray.commentsLoaded
  }

  initShowUnpublishedAssignments = (showUnpublishedAssignments = 'true') => {
    return (this.gridDisplaySettings.showUnpublishedAssignments =
      showUnpublishedAssignments === 'true')
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
      showUnpublishedAssignments: this.gridDisplaySettings.showUnpublishedAssignments
    }).catch(toggleableAction)
  }

  // Gradebook Application State Methods
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
      showSeparateFirstLastNames: this.gridDisplaySettings.showSeparateFirstLastNames
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
      viewUngradedAsZero: this.gridDisplaySettings.viewUngradedAsZero
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

  setAssignmentsLoaded = (gradingPeriodIds: string[]) => {
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
    return (this.contentLoadStates.assignmentGroupsLoaded = loaded)
  }

  setCustomColumnsLoaded = (loaded: boolean) => {
    return (this.contentLoadStates.customColumnsLoaded = loaded)
  }

  setGradingPeriodAssignmentsLoaded = (loaded: boolean) => {
    return (this.contentLoadStates.gradingPeriodAssignmentsLoaded = loaded)
  }

  setStudentIdsLoaded = (loaded: boolean) => {
    return (this.contentLoadStates.studentIdsLoaded = loaded)
  }

  setStudentsLoaded = (loaded: boolean) => {
    return (this.contentLoadStates.studentsLoaded = loaded)
  }

  setSubmissionsLoaded = (loaded: boolean) => {
    return (this.contentLoadStates.submissionsLoaded = loaded)
  }

  isGradeEditable = (studentId: string, assignmentId: string) => {
    if (!this.isStudentGradeable(studentId)) {
      return false
    }
    const submissionState = this.submissionStateMap.getSubmissionState({
      assignment_id: assignmentId,
      user_id: studentId
    })
    return submissionState != null && !submissionState.locked
  }

  isGradeVisible = (studentId: string, assignmentId: string) => {
    const submissionState = this.submissionStateMap.getSubmissionState({
      assignment_id: assignmentId,
      user_id: studentId
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

  addPendingGradeInfo = (submission, gradeInfo) => {
    if (!this.actionStates) throw new Error('actionStates not initialized')
    const {userId, assignmentId} = submission
    const pendingGradeInfo = {assignmentId, userId, ...gradeInfo}
    this.removePendingGradeInfo(submission)
    this.actionStates.pendingGradeInfo.push(pendingGradeInfo)
  }

  removePendingGradeInfo = submission => {
    if (!this.actionStates) throw new Error('actionStates missing')
    this.actionStates.pendingGradeInfo = _.reject(
      this.actionStates.pendingGradeInfo,
      function (info) {
        return info.userId === submission.userId && info.assignmentId === submission.assignmentId
      }
    )
    return this.actionStates.pendingGradeInfo
  }

  getPendingGradeInfo = submission => {
    if (!this.actionStates) throw new Error('actionStates missing')
    return (
      this.actionStates.pendingGradeInfo.find(function (info) {
        return info.userId === submission.userId && info.assignmentId === submission.assignmentId
      }) || null
    )
  }

  submissionIsUpdating = submission => {
    const ref1 = this.getPendingGradeInfo(submission)
    return Boolean(ref1 != null ? ref1.valid : undefined)
  }

  setTeacherNotesColumnUpdating = (updating: boolean) => {
    return (this.contentLoadStates.teacherNotesColumnUpdating = updating)
  }

  // Grid Display Settings Access Methods
  getFilterColumnsBySetting = filterKey => {
    return this.gridDisplaySettings?.filterColumnsBy[filterKey]
  }

  // Grid Display Settings Access Methods
  setFilterColumnsBySetting = (filterKey: string, value: null | string) => {
    return (this.gridDisplaySettings.filterColumnsBy[filterKey] = value)
  }

  getFilterRowsBySetting = (filterKey: string) => {
    return this.gridDisplaySettings.filterRowsBy[filterKey]
  }

  setFilterRowsBySetting = (filterKey: string, value: null | string) => {
    return (this.gridDisplaySettings.filterRowsBy[filterKey] = value)
  }

  isFilteringColumnsByAssignmentGroup = () => {
    return this.getAssignmentGroupToShow() !== '0'
  }

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

  getAssignmentGroupToShow = () => {
    const groupId = this.getFilterColumnsBySetting('assignmentGroupId') || '0'
    if (_.pluck(this.assignmentGroups, 'id').indexOf(groupId) >= 0) {
      return groupId
    } else {
      return '0'
    }
  }

  isFilteringColumnsByGradingPeriod = () => {
    return this.gradingPeriodId !== '0'
  }

  isFilteringRowsBySearchTerm = () => {
    if (this.options.gradebook_assignment_search_and_redesign) {
      return this.filteredStudentIds != null && this.filteredStudentIds.length > 0
    }

    return this.userFilterTerm != null && this.userFilterTerm !== ''
  }

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

  getCurrentGradingPeriod = () => {
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

  setSelectedPrimaryInfo = (primaryInfo: string, skipRedraw: boolean) => {
    this.gridDisplaySettings.selectedPrimaryInfo = primaryInfo
    this.saveSettings()
    if (!skipRedraw) {
      this.buildRows()
      return this.updateStudentColumnHeaders()
    }
  }

  toggleDefaultSort = (columnId: string) => {
    let direction
    const sortSettings = this.getSortRowsBySetting()
    const columnType = this.getColumnTypeForColumnId(columnId)
    const settingKey = getDefaultSettingKeyForColumnType(columnType)
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

  getSelectedPrimaryInfo = () => {
    return this.gridDisplaySettings.selectedPrimaryInfo
  }

  setSelectedSecondaryInfo = (secondaryInfo: string, skipRedraw: boolean) => {
    this.gridDisplaySettings.selectedSecondaryInfo = secondaryInfo
    this.saveSettings()
    if (!skipRedraw) {
      this.buildRows()
      return this.updateStudentColumnHeaders()
    }
  }

  getSelectedSecondaryInfo = () => {
    return this.gridDisplaySettings.selectedSecondaryInfo
  }

  setSortRowsBySetting = (columnId: string, settingKey, direction) => {
    this.gridDisplaySettings.sortRowsBy.columnId = columnId
    this.gridDisplaySettings.sortRowsBy.settingKey = settingKey
    this.gridDisplaySettings.sortRowsBy.direction = direction
    this.saveSettings()
    return this.sortGridRows()
  }

  getSortRowsBySetting = () => {
    return this.gridDisplaySettings.sortRowsBy
  }

  updateGridColors = (colors: StatusColors, successFn, errorFn) => {
    const setAndRenderColors = () => {
      this.gridDisplaySettings.colors = colors
      this.setState({gridColors: statusColors(this.gridDisplaySettings.colors)})
      return successFn()
    }
    return this.saveSettings({colors}).then(setAndRenderColors).catch(errorFn)
  }

  listAvailableViewOptionsFilters = () => {
    const filters: string[] = []
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

  setSelectedViewOptionsFilters = filters => {
    return (this.gridDisplaySettings.selectedViewOptionsFilters = filters)
  }

  listSelectedViewOptionsFilters = () => {
    return this.gridDisplaySettings.selectedViewOptionsFilters
  }

  toggleEnrollmentFilter = (enrollmentFilter, skipApply = false) => {
    this.getEnrollmentFilters()[enrollmentFilter] = !this.getEnrollmentFilters()[enrollmentFilter]
    if (!skipApply) {
      return this.applyEnrollmentFilter()
    }
  }

  updateStudentHeadersAndReloadData = () => {
    this.updateStudentColumnHeaders()
    return this.dataLoader.reloadStudentDataForEnrollmentFilterChange()
  }

  applyEnrollmentFilter = () => {
    const showInactiveEnrollments = this.getEnrollmentFilters().inactive
    const showConcludedEnrollments = this.getEnrollmentFilters().concluded
    return this.saveSettings({showInactiveEnrollments, showConcludedEnrollments}).then(
      this.updateStudentHeadersAndReloadData
    )
  }

  getEnrollmentFilters = () => {
    return this.gridDisplaySettings.showEnrollments
  }

  getSelectedEnrollmentFilters = () => {
    const filters = this.getEnrollmentFilters()
    const selectedFilters: string[] = []
    for (const filter in filters) {
      if (filters[filter]) {
        selectedFilters.push(filter)
      }
    }
    return selectedFilters
  }

  setEnterGradesAsSetting = (assignmentId: string, setting) => {
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

  updateEnterGradesAsSetting = (assignmentId: string, value) => {
    this.setEnterGradesAsSetting(assignmentId, value)
    return this.saveSettings({}).then(() => {
      if (!this.gradebookGrid.gridSupport) {
        throw new Error('grid not initialized')
      }
      this.gradebookGrid.gridSupport.columns.updateColumnHeaders([
        getAssignmentColumnId(assignmentId)
      ])
      return this.gradebookGrid.invalidate()
    })
  }

  postAssignmentGradesTrayOpenChanged = ({assignmentId, isOpen}) => {
    const columnId = getAssignmentColumnId(assignmentId)
    const definition = this.gridData.columns.definitions[columnId]
    if (!(definition && definition.type === 'assignment')) {
      return
    }
    definition.postAssignmentGradesTrayOpenForAssignmentId = isOpen
    return this.updateGrid()
  }

  // # Course Settings Access Methods
  getCourseGradingScheme = () => {
    return this.courseContent.courseGradingScheme
  }

  getDefaultGradingScheme = () => {
    return this.courseContent.defaultGradingScheme
  }

  getGradingScheme = (gradingSchemeId: string | null) => {
    return this.courseContent.gradingSchemes.find(scheme => {
      return scheme.id === gradingSchemeId
    })
  }

  getAssignmentGradingScheme = (assignmentId: string) => {
    const assignment = this.getAssignment(assignmentId)
    return this.getGradingScheme(assignment.grading_standard_id) || this.getDefaultGradingScheme()
  }

  // Gradebook Content Access Methods
  getSections = () => {
    return Object.values(this.sections)
  }

  setSections = (sections: Section[]) => {
    this.sections = _.indexBy(sections, 'id')
    return (this.sections_enabled = sections.length > 1)
  }

  setStudentGroups = (groupCategories: StudentGroupCategoryMap) => {
    this.studentGroupCategories = _.indexBy(groupCategories, 'id')
    const studentGroupList: StudentGroup[] = _.flatten(_.pluck(groupCategories, 'groups')).map(
      htmlEscape
    )
    this.studentGroups = _.indexBy(studentGroupList, 'id')
    return (this.studentGroupsEnabled = studentGroupList.length > 0)
  }

  setAssignments = assignmentMap => {
    return (this.assignments = assignmentMap)
  }

  setAssignmentGroups = assignmentGroupMap => {
    return (this.assignmentGroups = assignmentGroupMap)
  }

  getAssignment = (assignmentId: string): Assignment => {
    return this.assignments[assignmentId]
  }

  getAssignmentGroup = (assignmentGroupId: string) => {
    return this.assignmentGroups[assignmentGroupId]
  }

  getCustomColumn = (customColumnId: string) => {
    return this.gradebookContent.customColumns.find(function (column) {
      return column.id === customColumnId
    })
  }

  getTeacherNotesColumn = () => {
    return this.gradebookContent.customColumns.find(function (column) {
      return column.teacher_notes
    })
  }

  isTeacherNotesColumnShown = () => {
    const column = this.getTeacherNotesColumn()
    return column != null && !column.hidden
  }

  listVisibleCustomColumns = () => {
    return (
      this.gradebookContent.customColumns.filter(function (column) {
        return !column.hidden
      }) || []
    )
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

  onLatePolicyUpdate = latePolicy => {
    this.setLatePolicy(latePolicy)
    return this.applyLatePolicy()
  }

  setLatePolicy = latePolicy => {
    this.courseContent.latePolicy = latePolicy
  }

  applyLatePolicy = () => {
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

  getContextModule = (contextModuleId: string) => {
    let ref1
    if (contextModuleId != null) {
      return (ref1 = this.courseContent.modulesById) != null ? ref1[contextModuleId] : undefined
    }
  }

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
      onSelect: manager.showDialog
    }
  }

  getReuploadSubmissionsAction = (assignmentId: string) => {
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

  getSetDefaultGradeAction = (assignmentId: string) => {
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

  getCurveGradesAction = (assignmentId: string) => {
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

  // Gradebook Content Api Methods
  createTeacherNotes = () => {
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

  setTeacherNotesHidden = (hidden: boolean) => {
    this.setTeacherNotesColumnUpdating(true)
    this.renderViewOptionsMenu()
    const teacherNotes = this.getTeacherNotesColumn()
    if (!teacherNotes) throw new Error('teacherNotes missing')
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

  apiUpdateSubmission(submission, gradeInfo, enterGradesAs) {
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

  gradeSubmission = (submission, gradeInfo) => {
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
        type: 'error',
        err: undefined
      })
      this.addPendingGradeInfo(submission, gradeInfo)
      this.updateRowCellsForStudentIds([submission.userId])
      if (this.getSubmissionTrayState().open) {
        return this.renderSubmissionTray()
      }
    }
  }

  updateSubmissionAndRenderSubmissionTray = data => {
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

  renderAnonymousSpeedGraderAlert = props => {
    return renderComponent(AnonymousSpeedGraderAlert, anonymousSpeedGraderAlertMountPoint(), props)
  }

  showAnonymousSpeedGraderAlertForURL = (speedGraderUrl: string) => {
    const props = {
      speedGraderUrl,
      onClose: this.hideAnonymousSpeedGraderAlert
    }
    this.anonymousSpeedGraderAlert = this.renderAnonymousSpeedGraderAlert(props)
    return this.anonymousSpeedGraderAlert.open()
  }

  hideAnonymousSpeedGraderAlert = () => {
    // React throws an error if we try to unmount while the event is being handled
    return setTimeout(() => {
      const node = anonymousSpeedGraderAlertMountPoint()
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

  showSimilarityScore = _assignment => {
    return !!this.options.show_similarity_score
  }

  viewUngradedAsZero = () => {
    return !!(
      this.courseFeatures.allowViewUngradedAsZero && this.gridDisplaySettings.viewUngradedAsZero
    )
  }

  allowApplyScoreToUngraded = () => {
    return this.options.allow_apply_score_to_ungraded
  }

  onApplyScoreToUngradedRequested = assignmentGroup => {
    const mountPoint = this.props.applyScoreToUngradedModalNode
    if (!this.allowApplyScoreToUngraded() || mountPoint == null) {
      return null
    }

    const close = () => {
      ReactDOM.unmountComponentAtNode(mountPoint)
    }

    const props = {
      assignmentGroup,
      onApply: args => {
        this.executeApplyScoreToUngraded(args)
        close()
      },
      onClose: close,
      open: true
    }

    renderComponent(ApplyScoreToUngradedModal, mountPoint, props)
  }

  refreshScoreToUngradedColumnHeaders() {
    const columnIds = Object.keys(this.assignmentGroups).map(
      assignmentGroupId => `assignment_group_${assignmentGroupId}`
    )
    columnIds.push('total_grade')
    this.gradebookGrid.gridSupport?.columns.updateColumnHeaders(columnIds)
  }

  executeApplyScoreToUngraded = args => {
    const {value, ...options} = args

    // TODO: if updated Gradebook filters are enabled, we should use those
    // instead, either by replacing the lines below with checks against the
    // current filters or by passing the ID of the active filter (and looking up
    // the contents of the filter on the back-end)
    const optionsWithFilters = {
      ...options,
      courseSectionId: this.getFilterRowsBySetting('sectionId'),
      gradingPeriodId: this.getFilterColumnsBySetting('gradingPeriodId'),
      moduleId: this.getFilterColumnsBySetting('contextModuleId'),
      studentGroupId: this.getFilterRowsBySetting('studentGroupId')
    }

    if (value === 'excused') {
      optionsWithFilters.excuse = true
    } else {
      optionsWithFilters.percent = value
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
        this.scoreToUngradedManager!.startProcess(this.options.context_id, optionsWithFilters)
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

  destroy = () => {
    $(window).unbind('resize.fillWindowWithMe')
    $(document).unbind('gridready')
    this.gradebookGrid.destroy()
    this.scoreToUngradedManager?.clearMonitor()
    return this.postPolicies?.destroy()
  }

  // "PRIVILEGED" methods
  // The methods here are intended to support specs, but not intended to be a
  // permanent part of the API for this class. The existence of these methods
  // suggests that the behavior they provide does not yet have a more suitable
  // home elsewhere in the code. They are prefixed with '_' to suggest this
  // aspect of their presence here.
  _gridHasRendered = () => {
    return this.gridReady.state() === 'resolved'
  }

  _updateEssentialDataLoaded = () => {
    if (
      this.contentLoadStates.studentIdsLoaded &&
      !this.props.isModulesLoading &&
      this.contentLoadStates.customColumnsLoaded &&
      this.contentLoadStates.assignmentGroupsLoaded &&
      this.assignmentsLoadedForCurrentView() &&
      (!this.gradingPeriodSet || this.contentLoadStates.gradingPeriodAssignmentsLoaded)
    ) {
      this.setState({isEssentialDataLoaded: true})
      return this._essentialDataLoaded.resolve()
    }
  }

  componentDidMount() {
    this.initialize()
    this.onShow()
  }

  componentDidUpdate(prevProps) {
    // Here we keep track of data loading states
    //   and filter changes until we use hooks
    if (
      prevProps.isModulesLoading !== this.props.isModulesLoading &&
      !this.props.isModulesLoading
    ) {
      this.updateContextModules(this.props.modules)
    }

    const didAppliedFilterValuesChange =
      getAllAppliedFilterValues(prevProps.filters).join(',') !==
      getAllAppliedFilterValues(this.props.filters).join(',')
    if (didAppliedFilterValuesChange) {
      const prevSectionIds = findAllAppliedFilterValuesOfType('section', prevProps.filters)
      const sectionIds = findAllAppliedFilterValuesOfType('section', this.props.filters)
      if (prevSectionIds[0] !== sectionIds[0]) {
        if (sectionIds.length === 0) {
          this.updateCurrentSection(null)
        } else {
          this.updateCurrentSection(sectionIds[0] || null)
        }
      }

      const prevGradingPeriodId = findAllAppliedFilterValuesOfType(
        'grading-period',
        prevProps.filters
      )[0]
      const gradingPeriodId = findAllAppliedFilterValuesOfType(
        'grading-period',
        this.props.filters
      )[0]
      if (prevGradingPeriodId !== gradingPeriodId) {
        if (!gradingPeriodId) {
          this.updateCurrentGradingPeriod(null)
        } else {
          this.updateCurrentGradingPeriod(gradingPeriodId)
        }
      }
      this.updateColumns()
    }
  }

  render() {
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
        <Portal node={this.props.settingsModalButtonContainer}>
          <Button
            renderIcon={IconSettingsSolid}
            ref={this.gradebookSettingsModalButton}
            id="gradebook-settings-button"
            variant="icon"
            onClick={() => this.gradebookSettingsModal?.current?.open()}
          >
            <ScreenReaderContent>{I18n.t('Gradebook Settings')}</ScreenReaderContent>
          </Button>
        </Portal>
        <Portal node={this.props.gradebookMenuNode}>
          <GradebookMenu
            courseUrl={this.options.context_url}
            learningMasteryEnabled={this.options.outcome_gradebook_enabled}
            variant="DefaultGradebook"
          />
        </Portal>
        <Portal node={this.props.gridColorNode}>
          <GridColor colors={this.state.gridColors} />
        </Portal>
        {this.options.enhanced_gradebook_filters &&
          !this.props.isFiltersLoading &&
          this.state.isEssentialDataLoaded && (
            <Portal node={this.props.filterNavNode}>
              <FilterNav
                gradingPeriods={this.gradingPeriodSet?.gradingPeriods || []}
                modules={this.state.modules}
                assignmentGroups={this.state.assignmentGroups}
                sections={this.state.sections}
              />
            </Portal>
          )}
      </>
    )
  }
}

export default Gradebook
