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
import PropTypes from 'prop-types'
import ReactModal from 'react-modal'
import OverrideStudentStore from '../due_dates/OverrideStudentStore'
import Override from 'compiled/models/AssignmentOverride'
import TokenInput, {Option as ComboboxOption} from 'react-tokeninput'
import I18n from 'i18n!assignments'
import $ from 'jquery'
import SearchHelpers from '../shared/helpers/searchHelpers'
import DisabledTokenInput from '../due_dates/DisabledTokenInput'

  var DueDateWrapperConsts = {
    MINIMUM_SEARCH_LENGTH: 3,
    MAXIMUM_STUDENTS_TO_SHOW: 7,
    MAXIMUM_GROUPS_TO_SHOW: 5,
    MAXIMUM_SECTIONS_TO_SHOW: 3,
    MS_TO_DEBOUNCE_SEARCH: 800,
  }

  var DueDateTokenWrapper = React.createClass({

    propTypes: {
      tokens: PropTypes.array.isRequired,
      handleTokenAdd: PropTypes.func.isRequired,
      handleTokenRemove: PropTypes.func.isRequired,
      potentialOptions: PropTypes.array.isRequired,
      rowKey: PropTypes.string.isRequired,
      defaultSectionNamer: PropTypes.func.isRequired,
      currentlySearching: PropTypes.bool.isRequired,
      allStudentsFetched: PropTypes.bool.isRequired,
      disabled: PropTypes.bool.isRequired
    },

    MINIMUM_SEARCH_LENGTH: DueDateWrapperConsts.MINIMUM_SEARCH_LENGTH,
    MAXIMUM_STUDENTS_TO_SHOW: DueDateWrapperConsts.MAXIMUM_STUDENTS_TO_SHOW,
    MAXIMUM_SECTIONS_TO_SHOW: DueDateWrapperConsts.MAXIMUM_SECTIONS_TO_SHOW,
    MAXIMUM_GROUPS_TO_SHOW: DueDateWrapperConsts.MAXIMUM_GROUPS_TO_SHOW,
    MS_TO_DEBOUNCE_SEARCH: DueDateWrapperConsts.MS_TO_DEBOUNCE_SEARCH,

    // This is useful for testing to make it so the debounce is not used
    // during testing or any other time when that might be a problem.
    removeTimingSafeties(){
      this.safetiesOff = true;
    },

    // -------------------
    //      Lifecycle
    // -------------------

    getInitialState() {
      return {
        userInput: "",
        currentlyTyping: false
      }
    },

    // -------------------
    //       Actions
    // -------------------

    handleFocus() {
      // TODO: once react supports onFocusIn, remove this stuff and just
      // do it on DueDates' top-level <div /> like we do for onMouseEnter
      OverrideStudentStore.fetchStudentsForCourse()
    },

    handleInput(userInput) {
      if (this.props.disabled) return;

      this.setState(
        { userInput: userInput, currentlyTyping: true },function(){
          if (this.safetiesOff) {
            this.fetchStudents()
          } else {
            this.safeFetchStudents()
          }
        }

      )
    },

    safeFetchStudents: _.debounce( function() {
        this.fetchStudents()
      }, DueDateWrapperConsts.MS_TO_DEBOUNCE_SEARCH
    ),

    fetchStudents(){
      if( this.isMounted() ){
        this.setState({currentlyTyping: false})
      }
      if ($.trim(this.state.userInput) !== '' && this.state.userInput.length >= this.MINIMUM_SEARCH_LENGTH) {
        OverrideStudentStore.fetchStudentsByName($.trim(this.state.userInput))
      }
    },

    handleTokenAdd(value, option) {
      if (this.props.disabled) return;

      var token = this.findMatchingOption(value, option)
      this.props.handleTokenAdd(token)
      this.clearUserInput()
    },

    overrideTokenAriaLabel(tokenName) {
      return I18n.t('Currently assigned to %{tokenName}, click to remove', {tokenName: tokenName});
    },

    handleTokenRemove(token) {
      if (this.props.disabled) return;
      this.props.handleTokenRemove(token)
    },

    suppressKeys(e){
      var code = e.keyCode || e.which
      if (code === 13) {
        e.preventDefault()
      }
    },

    clearUserInput(){
      this.setState({userInput: ""})
    },

    // -------------------
    //      Helpers
    // -------------------

    findMatchingOption(name, option){
      if(option){
        // Selection was made from dropdown, find by unique attributes
        return _.findWhere(this.props.potentialOptions, option.props.set_props)
      } else {
        // Search for best matching name
        return this.sortedMatches(name)[0]
      }
    },

    sortedMatches(userInput){
      var optsByMatch = _.groupBy(this.props.potentialOptions, (dropdownObj) => {
        if (SearchHelpers.exactMatchRegex(userInput).test(dropdownObj.name)) { return "exact" }
        if (SearchHelpers.startOfStringRegex(userInput).test(dropdownObj.name)) { return "start" }
        if (SearchHelpers.substringMatchRegex(userInput).test(dropdownObj.name)) { return "substring" }
      });
      return _.union(
        optsByMatch.exact, optsByMatch.start, optsByMatch.substring
      );
    },

    filteredTags() {
      if (this.state.userInput === '') return this.props.potentialOptions
      return this.sortedMatches(this.state.userInput)
    },

    filteredTagsForType(type){
      var groupedTags = this.groupByTagType(this.filteredTags())
      return groupedTags && groupedTags[type] || []
    },

    groupByTagType(options){
      return _.groupBy(options, (opt) => {
        if (opt["course_section_id"]) {
          return "course_section"
        } else if (opt["group_id"]) {
          return "group"
        } else if (opt["noop_id"]){
          return "noop"
        } else {
          return "student"
        }
      })
    },

    userSearchingThisInput(){
      return this.state.userInput && $.trim(this.state.userInput) !== ""
    },

    // -------------------
    //      Rendering
    // -------------------

    rowIdentifier(){
      // identifying for validations
      return "tokenInputFor" + this.props.rowKey
    },

    currentlySearching(){
      if(this.props.allStudentsFetched || $.trim(this.state.userInput) === ''){
        return false
      }
      return this.props.currentlySearching || this.state.currentlyTyping
    },

    // ---- options ----

    optionsForMenu() {
      var options = this.promptText() ?
        _.union([this.promptOption()], this.optionsForAllTypes()) :
        this.optionsForAllTypes()
      return options
    },

    optionsForAllTypes(){
      return _.union(
        this.conditionalReleaseOptions(),
        this.sectionOptions(),
        this.groupOptions(),
        this.studentOptions()
      )
    },

    studentOptions(){
      return this.optionsForType("student")
    },

    groupOptions(){
      return this.optionsForType("group")
    },

    sectionOptions(){
      return this.optionsForType("course_section")
    },

    conditionalReleaseOptions(){
      if (!ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) return []

      var selectable = _.contains(this.filteredTagsForType('noop'), Override.conditionalRelease)
      return selectable ? [this.headerOption("conditional_release", Override.conditionalRelease)] : []
    },

    optionsForType(optionType){
      var header = this.headerOption(optionType)
      var options = this.selectableOptions(optionType)
      return _.any(options) ? _.union([header], options) : []
    },

    headerOption(heading, set){
      var headerText = {
        "student": I18n.t("Student"),
        "course_section": I18n.t("Course Section"),
        "group": I18n.t("Group"),
        "conditional_release": I18n.t("Mastery Paths"),
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
    },

    selectableOptions(type){
      var numberToShow = {
        "student": this.MAXIMUM_STUDENTS_TO_SHOW,
        "course_section": this.MAXIMUM_SECTIONS_TO_SHOW,
        "group": this.MAXIMUM_GROUPS_TO_SHOW,
      }[type] || 0

      return _.chain(this.filteredTagsForType(type))
        .take(numberToShow)
        .map((set, index) => this.selectableOption(set, index))
        .value()
    },

    selectableOption(set, index){
      var displayName = set.name || this.props.defaultSectionNamer(set.course_section_id)
      return <ComboboxOption key={set.key || `${displayName}-${index}`} value={set.name} set_props={set}>
               {displayName}
             </ComboboxOption>
    },

    // ---- prompt ----

    promptOption(){
      return (
        <ComboboxOption value={this.promptText()} key={"promptText"}>
          <i>{this.promptText()}</i>
          {this.throbber()}
        </ComboboxOption>
      )
    },

    promptText(){
      if (this.currentlySearching()){
        return I18n.t("Searching")
      }

      if(this.state.userInput.length < this.MINIMUM_SEARCH_LENGTH && !this.props.allStudentsFetched || this.hidingValidMatches()){
        return I18n.t("Continue typing to find additional sections or students.")
      }

      if(_.isEmpty(this.filteredTags())){
        return I18n.t("No results found")
      }
    },

    throbber(){
      if(this.currentlySearching() && this.userSearchingThisInput()){
        return (
          <div className="tokenInputThrobber"/>
        )
      }
    },

    hidingValidMatches(){
      var allSectionTags = this.filteredTagsForType("course_section")
      var hidingSections = allSectionTags && allSectionTags.length > this.MAXIMUM_SECTIONS_TO_SHOW

      var allStudentTags = this.filteredTagsForType("student")
      var hidingStudents = allStudentTags && allStudentTags.length > this.MAXIMUM_STUDENTS_TO_SHOW

      var allGroupTags = this.filteredTagsForType("group")
      var hidingGroups = allGroupTags && allGroupTags.length > this.MAXIMUM_GROUPS_TO_SHOW

      return hidingSections || hidingStudents || hidingGroups
    },

    renderTokenInput() {
      if (this.props.disabled) {
        return <DisabledTokenInput tokens={_.pluck(this.props.tokens, "name")} ref="DisabledTokenInput"/>;
      }
      const ariaLabel = I18n.t(
        'Add students by searching by name, course section or group.' +
        ' After entering text, navigate results by using the down arrow key.' +
        ' Select a result by using the Enter key.'
      );
      return (
        <div>
          <div id="ic-tokeninput-description"
               className = "screenreader-only">
            { I18n.t('Use this list to remove assigned students. Add new students with combo box after list.') }
          </div>
          <TokenInput
            menuContent         = {this.optionsForMenu()}
            selected            = {this.props.tokens}
            onFocus             = {this.handleFocus}
            onInput             = {this.handleInput}
            onSelect            = {this.handleTokenAdd}
            tokenAriaFunc       = {this.overrideTokenAriaLabel}
            onRemove            = {this.handleTokenRemove}
            combobox-aria-label = {ariaLabel}
            value               = {true}
            showListOnFocus     = {!this.props.disabled}
            ref                 = "TokenInput"
          />
        </div>
      );
    },

    // ---- render ----

    render() {
      return (
        <div className           = "ic-Form-control"
             data-row-identifier = {this.rowIdentifier()}
             onKeyDown           = {this.suppressKeys}>
          <div id         = "assign-to-label"
               className  = "ic-Label"
               title      = 'Assign to'
               aria-label = 'Assign to'>
             {I18n.t("Assign to")}
          </div>
          {this.renderTokenInput()}
        </div>
      )
    }
  })

export default DueDateTokenWrapper
