/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {chain, difference, forEach, isEmpty, isEqual, keyBy, map, reduce, union} from 'lodash'
import _ from 'underscore'
import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import DueDateRow from './DueDateRow'
import DueDateAddRowButton from './DueDateAddRowButton'
import OverrideStudentStore from './OverrideStudentStore'
import StudentGroupStore from './StudentGroupStore'
import TokenActions from './TokenActions'
import Override from '@canvas/assignments/backbone/models/AssignmentOverride'
import AssignmentOverrideHelper from '../AssignmentOverrideHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import GradingPeriodsHelper from '@canvas/grading/GradingPeriodsHelper'
import {Checkbox} from '@instructure/ui-checkbox'
import '@canvas/rails-flash-notifications'
import {
  sortedRowKeys,
  rowsFromOverrides,
  getAllOverrides,
  datesFromOverride,
} from '../util/overridesUtils'

const I18n = useI18nScope('due_datesDueDates')

export default class DueDates extends React.Component {
  static propTypes = {
    overrides: PropTypes.array.isRequired,
    syncWithBackbone: PropTypes.func.isRequired,
    sections: PropTypes.array.isRequired,
    defaultSectionId: PropTypes.string.isRequired,
    hasGradingPeriods: PropTypes.bool.isRequired,
    gradingPeriods: PropTypes.array.isRequired,
    isOnlyVisibleToOverrides: PropTypes.bool.isRequired,
    dueAt(props) {
      const isDate = props.dueAt instanceof Date
      if (!isDate && props.dueAt !== null) {
        return new Error('Invalid prop `dueAt` supplied to `DueDates`. Validation failed.')
      }
    },
    dueDatesReadonly: PropTypes.bool,
    availabilityDatesReadonly: PropTypes.bool,
    importantDates: PropTypes.bool,
    selectedGroupSetId: PropTypes.string,
    defaultDueTime: PropTypes.string,
  }

  static defaultProps = {
    dueDatesReadonly: false,
    availabilityDatesReadonly: false,
  }

  // -------------------
  //      Lifecycle
  // -------------------

  state = {
    students: {},
    sections: {},
    noops: {[Override.conditionalRelease.noop_id]: Override.conditionalRelease},
    rows: {},
    addedRowCount: 0,
    currentlySearching: false,
    allStudentsFetched: false,
    selectedGroupSetId: null,
    importantDates: false,
  }

  componentDidMount() {
    this.setState(
      {
        rows: rowsFromOverrides(this.props.overrides),
        sections: this.formattedSectionHash(this.props.sections),
        groups: {},
        selectedGroupSetId: this.props.selectedGroupSetId,
        importantDates: this.props.importantDates,
      },
      this.fetchAdhocStudents
    )

    OverrideStudentStore.addChangeListener(this.handleStudentStoreChange)

    StudentGroupStore.setGroupSetIfNone(this.props.selectedGroupSetId)
    StudentGroupStore.addChangeListener(this.handleStudentGroupStoreChange)
    StudentGroupStore.fetchGroupsForCourse()
  }

  componentWillUnmount() {
    OverrideStudentStore.removeChangeListener(this.handleStudentStoreChange)
    StudentGroupStore.removeChangeListener(this.handleStudentGroupStoreChange)
  }

  fetchAdhocStudents = () => {
    OverrideStudentStore.fetchStudentsByID(this.adhocOverrideStudentIDs())
  }

  handleStudentStoreChange = () => {
    this.setState({
      students: OverrideStudentStore.getStudents(),
      currentlySearching: OverrideStudentStore.currentlySearching(),
      allStudentsFetched: OverrideStudentStore.allStudentsFetched(),
    })
  }

  handleStudentGroupStoreChange = () => {
    this.setState({
      groups: this.formattedGroupHash(StudentGroupStore.getGroups()),
      selectedGroupSetId: StudentGroupStore.getSelectedGroupSetId(),
    })
  }

  // always keep React Overrides in sync with Backbone Collection
  UNSAFE_componentWillUpdate(nextProps, nextState) {
    const updatedOverrides = getAllOverrides(nextState.rows)
    this.props.syncWithBackbone(updatedOverrides, nextState.importantDates)
  }

