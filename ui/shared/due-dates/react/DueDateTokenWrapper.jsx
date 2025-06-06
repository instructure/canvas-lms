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

import {chain, debounce, find, map, groupBy, isEmpty, some, union} from 'lodash'
import React from 'react'
import PropTypes from 'prop-types'
import OverrideStudentStore from './OverrideStudentStore'
import Override from '@canvas/assignments/backbone/models/AssignmentOverride'
import TokenInput, {Option as ComboboxOption} from 'react-tokeninput'
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import SearchHelpers from '@canvas/util/searchHelpers'
import DisabledTokenInput from './DisabledTokenInput'

const I18n = createI18nScope('DueDateTokenWrapper')

const DueDateWrapperConsts = {
  MINIMUM_SEARCH_LENGTH: 3,
  MAXIMUM_STUDENTS_TO_SHOW: 7,
  MAXIMUM_GROUPS_TO_SHOW: 5,
  MAXIMUM_SECTIONS_TO_SHOW: 3,
  MS_TO_DEBOUNCE_SEARCH: 800,
}

class DueDateTokenWrapper extends React.Component {
  static propTypes = {
    tokens: PropTypes.array.isRequired,
    handleTokenAdd: PropTypes.func.isRequired,
    handleTokenRemove: PropTypes.func.isRequired,
    potentialOptions: PropTypes.array.isRequired,
    rowKey: PropTypes.string.isRequired,
    defaultSectionNamer: PropTypes.func.isRequired,
    currentlySearching: PropTypes.bool.isRequired,
    allStudentsFetched: PropTypes.bool.isRequired,
    disabled: PropTypes.bool.isRequired,
  }

  MINIMUM_SEARCH_LENGTH = DueDateWrapperConsts.MINIMUM_SEARCH_LENGTH

  MAXIMUM_STUDENTS_TO_SHOW = DueDateWrapperConsts.MAXIMUM_STUDENTS_TO_SHOW

  MAXIMUM_SECTIONS_TO_SHOW = DueDateWrapperConsts.MAXIMUM_SECTIONS_TO_SHOW

  MAXIMUM_GROUPS_TO_SHOW = DueDateWrapperConsts.MAXIMUM_GROUPS_TO_SHOW

  MS_TO_DEBOUNCE_SEARCH = DueDateWrapperConsts.MS_TO_DEBOUNCE_SEARCH

  // -------------------
  //      Lifecycle
  // -------------------

  constructor(props) {
    super(props)
    this.disabledTokenInputRef = React.createRef()
    this.tokenInputRef = React.createRef()
  }

  state = {
    userInput: '',
    currentlyTyping: false,
  }

  // This is useful for testing to make it so the debounce is not used
  // during testing or any other time when that might be a problem.
  removeTimingSafeties = () => {
    this.safetiesOff = true
  }

  // -------------------
  //       Actions
  // -------------------

  handleFocus = () => {
    // TODO: once react supports onFocusIn, remove this stuff and just
    // do it on DueDates' top-level <div /> like we do for onMouseEnter
    OverrideStudentStore.fetchStudentsForCourse()
  }

  handleInput = userInput => {
    if (this.props.disabled) return

    this.setState({userInput, currentlyTyping: true}, function () {
      if (this.safetiesOff) {
        this.fetchStudents()
      } else {
        this.safeFetchStudents()
      }
    })
  }

  fetchStudents = () => {
    try {
      this.setState({currentlyTyping: false})
    } catch (error) {
      console.error('tried to set state in unmounted DueDateTokenWrapper', error)
    }
    if (
      $.trim(this.state.userInput) !== '' &&
      this.state.userInput.length >= this.MINIMUM_SEARCH_LENGTH
    ) {
      OverrideStudentStore.fetchStudentsByName($.trim(this.state.userInput))
    }
  }

  safeFetchStudents = debounce(this.fetchStudents, DueDateWrapperConsts.MS_TO_DEBOUNCE_SEARCH)

