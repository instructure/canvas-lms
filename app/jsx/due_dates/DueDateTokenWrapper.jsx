define([
  'underscore',
  'react',
  'react-modal',
  'jsx/due_dates/OverrideStudentStore',
  'compiled/models/AssignmentOverride',
  'bower/react-tokeninput/dist/react-tokeninput',
  'i18n!assignments',
  'jquery',
  'jsx/shared/helpers/searchHelpers'
], (_ ,React, ReactModal, OverrideStudentStore, Override, TokenInput, I18n, $, SearchHelpers) => {

  var ComboboxOption = TokenInput.Option;
  TokenInput = TokenInput.default;

  var DueDateWrapperConsts = {
    MINIMUM_SEARCH_LENGTH: 3,
    MAXIMUM_STUDENTS_TO_SHOW: 7,
    MAXIMUM_GROUPS_TO_SHOW: 5,
    MAXIMUM_SECTIONS_TO_SHOW: 3,
    MS_TO_DEBOUNCE_SEARCH: 800,
  }

  var DueDateTokenWrapper = React.createClass({

    propTypes: {
      tokens: React.PropTypes.array.isRequired,
      handleTokenAdd: React.PropTypes.func.isRequired,
      handleTokenRemove: React.PropTypes.func.isRequired,
      potentialOptions: React.PropTypes.array.isRequired,
      rowKey: React.PropTypes.string.isRequired,
      defaultSectionNamer: React.PropTypes.func.isRequired,
      currentlySearching: React.PropTypes.bool.isRequired,
      allStudentsFetched: React.PropTypes.bool.isRequired
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

    handleInput(userInput) {
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

    handleTokenAdd(name, option) {
      var token = this.findMatchingOption(name, option)
      this.props.handleTokenAdd(token)
      this.clearUserInput()
    },

    handleTokenRemove(token) {
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
      return <ComboboxOption className="ic-tokeninput-header" value={heading} key={heading} set_props={set}>
               {headerText}
             </ComboboxOption>
    },

    selectableOptions(type){
      var numberToShow = {
        "student": this.MAXIMUM_STUDENTS_TO_SHOW,
        "course_section": this.MAXIMUM_SECTIONS_TO_SHOW,
        "group": this.MAXIMUM_GROUPS_TO_SHOW,
      }[type] || 0

      return _.chain(this.filteredTagsForType(type))
        .take(numberToShow)
        .map((set) => this.selectableOption(set))
        .value()
    },

    selectableOption(set){
      var displayName = set.name || this.props.defaultSectionNamer(set.course_section_id)
      return <ComboboxOption key={set.key} value={set.name} set_props={set}>
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

    // ---- render ----

    render() {
      return (
        <div className           = "ic-Form-control"
             data-row-identifier = {this.rowIdentifier()}
             onKeyDown           = {this.suppressKeys}>
          <div className  = "ic-Label"
               tabIndex   = '0'
               title      = 'Assign to'
               aria-label = 'Assign to'>
             {I18n.t("Assign to")}
           </div>
          <TokenInput menuContent     = {this.optionsForMenu()}
                      selected        = {this.props.tokens}
                      onInput         = {this.handleInput}
                      onSelect        = {this.handleTokenAdd}
                      onRemove        = {this.handleTokenRemove}
                      value           = {true}
                      showListOnFocus = {true}
                      ref             = "TokenInput" />
        </div>
      )
    }
  })

  return DueDateTokenWrapper
});
