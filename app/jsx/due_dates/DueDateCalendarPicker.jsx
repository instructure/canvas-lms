/** @jsx React.DOM */

define([
  'underscore',
  'react',
  'jsx/due_dates/DueDateTokenWrapper',
  'jsx/due_dates/DueDateCalendarPicker',
  'i18n!assignments',
  'jquery',
  'jquery.instructure_forms'
], (_ , React, DueDateTokenWrapper ,DueDateCalendarPicker ,I18n, $) => {

  var cx = React.addons.classSet;
  var DueDateCalendarPicker = React.createClass({

    propTypes: {
      dateType: React.PropTypes.string.isRequired,
      handleUpdate: React.PropTypes.func.isRequired,
      rowKey: React.PropTypes.string.isRequired,
      labelledBy: React.PropTypes.string.isRequired
    },

    // ---------------
    //    Lifecycle
    // ---------------

    componentDidMount(){
      var dateInput = this.refs.dateInput.getDOMNode()

      $(dateInput).datetime_field().change( (e) => {
        var trimmedInput = $.trim(e.target.value)
        var localizedDate = $(dateInput).data('date')

        var newDate = (trimmedInput === "") ?
          null :
          localizedDate

        if(this.fancyMidnightNeeded(trimmedInput, newDate)){
          var newDate = this.changeToFancyMidnight(newDate)
        }
        var newDate = $.unfudgeDateForProfileTimezone(newDate)
        this.props.handleUpdate(newDate)
      })
    },

    // ensure jquery UI updates (as react doesn't know about it)
    componentDidUpdate(){
      var dateInput = this.refs.dateInput.getDOMNode()
      $(dateInput).val(this.formattedDate())
    },

    // --------------------
    //    Fancy Midnight
    // --------------------

    fancyMidnightNeeded(userInput, localizedDate){
      return localizedDate && !(this.props.dateType == "unlock_at") && this.isMidnight(localizedDate)
    },

    isMidnight(date){
      return date.getHours() === 0 && date.getMinutes() === 0
    },

    changeToFancyMidnight(date){
      date.setHours(23)
      date.setMinutes(59)
      return date
    },

    // ---------------
    //    Rendering
    // ---------------

    formattedDate(){
      return $.datetimeString(this.props.dateValue)
    },

    wrapperClassName(){
      return this.props.dateType == "due_at" ?
        "DueDateInput__Container" :
        "DueDateRow__LockUnlockInput"
    },

    inputClasses(){
      return cx({
        date_field: true,
        datePickerDateField: true,
        DueDateInput: this.props.dateType === "due_at",
        UnlockLockInput: this.props.dateType !== "due_at"
      })
    },

    render() {
      return (
        <div ref="datePickerWrapper" className={this.wrapperClassName()}>
          <input type            = "text"
                 ref             = "dateInput"
                 className       = {this.inputClasses()}
                 aria-labelledby = {this.props.labelledBy}
                 data-row-key    = {this.props.rowKey}
                 data-date-type  = {this.props.dateType}
                 defaultValue    = {this.formattedDate()} />
        </div>
      )
    }
  })
  return DueDateCalendarPicker
});
