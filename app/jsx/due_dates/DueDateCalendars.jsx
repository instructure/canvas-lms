define([
  'jquery',
  'react',
  'jsx/due_dates/DueDateCalendarPicker',
  'i18n!assignments',
  'classnames'
], ($, React, DueDateCalendarPicker, I18n, cx) => {

  var DueDateCalendars = React.createClass({

    propTypes: {
      dates: React.PropTypes.object.isRequired,
      rowKey: React.PropTypes.string.isRequired,
      overrides: React.PropTypes.array.isRequired,
      replaceDate: React.PropTypes.func.isRequired,
      sections: React.PropTypes.object.isRequired,
      disabled: React.PropTypes.bool.isRequired
    },

    // -------------------
    //      Rendering
    // -------------------

    labelledByForType(dateType){
      return "label-for-" + dateType + "-" + this.props.rowKey;
    },

    datePicker(dateType, labelText){
      const isNotUnlockAt = dateType !== "unlock_at";

      return (
        <DueDateCalendarPicker
          dateType        = {dateType}
          handleUpdate    = {this.props.replaceDate.bind(this, dateType)}
          rowKey          = {this.props.rowKey}
          labelledBy      = {this.labelledByForType(dateType)}
          dateValue       = {this.props.dates[dateType]}
          inputClasses    = {this.inputClasses(dateType)}
          disabled        = {this.props.disabled}
          labelText       = {labelText}
          isFancyMidnight = {isNotUnlockAt}
        />
      );
    },

    inputClasses(dateType){
      return cx({
        date_field: true,
        datePickerDateField: true,
        DueDateInput: dateType === "due_at",
        UnlockLockInput: dateType !== "due_at"
      });
    },

    render(){
      return (
        <div>
          <div className="ic-Form-group">
            <div className="ic-Form-control">
              {this.datePicker("due_at", I18n.t("Due"))}
            </div>
          </div>
          <div className="ic-Form-group">
            <div className="ic-Form-control">
              <div className="Available-from-to">
                <div className="from">{this.datePicker("unlock_at", I18n.t("Available from"))}</div>
                <div className="to">{this.datePicker("lock_at", I18n.t("Until"))}</div>
              </div>
            </div>
          </div>
        </div>
      );
    }
  });

  return DueDateCalendars;
});
