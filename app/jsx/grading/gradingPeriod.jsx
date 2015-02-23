/** @jsx React.DOM */

define([
  'react',
  'jquery',
  'i18n!external_tools',
  'underscore',
  'jquery.instructure_date_and_time'
],
function(React, $, I18n, _) {

  var GradingPeriod = React.createClass({

    getInitialState: function(){
      return {
        title: this.props.title,
        startDate: this.parseDateTime(this.props.startDate),
        endDate: this.parseDateTime(this.props.endDate),
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
      var dateNode = $(this.getDOMNode()).find('.date_field');
      dateNode.datetime_field();
      dateNode.on('change', this.handleDateChange)
    },

    handleDateChange: function(event){
      var updatedState = {};
      updatedState[event.target.name] = this.parseDateTime(event.target.value);
      this.setState(updatedState, function() {
        this.replaceInputWithDate(this.refs[event.target.name]);
        this.checkFormForUpdates();
        this.props.updateGradingPeriodCollection(this.state);
      });
    },

    formatDataForSubmission: function () {
      return {
        title: this.state.title,
        start_date: this.state.startDate,
        end_date: this.state.endDate
      };
    },

    saveGradingPeriod: function () {
      if (this.isStartDateBeforeEndDate()) {
        var isNewGradingPeriod = this.isNewGradingPeriod();
        var requestType = (!isNewGradingPeriod) ? 'PUT' : 'POST';
        var url = ENV.GRADING_PERIODS_URL + ((!isNewGradingPeriod) ? ('/' + this.state.id) : '');
        var self = this;

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
                 self.props.updateGradingPeriodCollection(self.state, oldId);
              });
            } else {
              self.setState({shouldUpdateBeDisabled: true}, function () {
                self.props.updateGradingPeriodCollection(this.state);
              });
            }
            $('#add-grading-period-button').focus();
          })
          .error(function (error) {
            $.flashError(I18n.t('There was a problem saving the grading period'));
          });
      } else {
        var message = I18n.t('Start date must be before end date');
        $('#period_start_date_' + this.state.id).errorBox(message);
      }
    },

    isStartDateBeforeEndDate: function() {
      var startDate = Date.parse(this.state.startDate);
      var endDate = Date.parse(this.state.endDate);
      return startDate < endDate;
    },

    isNewGradingPeriod: function() {
      return this.state.id.indexOf('new') > -1;
    },

    checkFormForUpdates: function() {
      var shouldUpdateBeDisabled = !this.formIsCompleted() || !this.inputsHaveChanged();
      this.setState({shouldUpdateBeDisabled: shouldUpdateBeDisabled});
    },

    formIsCompleted: function() {
      var titleCompleted = (this.state.title).trim().length > 0;
      var startDateCompleted = (this.state.startDate).trim().length > 0;
      var endDateCompleted = (this.state.endDate).trim().length > 0;
      return titleCompleted && startDateCompleted && endDateCompleted;
    },

    inputsHaveChanged: function() {
      if(this.state.title !== this.props.title) return true;
      if(this.state.startDate !== this.parseDateTime(this.props.startDate)) return true;
      if(this.state.endDate !== this.parseDateTime(this.props.endDate)) return true;
      return false;
    },

    parseDateTime: function(inputDate) {
      return $.datetime.process(inputDate);
    },

    formatDateForDisplay: function(uglyDate) {
      return $.datetimeString(uglyDate, { format: 'medium' });
    },

    handleTitleChange: function(event) {
      this.setState({title: event.target.value}, function () {
        this.checkFormForUpdates();
        this.props.updateGradingPeriodCollection(this.state);
      });
    },

    replaceInputWithDate: function(dateRef) {
      var dateInput = dateRef.getDOMNode().value
      if(this.isValidDateInput(dateInput)){
        var inputAsDate = this.parseDateTime(dateInput)
        dateRef.getDOMNode().value = this.formatDateForDisplay(inputAsDate);
      }
    },

    isValidDateInput: function(dateInput) {
      return this.parseDateTime(dateInput) !== "";
    },

    triggerDeleteGradingPeriod: function(event) {
      this.props.onDeleteGradingPeriod(event, this.state.id);
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
                disabled={this.state.shouldUpdateBeDisabled}
                onClick={this.saveGradingPeriod}>
          {buttonText}
        </button>
      );
    },

    render: function () {
      return (
        <div className="grading-period pad-box-mini border border-trbl border-round">
          <div className="grid-row pad-box-micro">
            <div className="col-xs-12 col-sm-6 col-lg-3">
              <label htmlFor={"period_title_" + this.state.id}>
                {I18n.t("Grading Period Name")}
              </label>
              <input id={"period_title_" + this.state.id}
                     type="text"
                     ref="title"
                     onChange={this.handleTitleChange}
                     value={this.state.title}/>

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
                     defaultValue={this.formatDateForDisplay(this.state.startDate)}/>

            </div>
            <div className="col-xs-12 col-sm-6 col-lg-3">
              <label htmlFor={"period_end_date_" + this.state.id}>
               {I18n.t("End Date")}
              </label>
              <input id={"period_end_date_" + this.state.id} type="text"
                     className="input-grading-period-date date_field"
                     ref="endDate"
                     name="endDate"
                     defaultValue={this.formatDateForDisplay(this.state.endDate)}/>

            </div>
            <div className="col-xs-12 col-sm-6 col-lg-3 manage-buttons-container">
              <div className="content-box">
                <div className="buttons-grid-row grid-row">
                  <div className="col-xs">
                    {this.renderSaveUpdateButton()}
                  </div>
                  <div className="col-xs">
                    <div className="icon-delete-container" role="button" tabIndex="0" onClick={this.triggerDeleteGradingPeriod}>
                    <span className="screenreader-only">{I18n.t("Delete grading period")}</span>
                      <i title={I18n.t("Delete grading period")} className="icon-delete-grading-period hover icon-x"></i>
                    </div>
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
