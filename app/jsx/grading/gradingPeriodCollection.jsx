define([
  'react',
  'react-addons-update',
  'jsx/grading/gradingPeriod',
  'jquery',
  'i18n!external_tools',
  'underscore',
  'convert_case',
  'jquery.instructure_misc_plugins'
],
function(React, update, GradingPeriod, $, I18n, _, ConvertCase) {

  const periodsAreLoaded = (state) => {
    return state.periods !== null;
  };

  let GradingPeriodCollection = React.createClass({

    propTypes: {
      // no props
    },

    getInitialState: function() {
      return {
        periods: null,
        readOnly: false,
        disabled: false,
        saveDisabled: true,
        canChangeGradingPeriodsSetting: false
      };
    },

    componentWillMount: function() {
      this.getPeriods();
    },

    getPeriods: function() {
      let self = this;
      $.getJSON(ENV.GRADING_PERIODS_URL)
        .success(function(periods) {
          self.setState({
            periods: self.deserializePeriods(periods),
            readOnly: periods.grading_periods_read_only,
            canChangeGradingPeriodsSetting: periods.can_toggle_grading_periods,
            disabled: false,
            saveDisabled: _.isEmpty(periods.grading_periods)
          });
        })
        .error(function(){
          $.flashError(I18n.t('There was a problem fetching periods'));
        });
    },

    deserializePeriods: function(periods) {
      return _.map(periods.grading_periods, period => {
        let newPeriod = ConvertCase.camelize(period);
        newPeriod.startDate = new Date(period.start_date);
        newPeriod.endDate = new Date(period.end_date);
        newPeriod.closeDate = new Date(period.close_date || period.end_date);
        return newPeriod;
      });
    },

    deleteGradingPeriod: function(id) {
      if (id.indexOf('new') > -1) {
        this.removeDeletedGradingPeriod(id);
      } else {
        let self = this;
        $('#grading-period-' + id).confirmDelete({
          url: ENV.GRADING_PERIODS_URL + '/' + id,
          message: I18n.t('Are you sure you want to delete this grading period?'),
          success: function () {
            $.flashMessage(I18n.t('The grading period was deleted'));
            if (self.lastRemainingPeriod()) {
              self.getPeriods();
            } else {
              self.removeDeletedGradingPeriod(id);
            }
          },
          error: function() {
            $.flashError(I18n.t('There was a problem deleting the grading period'));
          }
        });
      }
    },

    lastRemainingPeriod: function() {
      return this.state.periods.length === 1;
    },

    removeDeletedGradingPeriod: function(id) {
      let newPeriods = _.reject(this.state.periods, period => period.id === id);
      this.setState({periods: newPeriods});
    },

    getPeriodById: function(id) {
      return _.find(this.state.periods, period => period.id === id);
    },

    areGradingPeriodsValid: function() {
      return _.every(this.state.periods, (period) => {
        return this.isTitleCompleted(period) &&
        this.areDatesValid(period) &&
        this.isStartDateBeforeEndDate(period) &&
        this.areNoDatesOverlapping(period)
      });
    },

    areDatesOverlapping: function(targetPeriod) {
      let target = this.getPeriodById(targetPeriod.id);
      let otherPeriods = _.reject(this.state.periods, p => (p.id === target.id));
      if (_.isEmpty(otherPeriods)) return false;
      return _.any(otherPeriods, (period) => {
        // http://c2.com/cgi/wiki?TestIfDateRangesOverlap
        return (
          target.startDate < period.endDate &&
          period.startDate < target.endDate
        );
      });
    },

    areNoDatesOverlapping: function(targetPeriod) {
      if(this.areDatesOverlapping(targetPeriod)) {
        $.flashError(I18n.t('Grading periods must not overlap'));
        return false;
      } else {
        return true;
      }
    },

    areDatesValid: function(period) {
      if (!isNaN(period.startDate) && !isNaN(period.endDate)) {
        return true;
      } else {
        $.flashError(I18n.t('All dates fields must be present and formatted correctly'));
        return false;
      }
    },

    isStartDateBeforeEndDate: function(period) {
      if (period.startDate < period.endDate) {
        return true;
      } else {
        $.flashError(I18n.t('All start dates must be before the end date'));
        return false;
      }
    },

    isTitleCompleted: function(period) {
      if ((period.title).trim().length > 0) {
        return true;
      } else {
        $.flashError(I18n.t('All grading periods must have a title'));
        return false;
      }
    },

    updateGradingPeriodCollection: function(updatedGradingPeriodComponent) {
      let attrs = $.extend(true, {}, updatedGradingPeriodComponent.props, updatedGradingPeriodComponent.state);
      let existingGradingPeriod = this.getPeriodById(attrs.id);
      let indexToUpdate = this.state.periods.indexOf(existingGradingPeriod);
      let updatedPeriods = update(this.state.periods, {$splice: [[indexToUpdate, 1, attrs]]});
      this.setState({ periods: updatedPeriods });
    },

    serializeDataForSubmission: function() {
      let periods = _.map(this.state.periods, function(period) {
        return {
          id: period.id,
          title: period.title,
          start_date: period.startDate,
          end_date: period.endDate
        };
      });
      return { 'grading_periods': periods };
    },

    batchUpdatePeriods: function() {
      this.setState({disabled: true}, () => {
        if (this.areGradingPeriodsValid()) {
          $.ajax({
            type: 'PATCH',
            url: ENV.GRADING_PERIODS_URL + '/batch_update',
            dataType: 'json',
            contentType: 'application/json',
            data: JSON.stringify(this.serializeDataForSubmission()),
            context: this
          })
            .success(function (response) {
              $.flashMessage(I18n.t('All changes were saved'));
              this.setState({disabled: false, periods: this.deserializePeriods(response)});
            })
            .error(function (error) {
              this.setState({disabled: false});
              $.flashError(I18n.t('There was a problem saving the grading period'));
            });
        } else {
          this.setState({disabled: false});
        }
      });
    },

    renderLinkToSettingsPage: function() {
      if (this.state.canChangeGradingPeriodsSetting && this.state.periods && this.state.periods.length <= 1) {
        return (
          <span id='disable-feature-message' ref='linkToSettings'>
            {I18n.t('You can disable this feature ')}
            <a href={ENV.CONTEXT_SETTINGS_URL + '#tab-features'} aria-label={I18n.t('Feature Options')}> {I18n.t('here.')} </a>
          </span>);
      }
    },

    renderSaveButton: function() {
      if (periodsAreLoaded(this.state) && !this.state.readOnly && _.all(this.state.periods, period => period.permissions.update)) {
        let buttonText = this.state.disabled ? I18n.t('Updating') : I18n.t('Save');
        return (
          <div className='form-actions'>
            <button className='Button btn-primary btn save_button'
                    id='update-button'
                    disabled={this.state.disabled || this.state.saveDisabled}
                    onClick={this.batchUpdatePeriods}>
              {buttonText}
            </button>
          </div>
        );
      }
    },

    renderGradingPeriods: function() {
      if (!this.state.periods) return null;
      return _.map(this.state.periods, period => {
        return (
          <GradingPeriod key={period.id}
                         ref={"grading_period_" + period.id}
                         id={period.id}
                         title={period.title}
                         startDate={period.startDate}
                         endDate={period.endDate}
                         closeDate={period.closeDate}
                         permissions={period.permissions}
                         readOnly={this.state.readOnly}
                         disabled={this.state.disabled}
                         weight={period.weight}
                         updateGradingPeriodCollection={this.updateGradingPeriodCollection}
                         onDeleteGradingPeriod={this.deleteGradingPeriod}/>
        );
      });
    },

    render: function () {
      return (
        <div>
          <div id='messages'>
            {this.renderLinkToSettingsPage()}
          </div>
          <div id='grading_periods' className='content-box'>
            {this.renderGradingPeriods()}
          </div>
          {this.renderSaveButton()}
        </div>
      );
    }
  });

  return GradingPeriodCollection;
});