  handleTokenAdd = (value, option) => {
    if (this.props.disabled) return

    const token = this.findMatchingOption(value, option)
    this.props.handleTokenAdd(token)
    this.clearUserInput()
  }

  overrideTokenAriaLabel = tokenName =>
    I18n.t('Currently assigned to %{tokenName}, click to remove', {tokenName})

  handleTokenRemove = token => {
    if (this.props.disabled) return
    this.props.handleTokenRemove(token)
  }

  suppressKeys = e => {
    const code = e.keyCode || e.which
    if (code === 13) {
      e.preventDefault()
    }
  }

  clearUserInput = () => {
    this.setState({userInput: ''})
  }

  // -------------------
  //      Helpers
  // -------------------

  findMatchingOption = (name, option) => {
    if (option) {
      // Selection was made from dropdown, find by unique attributes
      return find(this.props.potentialOptions, option.props.set_props)
    } else {
      // Search for best matching name
      return this.sortedMatches(name)[0]
    }
  }

  sortedMatches = userInput => {
    const optsByMatch = groupBy(this.props.potentialOptions, dropdownObj => {
      if (SearchHelpers.exactMatchRegex(userInput).test(dropdownObj.name)) {
        return 'exact'
      }
      if (SearchHelpers.startOfStringRegex(userInput).test(dropdownObj.name)) {
        return 'start'
      }
      if (SearchHelpers.substringMatchRegex(userInput).test(dropdownObj.name)) {
        return 'substring'
      }
    })
    return union(optsByMatch.exact, optsByMatch.start, optsByMatch.substring)
  }

  filteredTags = () => {
    if (this.state.userInput === '') return this.props.potentialOptions
    return this.sortedMatches(this.state.userInput)
  }

  filteredTagsForType = type => {
    const groupedTags = this.groupByTagType(this.filteredTags())
    return (groupedTags && groupedTags[type]) || []
  }

  groupByTagType = options =>
    groupBy(options, opt => {
      if (opt.course_section_id) {
        return 'course_section'
      } else if (opt.group_id) {
        return 'group'
      } else if (opt.noop_id) {
        return 'noop'
      } else {
        return 'student'
      }
    })

  userSearchingThisInput = () => this.state.userInput && $.trim(this.state.userInput) !== ''

  // -------------------
  //      Rendering
  // -------------------

  rowIdentifier = () =>
    // identifying for validations
    `tokenInputFor${this.props.rowKey}`

  currentlySearching = () => {
    if (this.props.allStudentsFetched || $.trim(this.state.userInput) === '') {
      return false
    }
    return this.props.currentlySearching || this.state.currentlyTyping
  }

  // ---- options ----

  optionsForMenu = () => {
    const options = this.promptText()
      ? union([this.promptOption()], this.optionsForAllTypes())
      : this.optionsForAllTypes()
    return options
  }

  optionsForAllTypes = () =>
    union(
      this.conditionalReleaseOptions(),
      this.sectionOptions(),
      this.groupOptions(),
      this.studentOptions(),
    )

  studentOptions = () => this.optionsForType('student')

  groupOptions = () => this.optionsForType('group')

  sectionOptions = () => this.optionsForType('course_section')

  conditionalReleaseOptions = () => {
    if (!ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) return []

    const selectable = this.filteredTagsForType('noop').includes(Override.conditionalRelease)
    return selectable ? [this.headerOption('conditional_release', Override.conditionalRelease)] : []
  }

  optionsForType = optionType => {
    const header = this.headerOption(optionType)
    const options = this.selectableOptions(optionType)
    return some(options) ? union([header], options) : []
  }

  headerOption = (heading, set) => {
    const headerText = {
      get student() {
        return I18n.t('Student')
      },
      get course_section() {
        return I18n.t('Course Section')
      },
      get group() {
        return I18n.t('Group')
      },
      get conditional_release() {
        return I18n.t('Mastery Paths')
      },
    }[heading]

    const canSelect = heading === 'conditional_release'
    return (
      <ComboboxOption
        isFocusable={canSelect}
        className="ic-tokeninput-header"
        value={heading}
        key={heading}
        set_props={set}
      >
        {headerText}
      </ComboboxOption>
    )
  }