  // --------------------------
  //        State Change
  // --------------------------

  replaceRow = (rowKey, overrides, rowDates) => {
    const dates = rowDates || datesFromOverride(overrides[0])
    this.setState(oldState => ({
      rows: {...oldState.rows, [rowKey]: {overrides, dates, persisted: false}},
    }))
  }

  // -------------------
  //       Helpers
  // -------------------

  formattedSectionHash = unformattedSections => {
    const formattedSections = map(unformattedSections, this.formatSection)
    return keyBy(formattedSections, 'id')
  }

  formatSection = section => ({...section.attributes, course_section_id: section.id})

  formattedGroupHash = unformattedGroups => {
    const formattedGroups = map(unformattedGroups, this.formatGroup)
    return keyBy(formattedGroups, 'id')
  }

  formatGroup = group => ({...group, group_id: group.id})

  adhocOverrides = () => _.filter(getAllOverrides(this.state.rows), ov => ov.get('student_ids'))

  adhocOverrideStudentIDs = () =>
    chain(this.adhocOverrides())
      .map(ov => ov.get('student_ids'))
      .flatten()
      .uniq()
      .value()

  groupsForSelectedSet = () => {
    const allGroups = this.state.groups
    const setId = this.state.selectedGroupSetId
    return chain(allGroups)
      .filter(value => value.group_category_id === setId)
      .keyBy('id')
      .value()
  }

  // -------------------
  //      Row Setup
  // -------------------

  rowRef = rowKey => `due_date_row-${rowKey}`

  // ------------------------
  // Adding and Removing Rows
  // ------------------------

  addRow = () => {
    const newRowCount = this.state.addedRowCount + 1
    this.replaceRow(newRowCount, [], {})
    this.setState({addedRowCount: newRowCount}, function () {
      this.focusRow(newRowCount)
    })
  }

  removeRow = rowToRemoveKey => {
    if (!this.canRemoveRow()) return

    const previousIndex = _.indexOf(sortedRowKeys(this.state.rows), rowToRemoveKey)
    const newRows = _.omit(this.state.rows, rowToRemoveKey)
    this.setState({rows: newRows}, function () {
      const ks = sortedRowKeys(this.state.rows)
      const previousRowKey = ks[previousIndex] || ks[ks.length - 1]
      this.focusRow(previousRowKey)
    })
  }

  canRemoveRow = () => sortedRowKeys(this.state.rows).length > 1

  focusRow = rowKey => {
    ReactDOM.findDOMNode(this.refs[this.rowRef(rowKey)]).querySelector('input').focus()
  }

  // --------------------------
  // Adding and Removing Tokens
  // --------------------------

  changeRowToken = (addOrRemoveFunction, rowKey, changedToken) => {
    if (!changedToken) return
    const row = this.state.rows[rowKey]
    const newOverridesForRow = addOrRemoveFunction.call(
      TokenActions,
      changedToken,
      row.overrides,
      rowKey,
      row.dates
    )

    this.replaceRow(rowKey, newOverridesForRow, row.dates)
  }

  handleInteractionStart = () => {
    OverrideStudentStore.fetchStudentsForCourse()
  }

  handleTokenAdd = (rowKey, newToken) => {
    this.changeRowToken(TokenActions.handleTokenAdd, rowKey, newToken)
  }

  handleTokenRemove = (rowKey, tokenToRemove) => {
    this.changeRowToken(TokenActions.handleTokenRemove, rowKey, tokenToRemove)
  }

  replaceDate = (rowKey, dateType, newDate) => {
    const oldOverrides = this.state.rows[rowKey].overrides
    const oldDates = this.state.rows[rowKey].dates

    const newOverrides = map(oldOverrides, override => {
      override.set(dateType, newDate)
      return override
    })

    const newDates = {...oldDates, [dateType]: newDate}

    this.replaceRow(rowKey, newOverrides, newDates)
  }

  // --------------------------
  //  Everyone v Everyone Else
  // --------------------------

