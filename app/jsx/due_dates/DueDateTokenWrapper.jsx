define([
  'underscore',
  'react',
  'react-modal',
  'jsx/due_dates/OverrideStudentStore',
  'bower/react-tokeninput/dist/react-tokeninput',
  'i18n!assignments',
  'jquery',
  'jsx/shared/helpers/searchHelpers'
], (_ ,React, ReactModal, OverrideStudentStore, TokenInput, I18n, $, SearchHelpers) => {

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

    handleTokenAdd(value) {
      var token = this.findMatchingOption(value)
      this.props.handleTokenAdd(token)
      this.clearUserInput()
    },

    handleTokenRemove(value) {
      var token = this.findMatchingOption(value)
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

    findMatchingOption(userInput){
      if(typeof userInput !== 'string') { return userInput }
      return this.findBestMatch(userInput)
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

    findBestMatch(userInput){
      return _.find(this.props.potentialOptions, (item) => SearchHelpers.exactMatchRegex(userInput).test(item.name)) ||
      _.find(this.props.potentialOptions, (item) => SearchHelpers.startOfStringRegex(userInput).test(item.name)) ||
      _.find(this.props.potentialOptions, (item) => SearchHelpers.substringMatchRegex(userInput).test(item.name))
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
        } else {
          return !!opt["group_id"] ? "group" : "student"
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

    optionsForType(optionType){
      var header = this.headerOption(optionType)
      var options = this.selectableOptions(optionType)
      return _.any(options) ? _.union([header], options) : []
    },

    headerOption(heading){
      var headerText = {
        "student": I18n.t("Student"),
        "course_section": I18n.t("Course Section"),
        "group": I18n.t("Group"),
      }[heading]
      return <ComboboxOption className="ic-tokeninput-header" value={heading} key={heading}>
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
      return <ComboboxOption key={set.key} value={set.name}>
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
