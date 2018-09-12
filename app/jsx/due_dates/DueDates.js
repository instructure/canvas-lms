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

import _ from 'underscore'
import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import DueDateRow from '../due_dates/DueDateRow'
import DueDateAddRowButton from '../due_dates/DueDateAddRowButton'
import OverrideStudentStore from '../due_dates/OverrideStudentStore'
import StudentGroupStore from '../due_dates/StudentGroupStore'
import TokenActions from '../due_dates/TokenActions'
import Override from 'compiled/models/AssignmentOverride'
import AssignmentOverrideHelper from '../gradebook/AssignmentOverrideHelper'
import I18n from 'i18n!assignments'
import GradingPeriodsHelper from '../grading/helpers/GradingPeriodsHelper'
import tz from 'timezone'
import 'compiled/jquery.rails_flash_notifications'

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
    availabilityDatesReadonly: PropTypes.bool
  }

  static defaultProps = {
    dueDatesReadonly: false,
    availabilityDatesReadonly: false
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
    defaultSectionId: null,
    currentlySearching: false,
    allStudentsFetched: false,
    selectedGroupSetId: null
  }

  componentDidMount() {
    this.setState(
      {
        rows: this.rowsFromOverrides(this.props.overrides),
        sections: this.formattedSectionHash(this.props.sections),
        groups: {},
        selectedGroupSetId: this.props.selectedGroupSetId
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
      allStudentsFetched: OverrideStudentStore.allStudentsFetched()
    })
  }

  handleStudentGroupStoreChange = () => {
    this.setState({
      groups: this.formattedGroupHash(StudentGroupStore.getGroups()),
      selectedGroupSetId: StudentGroupStore.getSelectedGroupSetId()
    })
  }

  // always keep React Overrides in sync with Backbone Collection
  componentWillUpdate(nextProps, nextState) {
    const updatedOverrides = this.getAllOverrides(nextState.rows)
    this.props.syncWithBackbone(updatedOverrides)
  }

  // --------------------------
  //        State Change
  // --------------------------

  replaceRow = (rowKey, newOverrides, rowDates) => {
    const tmp = {}
    const dates = rowDates || this.datesFromOverride(newOverrides[0])
    tmp[rowKey] = {overrides: newOverrides, dates, persisted: false}

    const newRows = _.extend(this.state.rows, tmp)
    this.setState({rows: newRows})
  }

  // -------------------
  //       Helpers
  // -------------------

  formattedSectionHash = unformattedSections => {
    const formattedSections = _.map(unformattedSections, this.formatSection)
    return _.indexBy(formattedSections, 'id')
  }

  formatSection = section => _.extend(section.attributes, {course_section_id: section.id})

  formattedGroupHash = unformattedGroups => {
    const formattedGroups = _.map(unformattedGroups, this.formatGroup)
    return _.indexBy(formattedGroups, 'id')
  }

  formatGroup = group => _.extend(group, {group_id: group.id})

  getAllOverrides = givenRows => {
    const rows = givenRows || this.state.rows
    return _.chain(rows)
      .values()
      .map(row =>
        _.map(row.overrides, override => {
          override.attributes.persisted = row.persisted
          return override
        })
      )
      .flatten()
      .compact()
      .value()
  }

  adhocOverrides = () => _.filter(this.getAllOverrides(), ov => ov.get('student_ids'))

  adhocOverrideStudentIDs = () =>
    _.chain(this.adhocOverrides())
      .map(ov => ov.get('student_ids'))
      .flatten()
      .uniq()
      .value()

  datesFromOverride = override => ({
    due_at: override ? override.get('due_at') : null,
    lock_at: override ? override.get('lock_at') : null,
    unlock_at: override ? override.get('unlock_at') : null
  })

  groupsForSelectedSet = () => {
    const allGroups = this.state.groups
    const setId = this.state.selectedGroupSetId
    return _.chain(allGroups)
      .filter((value, key) => value.group_category_id === setId)
      .indexBy('id')
      .value()
  }

  // -------------------
  //      Row Setup
  // -------------------

  rowsFromOverrides = overrides => {
    const overridesByKey = _.groupBy(overrides, override => {
      override.set('rowKey', override.combinedDates())
      return override.get('rowKey')
    })

    return _.chain(overridesByKey)
      .map((overrides, key) => {
        const datesForGroup = this.datesFromOverride(overrides[0])
        return [key, {overrides, dates: datesForGroup, persisted: true}]
      })
      .object()
      .value()
  }

  sortedRowKeys = () => {
    const {datedKeys, numberedKeys} = _.chain(this.state.rows)
      .keys()
      .groupBy(key => (key.length > 11 ? 'datedKeys' : 'numberedKeys'))
      .value()

    return _.chain([datedKeys, numberedKeys])
      .flatten()
      .compact()
      .value()
  }

  rowRef = rowKey => `due_date_row-${rowKey}`

  // ------------------------
  // Adding and Removing Rows
  // ------------------------

  addRow = () => {
    const newRowCount = this.state.addedRowCount + 1
    this.replaceRow(newRowCount, [], {})
    this.setState({addedRowCount: newRowCount}, function() {
      this.focusRow(newRowCount)
    })
  }

  removeRow = rowToRemoveKey => {
    if (!this.canRemoveRow()) return

    const previousIndex = _.indexOf(this.sortedRowKeys(), rowToRemoveKey)
    const newRows = _.omit(this.state.rows, rowToRemoveKey)
    this.setState({rows: newRows}, function() {
      const ks = this.sortedRowKeys()
      const previousRowKey = ks[previousIndex] || ks[ks.length - 1]
      this.focusRow(previousRowKey)
    })
  }

  canRemoveRow = () => this.sortedRowKeys().length > 1

  focusRow = rowKey => {
    ReactDOM.findDOMNode(this.refs[this.rowRef(rowKey)])
      .querySelector('input')
      .focus()
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

    const newOverrides = _.map(oldOverrides, override => {
      override.set(dateType, newDate)
      return override
    })

    const tmp = {}
    tmp[dateType] = newDate
    const newDates = _.extend(oldDates, tmp)

    this.replaceRow(rowKey, newOverrides, newDates)
  }

  // --------------------------
  //  Everyone v Everyone Else
  // --------------------------

  defaultSectionNamer = sectionID => {
    if (sectionID !== this.props.defaultSectionId) return null

    const onlyDefaultSectionChosen = _.isEqual(this.chosenSectionIds(), [sectionID])
    const noSectionsChosen = _.isEmpty(this.chosenSectionIds())

    const noGroupsChosen = _.isEmpty(this.chosenGroupIds())
    const noStudentsChosen = _.isEmpty(this.chosenStudentIds())

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
    const allStudents = _.values(this.state.students)
    if (_.isEmpty(allStudents)) return allStudents

    const overrides = _.map(this.props.overrides, override => override.attributes)
    const assignment = {
      due_at: this.props.dueAt,
      only_visible_to_overrides: this.props.isOnlyVisibleToOverrides
    }

    const effectiveDueDates = AssignmentOverrideHelper.effectiveDueDatesForAssignment(
      assignment,
      overrides,
      allStudents
    )
    const gradingPeriodsHelper = new GradingPeriodsHelper(this.props.gradingPeriods)
    return _.reduce(
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
      keysToOmit: this.chosenStudentIds()
    })
    let validGroups = this.valuesWithOmission({
      object: this.groupsForSelectedSet(),
      keysToOmit: this.chosenGroupIds()
    })
    let validSections = this.valuesWithOmission({
      object: this.state.sections,
      keysToOmit: this.chosenSectionIds()
    })
    const validNoops = this.valuesWithOmission({
      object: this.state.noops,
      keysToOmit: this.chosenNoops()
    })
    if (this.props.hasGradingPeriods && !_.contains(ENV.current_user_roles, 'admin')) {
      ;({
        validStudents,
        validGroups,
        validSections
      } = this.filterDropdownOptionsForMultipleGradingPeriods(
        validStudents,
        validGroups,
        validSections
      ))
    }

    return _.union(validStudents, validSections, validGroups, validNoops)
  }

  extractGroupsAndSectionsFromStudent = (groups, toOmit, student) => {
    _.each(student.group_ids, groupID => {
      toOmit.groupsToOmit[groupID] = toOmit.groupsToOmit[groupID] || groups[groupID]
    })
    _.each(student.sections, sectionID => {
      toOmit.sectionsToOmit[sectionID] =
        toOmit.sectionsToOmit[sectionID] || this.state.sections[sectionID]
    })
    return toOmit
  }

  groupsAndSectionsInClosedPeriods = studentsToOmit => {
    const groups = this.groupsForSelectedSet()
    const omitted = _.reduce(
      studentsToOmit,
      this.extractGroupsAndSectionsFromStudent.bind(this, groups),
      {groupsToOmit: {}, sectionsToOmit: {}}
    )

    return {
      groupsToOmit: _.values(omitted.groupsToOmit),
      sectionsToOmit: _.values(omitted.sectionsToOmit)
    }
  }

  filterDropdownOptionsForMultipleGradingPeriods = (students, groups, sections) => {
    const studentsToOmit = this.studentsInClosedPeriods()

    if (_.isEmpty(studentsToOmit)) {
      return {validStudents: students, validGroups: groups, validSections: sections}
    } else {
      const {groupsToOmit, sectionsToOmit} = this.groupsAndSectionsInClosedPeriods(studentsToOmit)

      return {
        validStudents: _.difference(students, studentsToOmit),
        validGroups: _.difference(groups, groupsToOmit),
        validSections: _.difference(sections, sectionsToOmit)
      }
    }
  }

  chosenIds = idType =>
    _.chain(this.getAllOverrides())
      .map(ov => ov.get(idType))
      .compact()
      .value()

  chosenSectionIds = () => this.chosenIds('course_section_id')

  chosenStudentIds = () => _.flatten(this.chosenIds('student_ids'))

  chosenGroupIds = () => this.chosenIds('group_id')

  chosenNoops = () => this.chosenIds('noop_id')

  valuesWithOmission = args =>
    _.chain(args.object)
      .omit(args.keysToOmit)
      .values()
      .value()

  disableInputs = row => {
    const rowIsNewOrUserIsAdmin = !row.persisted || _.contains(ENV.current_user_roles, 'admin')
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
    _.map(this.sortedRowKeys(), rowKey => {
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
        />
      )
    })

  render() {
    const rowsToRender = this.rowsToRender()
    return (
      <div className="ContainerDueDate" onMouseEnter={this.handleInteractionStart}>
        <div id="bordered-wrapper" className="Container__DueDateRow">
          {rowsToRender}
        </div>
        {this.props.dueDatesReadonly || this.props.availabilityDatesReadonly ? null : (
          <DueDateAddRowButton handleAdd={this.addRow} display />
        )}
      </div>
    )
  }
}