  defaultSectionNamer = sectionID => {
    if (sectionID !== this.props.defaultSectionId) return null

    const onlyDefaultSectionChosen = isEqual(this.chosenSectionIds(), [sectionID])
    const noSectionsChosen = isEmpty(this.chosenSectionIds())

    const noGroupsChosen = isEmpty(this.chosenGroupIds())
    const noStudentsChosen = isEmpty(this.chosenStudentIds())

    const defaultSectionOrNoSectionChosen = onlyDefaultSectionChosen || noSectionsChosen

    if (defaultSectionOrNoSectionChosen && noStudentsChosen && noGroupsChosen) {
      return I18n.t('Everyone')
    }
    return I18n.t('Everyone Else')
  }

  addStudentIfInClosedPeriod = (gradingPeriodsHelper, students, dueDate, studentID) => {
    const student = this.state.students[studentID]

    if (student && gradingPeriodsHelper.isDateInClosedGradingPeriod(dueDate)) {
      students = students.concat(student)
    }

    return students
  }

  studentsInClosedPeriods = () => {
    const allStudents = Object.values(this.state.students || {})
    if (isEmpty(allStudents)) return allStudents

    const overrides = map(this.props.overrides, override => override.attributes)
    const assignment = {
      due_at: this.props.dueAt,
      only_visible_to_overrides: this.props.isOnlyVisibleToOverrides,
    }

    const effectiveDueDates = AssignmentOverrideHelper.effectiveDueDatesForAssignment(
      assignment,
      overrides,
      allStudents
    )
    const gradingPeriodsHelper = new GradingPeriodsHelper(this.props.gradingPeriods)
    return reduce(
      effectiveDueDates,
      this.addStudentIfInClosedPeriod.bind(this, gradingPeriodsHelper),
      []
    )
  }

  // --------------------------
  //  Filtering Dropdown Opts
  // --------------------------
  // if a student/section has already been selected
  // it is no longer a valid option -> hide it

  validDropdownOptions = () => {
    let validStudents = this.valuesWithOmission({
      object: this.state.students,
      keysToOmit: this.chosenStudentIds(),
    })
    let validGroups = this.valuesWithOmission({
      object: this.groupsForSelectedSet(),
      keysToOmit: this.chosenGroupIds(),
    })
    let validSections = this.valuesWithOmission({
      object: this.state.sections,
      keysToOmit: this.chosenSectionIds(),
    })
    const validNoops = this.valuesWithOmission({
      object: this.state.noops,
      keysToOmit: this.chosenNoops(),
    })
    if (this.props.hasGradingPeriods && !ENV.current_user_is_admin) {
      ;({validStudents, validGroups, validSections} =
        this.filterDropdownOptionsForMultipleGradingPeriods(
          validStudents,
          validGroups,
          validSections
        ))
    }

    return union(validStudents, validSections, validGroups, validNoops)
  }

  extractGroupsAndSectionsFromStudent = (groups, toOmit, student) => {
    forEach(student.group_ids, groupID => {
      toOmit.groupsToOmit[groupID] = toOmit.groupsToOmit[groupID] || groups[groupID]
    })
    forEach(student.sections, sectionID => {
      toOmit.sectionsToOmit[sectionID] =
        toOmit.sectionsToOmit[sectionID] || this.state.sections[sectionID]
    })
    return toOmit
  }

  groupsAndSectionsInClosedPeriods = studentsToOmit => {
    const groups = this.groupsForSelectedSet()
    const omitted = reduce(
      studentsToOmit,
      this.extractGroupsAndSectionsFromStudent.bind(this, groups),
      {groupsToOmit: {}, sectionsToOmit: {}}
    )

    return {
      groupsToOmit: Object.values(omitted.groupsToOmit || {}),
      sectionsToOmit: Object.values(omitted.sectionsToOmit || {}),
    }
  }

