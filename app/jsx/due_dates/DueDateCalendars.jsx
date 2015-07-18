/** @jsx React.DOM */

define([
  'underscore',
  'react',
  'jsx/due_dates/DueDateCalendarPicker',
  'i18n!assignments',
], (_ , React, DueDateCalendarPicker, I18n) => {

  var DueDateCalendarPicker = React.createFactory(DueDateCalendarPicker)

  var DueDateCalendars = React.createClass({

    propTypes: {
      dates: React.PropTypes.object.isRequired,
      rowKey: React.PropTypes.string.isRequired,
      overrides: React.PropTypes.array.isRequired,
      replaceDate: React.PropTypes.func.isRequired,
      sections: React.PropTypes.object.isRequired
    },

    // -------------------
    //      Rendering
    // -------------------

    labelledByForType(dateType){
      return "label-for-" + dateType + "-" + this.props.rowKey
    },

    datePicker(dateType){
      return (
        <DueDateCalendarPicker dateType     = {dateType}
                               handleUpdate = {this.props.replaceDate.bind(this, dateType)}
                               rowKey       = {this.props.rowKey}
                               labelledBy   = {this.labelledByForType(dateType)}
                               dateValue    = {this.props.dates[dateType]} />
      )
    },

    render(){
      return (
        <div>
          <div className="ic-Form-group">
            <div className="ic-Form-control">
              <label id         = {this.labelledByForType("due_at")}
                     className  = "Date__label"
                     title      = {I18n.t('Due - Format Like YYYY-MM-DD hh:mm')}>
                {I18n.t("Due")}
              </label>
              {this.datePicker("due_at")}
            </div>
          </div>
          <div className="ic-Form-group">
            <div className="ic-Form-control">
              <label id         = {this.labelledByForType("unlock_at")}
                     className  = "Date__label"
                     title      = {I18n.t('Available from - Format Like YYYY-MM-DD hh:mm')}>
                {I18n.t("Available from")}
              </label>
              <div className="Available-from-to">
                {this.datePicker("unlock_at")}
                <span id         = {this.labelledByForType("lock_at")}
                      className  = "Available-from-to__prompt"
                      title       = {I18n.t('Available until - Format Like YYYY-MM-DD hh:mm')}>
                  {I18n.t("until")}
                </span>
                {this.datePicker("lock_at")}
              </div>
            </div>
          </div>
        </div>
      )
    }

  })
  return DueDateCalendars
});
