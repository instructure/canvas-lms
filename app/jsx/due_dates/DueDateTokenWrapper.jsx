/** @jsx React.DOM */

define([
  'underscore',
  'react',
  'react-modal',
  'jsx/due_dates/OverrideStudentStore',
  'bower/react-tokeninput/dist/react-tokeninput',
  'i18n!assignments',
  'jquery'
], (_ ,React, ReactModal, OverrideStudentStore, TokenInput, I18n, $) => {

  var ComboboxOption = React.createFactory(TokenInput.Option)
  var TokenInput = React.createFactory(TokenInput)

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

    MINIMUM_SEARCH_LENGTH: 3,
    MAXIMUM_STUDENTS_TO_SHOW: 10,
    MAXIMUM_SECTIONS_TO_SHOW: 5,
    MS_TO_DEBOUNCE_SEARCH: 800,

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
        { userInput: userInput, currentlyTyping: true },
        this.fetchStudents
      )
    },

    fetchStudents: _.debounce( function() {
        if( this.isMounted() ){
          this.setState({currentlyTyping: false})
        }
        if ($.trim(this.state.userInput) !== '' && this.state.userInput.length >= this.MINIMUM_SEARCH_LENGTH) {
          OverrideStudentStore.fetchStudentsByName($.trim(this.state.userInput))
        }
      }, this.MS_TO_DEBOUNCE_SEARCH
    ),

    handleTokenAdd(value) {
      var token = this.findMatchingOption(value)
      this.props.handleTokenAdd(token)
      this.clearUserInput()
    },

    handleTokenRemove(value) {
      var token = this.findMatchingOption(value)
      this.props.handleTokenRemove(token)
    },

    findMatchingOption(userInput){
      if(typeof userInput !== 'string') { return userInput }
      return this.enumerableStartsWith(userInput, _.find)
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

    groupBySectionOrStudent(options){
      return _.groupBy(options, function(opt){

        return opt["course_section_id"] ? "course_section" : "student"
      })
    },

    enumerableStartsWith(userInput, enumerable){
      var filter = new RegExp('^'+userInput, 'i')
      return enumerable(this.props.potentialOptions, function(option){
        return filter.test(option.name)
      })
    },

    userSearchingThisInput(){
      return this.state.userInput && $.trim(this.state.userInput) !== ""
    },

    filteredTags() {
      if (this.state.userInput === '') return this.props.potentialOptions
      return this.enumerableStartsWith(this.state.userInput, _.filter)
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

    selectableOptions(groupedOptions, type){
      var numberToShow = type === "Student" ? this.MAXIMUM_STUDENTS_TO_SHOW : this.MAXIMUM_SECTIONS_TO_SHOW
      return _.chain(groupedOptions[type])
        .take(numberToShow)
        .map((set) => this.selectableOption(set))
        .value()
    },

    optionsForMenu() {
      var groupedOptions = this.groupBySectionOrStudent(this.filteredTags())
      var groupHeadings = ["course_section", "student"]

      var groups = groupHeadings.map((heading) => {
        var header = this.headerOption(heading)
        var options = groupedOptions[heading] ?
          this.selectableOptions(groupedOptions, heading) :
          []
        return _.any(options) ? _.union([header], options) : []
      })

      var options = this.promptText() ?
        _.union([this.promptOption()], _.flatten(groups)) :
        _.flatten(groups)

      return options
    },

    headerOption(heading){
      var headerText = heading === "student" ? I18n.t("Student") : I18n.t("Course Section")
      return <ComboboxOption className="ic-tokeninput-header" value={heading} key={heading}>
               {headerText}
             </ComboboxOption>
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

      if(this.state.userInput.length < this.MINIMUM_SEARCH_LENGTH && !this.props.allStudentsFetched){
        return I18n.t("Type more to find additional students")
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

    // ---- render ----

    render() {
      return (
        <div className           = "ic-Form-control"
             data-row-identifier = {this.rowIdentifier()}
             onKeyDown           = {this.suppressKeys}>
          <div className  = "ic-Label"
               title      = 'Assign to'
               aria-label = 'Assign to'>
             To
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