  filterDropdownOptionsForMultipleGradingPeriods = (students, groups, sections) => {
    const studentsToOmit = this.studentsInClosedPeriods()

    if (isEmpty(studentsToOmit)) {
      return {validStudents: students, validGroups: groups, validSections: sections}
    } else {
      const {groupsToOmit, sectionsToOmit} = this.groupsAndSectionsInClosedPeriods(studentsToOmit)

      return {
        validStudents: difference(students, studentsToOmit),
        validGroups: difference(groups, groupsToOmit),
        validSections: difference(sections, sectionsToOmit),
      }
    }
  }

  chosenIds = idType =>
    _.chain(getAllOverrides(this.state.rows))
      .map(ov => ov.get(idType))
      .compact()
      .value()

  chosenSectionIds = () => this.chosenIds('course_section_id')

  chosenStudentIds = () => (this.chosenIds('student_ids') || []).flat(Infinity)

  chosenGroupIds = () => this.chosenIds('group_id')

  chosenNoops = () => this.chosenIds('noop_id')

  valuesWithOmission = args => chain(args.object).omit(args.keysToOmit).values().value()

  disableInputs = row => {
    const rowIsNewOrUserIsAdmin = !row.persisted || ENV.current_user_is_admin
    if (!this.props.hasGradingPeriods || rowIsNewOrUserIsAdmin) {
      return false
    }

    const dates = row.dates || {}
    return this.isInClosedGradingPeriod(dates.due_at)
  }

  isInClosedGradingPeriod = date => {
    if (date === undefined) return false

    const dueAt = date === null ? null : new Date(date)
    return new GradingPeriodsHelper(this.props.gradingPeriods).isDateInClosedGradingPeriod(dueAt)
  }

  // -------------------
  //      Rendering
  // -------------------

  rowsToRender = () =>
    map(sortedRowKeys(this.state.rows), rowKey => {
      const row = this.state.rows[rowKey]
      const overrides = row.overrides || []
      const dates = row.dates || {}
      return (
        <DueDateRow
          ref={this.rowRef(rowKey)}
          inputsDisabled={this.disableInputs(row)}
          overrides={overrides}
          key={rowKey}
          rowKey={rowKey}
          dates={dates}
          students={this.state.students}
          sections={this.state.sections}
          groups={this.state.groups}
          canDelete={this.canRemoveRow()}
          validDropdownOptions={this.validDropdownOptions()}
          handleDelete={this.removeRow.bind(this, rowKey)}
          handleTokenAdd={this.handleTokenAdd.bind(this, rowKey)}
          handleTokenRemove={this.handleTokenRemove.bind(this, rowKey)}
          defaultSectionNamer={this.defaultSectionNamer}
          replaceDate={this.replaceDate.bind(this, rowKey)}
          currentlySearching={this.state.currentlySearching}
          allStudentsFetched={this.state.allStudentsFetched}
          dueDatesReadonly={this.props.dueDatesReadonly}
          availabilityDatesReadonly={this.props.availabilityDatesReadonly}
          defaultDueTime={this.props.defaultDueTime}
        />
      )
    })

  imporantDatesCheckbox = () => {
    if (ENV.K5_SUBJECT_COURSE || ENV.K5_HOMEROOM_COURSE) {
      const disabled = !this.rowsToRender().some(row => row.props.dates.due_at)
      const checked = !disabled && this.state.importantDates
      return (
        <div id="important-dates">
          <Checkbox
            label={I18n.t('Mark as important date and show on homeroom sidebar')}
            name="important_dates"
            size="small"
            value={checked}
            checked={checked}
            onChange={event => {
              this.setState({importantDates: event.target.checked})
            }}
            disabled={disabled}
            inline={true}
          />
        </div>
      )
    }
  }

  render() {
    const rowsToRender = this.rowsToRender()
    const imporantDatesCheckbox = this.imporantDatesCheckbox()
    return (
      <div>
        <div className="ContainerDueDate" onMouseEnter={this.handleInteractionStart}>
          <div id="bordered-wrapper" className="Container__DueDateRow">
            {rowsToRender}
          </div>
          {this.props.dueDatesReadonly || this.props.availabilityDatesReadonly ? null : (
            <DueDateAddRowButton handleAdd={this.addRow} display={true} />
          )}
        </div>

        {imporantDatesCheckbox}
      </div>
    )
  }
}
