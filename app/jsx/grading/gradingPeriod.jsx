/** @jsx React.DOM */

define([
  'react',
  'jquery',
  'i18n!external_tools',
  'underscore',
  'jquery.instructure_date_and_time'
],
function(React, $, I18n, _) {

  var types = React.PropTypes;
  var GradingPeriod = React.createClass({

    propTypes: {
      title: types.string.isRequired,
      startDate: types.instanceOf(Date).isRequired,
      endDate: types.instanceOf(Date).isRequired,
      permissions: types.object.isRequired,
      id: types.string.isRequired
    },

    getInitialState: function(){
      return {
        title: this.props.title,
        startDate: this.props.startDate,
        endDate: this.props.endDate,
        weight: this.props.weight,
        permissions: this.props.permissions,
        id: this.props.id,
        shouldUpdateBeDisabled: true
      };
    },

    componentWillReceiveProps: function(nextProps) {
      this.setState({
        title: nextProps.title,
        startDate: nextProps.startDate,
        endDate: nextProps.endDate,
        weight: nextProps.weight,
        permissions: nextProps.permissions
      });
    },

    componentDidMount: function() {
      if (this.isNewGradingPeriod()) {
        this.refs.title.getDOMNode().focus();
      }
      var dateField = $(this.getDOMNode()).find('.date_field');
      dateField.datetime_field();
      dateField.on('change', this.handleDateChange)
    },

    handleTitleChange: function(event) {
      this.setState({title: event.target.value}, function () {
        this.props.updateGradingPeriodCollection(this)
      });
    },

    handleDateChange: function(event) {
      var dateNode = this.refs[event.target.name].getDOMNode();
      var isInvalidDate = $(dateNode).data('invalid') || $(dateNode).data('blank');
      var updatedDate = isInvalidDate ? new Date('invalid date') : $(dateNode).data('unfudged-date');
      // If it's the end date, make sure the date goes _through_ the minute, not
      // just to the minute.
      if (dateNode.id.match(/period_end_date/)){
        updatedDate.setSeconds(59);
      }
      var updatedState = {};
      updatedState[event.target.name] = updatedDate;
      this.setState(updatedState, function() {
        this.replaceInputWithDate(this.refs[event.target.name]);
        this.props.updateGradingPeriodCollection(this);
      });
    },

    formatDateForDisplay: function(date) {
      return $.datetimeString(date, { format: 'medium', timezone: ENV.CONTEXT_TIMEZONE });
    },

    replaceInputWithDate: function(dateRef) {
      var date = this.state[dateRef.getDOMNode().name];
      dateRef.getDOMNode().value = this.formatDateForDisplay(date);
    },

    isNewGradingPeriod: function() {
      return this.state.id.indexOf('new') > -1;
    },

    triggerDeleteGradingPeriod: function() {
      this.props.onDeleteGradingPeriod(this.state.id);
    },

    renderDeleteButton: function() {
      if (this.props.cannotDelete()) {
        return null;
      } else {
        var cssClasses = "Button Button--icon-action icon-x icon-delete-grading-period";
        if (this.props.disabled) cssClasses += " disabled";
        return (
          <a role="button"
             href="#"
             className={cssClasses}
             onClick={this.triggerDeleteGradingPeriod}>
            <span className="screenreader-only">{I18n.t("Delete grading period")}</span>
          </a>
        );
      }
    },

    render: function () {
      return (
        <div id={"grading-period-" + this.state.id} className="grading-period pad-box-mini border border-trbl border-round">
          <div className="grid-row pad-box-micro">
            <div className="col-xs-12 col-sm-6 col-lg-3">
              <label htmlFor={"period_title_" + this.state.id}>
                {I18n.t("Grading Period Name")}
              </label>
              <input id={"period_title_" + this.state.id}
                     type="text"
                     ref="title"
                     onChange={this.handleTitleChange}
                     value={this.state.title}
                     disabled={this.props.disabled}/>

            </div>
            <div className="col-xs-12 col-sm-6 col-lg-3">
              <label htmlFor={"period_start_date_" + this.state.id}>
                {I18n.t("Start Date")}
              </label>
              <input id={"period_start_date_" + this.state.id}
                     type="text"
                     ref="startDate"
                     name="startDate"
                     className="input-grading-period-date date_field"
                     defaultValue={this.formatDateForDisplay(this.state.startDate)}
                     disabled={this.props.disabled}/>

            </div>
            <div className="col-xs-12 col-sm-6 col-lg-3">
              <label htmlFor={"period_end_date_" + this.state.id}>
               {I18n.t("End Date")}
              </label>
              <input id={"period_end_date_" + this.state.id} type="text"
                     className="input-grading-period-date date_field"
                     ref="endDate"
                     name="endDate"
                     defaultValue={this.formatDateForDisplay(this.state.endDate)}
                     disabled={this.props.disabled}/>

            </div>
            <div className="col-xs-12 col-sm-6 col-lg-3 manage-buttons-container">
              <div className="content-box">
                <div className="buttons-grid-row grid-row">
                  <div className="col-xs">
                    {this.renderDeleteButton()}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      );
    }
  });

  return GradingPeriod;
});