  selectableOptions = type => {
    const numberToShow =
      {
        student: this.MAXIMUM_STUDENTS_TO_SHOW,
        course_section: this.MAXIMUM_SECTIONS_TO_SHOW,
        group: this.MAXIMUM_GROUPS_TO_SHOW,
      }[type] || 0

    return chain(this.filteredTagsForType(type))
      .take(numberToShow)
      .map((set, index) => this.selectableOption(set, index))
      .value()
  }

  selectableOption = (set, index) => {
    const displayName =
      set.displayName || set.name || this.props.defaultSectionNamer(set.course_section_id)
    return (
      <ComboboxOption key={set.key || `${displayName}-${index}`} value={set.name} set_props={set}>
        {displayName}
        {set.pronouns && ` (${set.pronouns})`}
      </ComboboxOption>
    )
  }

  // ---- prompt ----

  promptOption = () => (
    <ComboboxOption value={this.promptText()} key="promptText">
      <i>{this.promptText()}</i>
      {this.throbber()}
    </ComboboxOption>
  )

  promptText = () => {
    if (this.currentlySearching()) {
      return I18n.t('Searching')
    }

    if (
      (this.state.userInput.length < this.MINIMUM_SEARCH_LENGTH &&
        !this.props.allStudentsFetched) ||
      this.hidingValidMatches()
    ) {
      return I18n.t('Continue typing to find additional sections or students.')
    }

    if (isEmpty(this.filteredTags())) {
      return I18n.t('No results found')
    }
  }

  throbber = () => {
    if (this.currentlySearching() && this.userSearchingThisInput()) {
      return <div className="tokenInputThrobber" />
    }
  }

  hidingValidMatches = () => {
    const allSectionTags = this.filteredTagsForType('course_section')
    const hidingSections = allSectionTags && allSectionTags.length > this.MAXIMUM_SECTIONS_TO_SHOW

    const allStudentTags = this.filteredTagsForType('student')
    const hidingStudents = allStudentTags && allStudentTags.length > this.MAXIMUM_STUDENTS_TO_SHOW

    const allGroupTags = this.filteredTagsForType('group')
    const hidingGroups = allGroupTags && allGroupTags.length > this.MAXIMUM_GROUPS_TO_SHOW

    return hidingSections || hidingStudents || hidingGroups
  }

  renderTokenInput = () => {
    if (this.props.disabled) {
      return (
        <DisabledTokenInput
          tokens={map(this.props.tokens, 'name')}
          ref={this.disabledTokenInputRef}
        />
      )
    }
    const ariaLabel = I18n.t(
      'Add students by searching by name, course section or group.' +
        ' After entering text, navigate results by using the down arrow key.' +
        ' Select a result by using the Enter key.',
    )
    return (
      <div>
        <div id="ic-tokeninput-description" className="screenreader-only">
          {I18n.t(
            'Use this list to remove assigned students. Add new students with combo box after list.',
          )}
        </div>
        <TokenInput
          menuContent={this.optionsForMenu()}
          selected={this.props.tokens}
          onFocus={this.handleFocus}
          onInput={this.handleInput}
          onSelect={this.handleTokenAdd}
          tokenAriaFunc={this.overrideTokenAriaLabel}
          onRemove={this.handleTokenRemove}
          combobox-aria-label={ariaLabel}
          value={true}
          showListOnFocus={!this.props.disabled}
          ref={this.tokenInputRef}
        />
      </div>
    )
  }

  // ---- render ----

  render() {
    return (
      // eslint-disable-next-line jsx-a11y/no-static-element-interactions
      <div
        className="ic-Form-control"
        data-row-identifier={this.rowIdentifier()}
        onKeyDown={this.suppressKeys}
      >
        <div id="assign-to-label" className="ic-Label" title="Assign to" aria-label="Assign to">
          {I18n.t('Assign to')}
        </div>
        {this.renderTokenInput()}
      </div>
    )
  }
}

export default DueDateTokenWrapper
