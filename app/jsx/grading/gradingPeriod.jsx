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

    formatDataForSubmission: function () {
      return {
        title: this.state.title,
        start_date: this.state.startDate,
        end_date: this.state.endDate
      };
    },

    handleTitleChange: function(event) {
      this.setState({title: event.target.value}, function () {
        this.setUpdateButtonState();
        this.props.updateGradingPeriodCollection(this.state, this.props.permissions);
      });
    },

    handleDateChange: function(event) {
      var dateNode = this.refs[event.target.name].getDOMNode();
      var updatedDate = $(dateNode).data('invalid') ? new Date('invalid date') : $(dateNode).data('unfudged-date');
      var updatedState = {};
      updatedState[event.target.name] = updatedDate;
      this.setState(updatedState, function() {
        this.replaceInputWithDate(this.refs[event.target.name]);
        this.setUpdateButtonState();
        this.props.updateGradingPeriodCollection(this.state, this.props.permissions);
      });
    },

    formatDateForDisplay: function(date) {
      return $.datetimeString(date, { format: 'medium', localized: false, timezone: ENV.CONTEXT_TIMEZONE });
    },

    replaceInputWithDate: function(dateRef) {
      var date = this.state[dateRef.getDOMNode().name];
      dateRef.getDOMNode().value = this.formatDateForDisplay(date);
    },

    saveGradingPeriod: function() {
      var self = this;
      var url = ENV.GRADING_PERIODS_URL;
      var requestType;

      if (this.isEndDateBeforeStartDate()) {
        var message = I18n.t('Start date must be before end date');
        $('#period_start_date_' + this.state.id).errorBox(message);
      } else if (this.props.isOverlapping(this.state.id)) {
        var message = I18n.t('This Grading Period overlaps');
        $.flashError(message);
      } else {
        if (!this.isNewGradingPeriod() && this.props.permissions.manage) {
          requestType = 'PUT';
          url = url + '/' + this.state.id;
        } else {
          requestType = 'POST';
        }

        $('#period_start_date_' + this.state.id).hideErrors();

        $.ajax({
          type: requestType,
          url: url,
          dataType: 'json',
          contentType: 'application/json',
          data: JSON.stringify({grading_periods: [this.formatDataForSubmission()]})
        })
          .success(function (gradingPeriod) {
            $.flashMessage(I18n.t('The grading period was saved'));
            if (requestType === 'POST') {
              var oldId = self.state.id,
                updatedGradingPeriod = gradingPeriod.grading_periods[0],
                newState = {
                  shouldUpdateBeDisabled: true,
                  id: updatedGradingPeriod.id,
                  title: updatedGradingPeriod.title,
                  startDate: new Date(updatedGradingPeriod.start_date),
                  endDate: new Date(updatedGradingPeriod.end_date)
                };
              self.setState(newState, function () {
                 self.props.updateGradingPeriodCollection(self.state, updatedGradingPeriod.permissions, oldId);
              });
            } else {
              self.setState({shouldUpdateBeDisabled: true}, function () {
                self.props.updateGradingPeriodCollection(self.state, self.props.permissions);
              });
            }
            $('#add-period-button').focus();
          })
          .error(function (error) {
            $.flashError(I18n.t('There was a problem saving the grading period'));
          });
      }
    },

    isEndDateBeforeStartDate: function() {
      return this.state.startDate > this.state.endDate;
    },

    isNewGradingPeriod: function() {
      return this.state.id.indexOf('new') > -1;
    },

    setUpdateButtonState: function() {
      var shouldUpdateBeDisabled = !this.formIsComplete();
      this.setState({shouldUpdateBeDisabled: shouldUpdateBeDisabled});
    },

    formIsComplete: function() {
      var titleCompleted = (this.state.title).trim().length > 0;
      return titleCompleted && this.datesAreValid();
    },

    datesAreValid: function() {
      return !isNaN(this.state.startDate) && !isNaN(this.state.endDate);
    },

    triggerDeleteGradingPeriod: function() {
      this.props.onDeleteGradingPeriod(this.state.id);
    },

    renderSaveUpdateButton: function() {
      var className = 'update-button Button';
      var buttonText = I18n.t('Update');

      if (this.isNewGradingPeriod()) {
        buttonText = I18n.t('Save');
        className += ' btn-primary'
      }

      if (!this.state.shouldUpdateBeDisabled) {
        className += ' btn-primary'
      }

      return (
        <button className={className}
                disabled={this.state.shouldUpdateBeDisabled || this.props.disabled}
                onClick={this.saveGradingPeriod}>
          {buttonText}
        </button>
      );
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
                    {this.renderSaveUpdateButton()}
                  </div>
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
