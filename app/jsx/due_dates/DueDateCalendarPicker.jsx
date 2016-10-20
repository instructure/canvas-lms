define([
  'underscore',
  'react',
  'jsx/due_dates/DueDateTokenWrapper',
  'jsx/due_dates/DueDateCalendarPicker',
  'jsx/shared/helpers/accessibleDateFormat',
  'timezone',
  'i18n!assignments',
  'classnames',
  'jquery',
  'jquery.instructure_forms'
], (_, React, DueDateTokenWrapper, DueDateCalendarPicker, accessibleDateFormat, tz, I18n, cx, $) => {

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
      var dateInput = this.refs.dateInput

      $(dateInput).datetime_field().change( (e) => {
        var trimmedInput = $.trim(e.target.value)

        var newDate = $(dateInput).data('unfudged-date')
        newDate     = (trimmedInput === "") ? null : newDate
        newDate     = this.changeToFancyMidnightIfNeeded(newDate)

        this.props.handleUpdate(newDate)
      })
    },

    // ensure jquery UI updates (as react doesn't know about it)
    componentDidUpdate(){
      var dateInput = this.refs.dateInput
      $(dateInput).val(this.formattedDate())
    },

    changeToFancyMidnightIfNeeded(date) {
      if( !(this.props.dateType == "unlock_at") &&
          tz.isMidnight(date) ) {
        return tz.changeToTheSecondBeforeMidnight(date);
      } else {
        return date;
      }
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
                 title           = {accessibleDateFormat()}
                 data-tooltip    = ""
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
