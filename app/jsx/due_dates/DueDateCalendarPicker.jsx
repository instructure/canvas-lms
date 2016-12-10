define([
  'jquery',
  'react',
  'jsx/shared/helpers/accessibleDateFormat',
  'timezone',
  'jquery.instructure_forms'
], ($, React, accessibleDateFormat, tz) => {

  const { string, func, bool, instanceOf } = React.PropTypes;

  var DueDateCalendarPicker = React.createClass({

    propTypes: {
      dateType: string.isRequired,
      handleUpdate: func.isRequired,
      rowKey: string.isRequired,
      labelledBy: string.isRequired,
      inputClasses: string.isRequired,
      disabled: bool.isRequired,
      isFancyMidnight: bool.isRequired,
      dateValue: instanceOf(Date).isRequired,
    },

    // ---------------
    //    Lifecycle
    // ---------------

    componentDidMount() {
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
    componentDidUpdate() {
      var dateInput = this.refs.dateInput
      $(dateInput).val(this.formattedDate())
    },

    changeToFancyMidnightIfNeeded(date) {
      if (this.props.isFancyMidnight && tz.isMidnight(date)) {
        return tz.changeToTheSecondBeforeMidnight(date);
      }

      return date;
    },
    // ---------------
    //    Rendering
    // ---------------

    formattedDate() {
      return $.datetimeString(this.props.dateValue)
    },

    wrapperClassName() {
      return this.props.dateType == "due_at" ?
        "DueDateInput__Container" :
        "DueDateRow__LockUnlockInput"
    },

    render() {
      if (this.props.disabled) {
        return (
          <div className="ic-Form-control">
            <label className="ic-Label" htmlFor={this.props.dateType}>{this.props.labelText}</label>
            <div className="ic-Input-group">
              <input
                id={this.props.dateType}
                readOnly
                type="text"
                className={`ic-Input ${this.props.inputClasses}`}
                defaultValue={this.formattedDate()}
              />
              <div className="ic-Input-group__add-on" role="presentation" aria-hidden="true" tabIndex="-1">
                <button className="Button Button--icon-action disabled" aria-disabled="true" type="button">
                  <i className="icon-calendar-month" role="presentation"/>
                </button>
              </div>
            </div>
          </div>
        );
      }

      return (
        <div>
          <label
            id={this.props.labelledBy}
            className="Date__label"
          >{this.props.labelText}</label>
          <div
            ref="datePickerWrapper"
            className={this.wrapperClassName()}
          >
            <input
              type            = "text"
              ref             = "dateInput"
              title           = {accessibleDateFormat()}
              data-tooltip    = ""
              className       = {this.props.inputClasses}
              aria-labelledby = {this.props.labelledBy}
              data-row-key    = {this.props.rowKey}
              data-date-type  = {this.props.dateType}
              defaultValue    = {this.formattedDate()}
            />
          </div>
        </div>
      )
    }
  });

  return DueDateCalendarPicker
});
