/** @jsx React.DOM */

define([
  'react',
  'jsx/grading/gradingPeriod',
  'jquery',
  'i18n!external_tools',
  'underscore',
  'convert_case',
  'jquery.instructure_misc_plugins'
],
function(React, GradingPeriod, $, I18n, _, ConvertCase) {

  var update = React.addons.update;
  var GradingPeriodCollection = React.createClass({

    propTypes: {
      // no props
    },

    getInitialState: function() {
      return { periods: null, needsToCopy: false, disabled: false, saveDisabled: true};
    },

    componentWillMount: function() {
      this.getPeriods();
    },

    getPeriods: function() {
      var self = this;
      $.getJSON(ENV.GRADING_PERIODS_URL)
        .success(function(periods){
          self.setState({
            periods: self.deserializePeriods(periods),
            needsToCopy: !self.canManageAtLeastOnePeriod(self.deserializePeriods(periods)) && periods.grading_periods.length > 0,
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
        var newPeriod = ConvertCase.camelize(period);
        newPeriod.startDate = new Date(period.start_date);
        newPeriod.endDate = new Date(period.end_date);
        return newPeriod;
      });
    },

    componentDidUpdate: function(prevProps, prevState) {
      if (prevState.periods) {
        var removedAGradingPeriod = this.state.periods.length < prevState.periods.length;
        if (removedAGradingPeriod) this.refs.addPeriodButton.getDOMNode().focus();
      }
    },

    canManageAtLeastOnePeriod: function(periods) {
      return _.any(periods, period => period.permissions.manage);
    },

    copyTemplatePeriods: function(periodsToCopy) {
      var validPeriods = periodsToCopy.filter(p => p.shouldUpdateBeDisabled !== true);
      this.setState({disabled: true}, function(){
          var copyDfds = validPeriods.map(gradingPeriod => {
            return $.ajaxJSON(ENV.GRADING_PERIODS_URL, 'POST', JSON.stringify({
              grading_periods: [{
                title: gradingPeriod.title,
                start_date: gradingPeriod.startDate,
                end_date: gradingPeriod.endDate,
              }]
            }), null, null, {contentType: 'application/json'});
          });
          $.when.apply(null, copyDfds).then((responses) => {
            this.getPeriods();
          });
      });
    },

    deleteGradingPeriod: function(id) {
      if (id.indexOf('new') > -1) {
        this.removeDeletedGradingPeriod(id);
      } else if (this.state.needsToCopy) {
        var periodsToCopy = _.reject(this.state.periods, p => p.id === id || isNaN(p.id));
        var confirmDelete = confirm(I18n.t('Are you sure you want to remove this grading period?'));
        if (confirmDelete) this.copyTemplatePeriods(periodsToCopy);
      } else {
        var self = this;
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

    cannotDeleteLastPeriod: function() {
      return this.lastRemainingPeriod() && !this.state.periods[0].permissions.manage;
    },

    removeDeletedGradingPeriod: function(id) {
      if (this.lastRemainingPeriod()) {
        this.getPeriods();
      } else {
        var newPeriods = _.reject(this.state.periods, period => period.id === id);
        this.setState({periods: newPeriods});
      }
    },

    getCreateGradingPeriodCSS: function() {
      var cssClasses = 'center-md new-grading-period pad-box border border-round';
      if (!this.state.periods || this.state.periods.length === 0) {
        cssClasses += ' no-active-grading-periods';
      }

      return cssClasses;
    },

    createNewGradingPeriod: function() {
      var newPeriod = { title: '', startDate: new Date(''), endDate: new Date(''), id: _.uniqueId('new'),
        permissions: { read: true, manage: true } };
      var periods = update(this.state.periods, {$push: [newPeriod]});
      this.setState({periods: periods, saveDisabled: false});
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
      var target = this.getPeriodById(targetPeriod.id);
      var otherPeriods = _.reject(this.state.periods, p => (p.id === target.id));
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
      var attrs = $.extend(true, {}, updatedGradingPeriodComponent.props, updatedGradingPeriodComponent.state);
      var id = updatedGradingPeriodComponent.state.id;
      var existingGradingPeriod = this.getPeriodById(id);
      var indexToUpdate = this.state.periods.indexOf(existingGradingPeriod);
      var updatedPeriods = update(this.state.periods, {$splice: [[indexToUpdate, 1, attrs]]});
      this.setState({ periods: updatedPeriods });
    },

    serializeDataForSubmission: function() {
      var periods = _.map(this.state.periods, function(period) {
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
            type: 'PUT',
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
      if (this.state.periods && this.state.periods.length <= 1) {
        return (
          <span id='disable-feature-message' ref='linkToSettings'>
            {I18n.t('You can disable this feature ')}
            <a href={ENV.CONTEXT_SETTINGS_URL + '#tab-features'} aria-label={I18n.t('Feature Options')}> {I18n.t('here.')} </a>
          </span>);
      }
    },

    renderSaveButton: function() {
      var buttonText = this.state.disabled ? I18n.t('Updating') : I18n.t('Save');
      return (
        <button className='Button btn-primary btn save_button'
                id='update-button'
                disabled={this.state.disabled || this.state.saveDisabled}
                onClick={this.batchUpdatePeriods}>
          {buttonText}
        </button>
      );
    },

    renderAdminPeriodsMessage: function() {
      if (this.state.periods && this.state.periods.length > 0 && !this.canManageAtLeastOnePeriod(this.state.periods)) {
        return <span id='admin-periods-message' ref='adminPeriodsMessage'> {I18n.t('These grading periods were created for you by an administrator.')} </span>;
      }
    },

    renderGradingPeriods: function() {
      if (!this.state.periods) return null;
      return _.map(this.state.periods, period => {
        return (<GradingPeriod id={period.id} key={period.id} title={period.title} startDate={period.startDate}
                               endDate={period.endDate} weight={period.weight} permissions={period.permissions}
                               onDeleteGradingPeriod={this.deleteGradingPeriod} cannotDelete={this.cannotDeleteLastPeriod}
                               updateGradingPeriodCollection={this.updateGradingPeriodCollection}
                               disabled={this.state.disabled} />);
      });
    },

    render: function () {
      return(
        <div>
          <div id='messages'>
            {this.renderAdminPeriodsMessage()}
            {this.renderLinkToSettingsPage()}
          </div>
          <div id='grading_periods' className='content-box'>
            {this.renderGradingPeriods()}
          </div>
          <div className={this.getCreateGradingPeriodCSS()}>
            <button id='add-period-button' className='Button--link' ref='addPeriodButton'
                    onClick={this.createNewGradingPeriod} disabled={this.state.disabled}>
              <i className='icon-plus grading-period-add-icon'/>
              {I18n.t('Add Grading Period')}
            </button>
          </div>
          <div className='form-actions'>
            {this.renderSaveButton()}
          </div>
        </div>
      );
    }
  });

  return GradingPeriodCollection;
});
