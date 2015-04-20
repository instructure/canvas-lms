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

    getInitialState: function() {
      return {periods: null, needsToCopy: false, disabled: false};
    },

    componentWillMount: function() {
      this.getPeriods();
    },

    getPeriods: function(idToExclude) {
      var self = this;
      $.getJSON(ENV.GRADING_PERIODS_URL)
      .done(function(periods){
        self.gotPeriods(periods, idToExclude);
      })
    },

    gotPeriods: function(periods, idToExclude) {
      var unsavedPeriods = [];
      if (this.state.periods) {
        unsavedPeriods = this.state.periods.filter(p => p.id.indexOf('new') > -1 && p.id !== idToExclude);
      }
      var camelizedPeriods = _.map(periods.grading_periods, function (gradingPeriod) { return ConvertCase.camelize(gradingPeriod) });
      this.setState({
        periods: camelizedPeriods.concat(unsavedPeriods),
        needsToCopy: !this.canManageAtLeastOnePeriod(camelizedPeriods) && camelizedPeriods.length > 0,
        disabled: false,
      });
    },

    componentDidUpdate: function(prevProps, prevState) {
      if (prevState.periods) {
        var removedAGradingPeriod = this.state.periods.length < prevState.periods.length;
        if (removedAGradingPeriod) this.refs.addPeriodButton.getDOMNode().focus();
      }
    },

    canManageAtLeastOnePeriod: function(periods) {
      return _.any(periods, function(period){ return period.permissions.manage });
    },

    copyTemplatePeriods: function(periodsToCopy, idToExclude) {
      var validPeriods = periodsToCopy.filter(p => p.shouldUpdateBeDisabled !== true);
      this.setState({disabled: true}, function(){
          var copyDfds = validPeriods.map(gradingPeriod => {
            return $.ajaxJSON(ENV.GRADING_PERIODS_URL, "POST", JSON.stringify({
              grading_periods: [{
                title: gradingPeriod.title,
                start_date: gradingPeriod.startDate,
                end_date: gradingPeriod.endDate,
              }]
            }), null, null, {contentType: "application/json"});
          });
          $.when.apply(null, copyDfds).then((responses) => {
            this.getPeriods(idToExclude);
          });
      });
    },

    componentDidUpdate: function(prevProps, prevState) {
      if (prevState.periods) {
        var removedAGradingPeriod = this.state.periods.length < prevState.periods.length;
        if (removedAGradingPeriod) this.refs.addPeriodButton.getDOMNode().focus();
      }
    },

    deleteGradingPeriod: function(event, id) {
      var $gradingPeriodElement = $(event.target).parents('.grading-period'),
        self = this;

      if (id.indexOf('new') > -1) {
        this.removeDeletedGradingPeriod(id);
        return;
      }

      if (this.state.needsToCopy) {
        var periodsToCopy = _.reject(this.state.periods, p => p.id === id || isNaN(p.id));
        var confirmDelete = confirm("Are you sure you want to remove this grading period?");
        if (confirmDelete) this.copyTemplatePeriods(periodsToCopy);
      } else {
        $gradingPeriodElement.confirmDelete({
          url: ENV.GRADING_PERIODS_URL + "/" + id,
          message: I18n.t("Are you sure you want to delete this grading period?"),
          success: function () {
            $.flashMessage(I18n.t("The grading period was deleted"));
            if (self.lastRemainingPeriod()) {
              self.getPeriods();
            } else {
              self.removeDeletedGradingPeriod(id);
            }
          },
          error: function() {
            $.flashError(I18n.t("There was a problem deleting the grading period"));
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
      var newPeriods = _.reject(this.state.periods, function(period){ return period.id === id });
      if (this.lastRemainingPeriod()) {
        this.getPeriods();
      } else {
        this.setState({periods: newPeriods});
      }
    },

    getCreateGradingPeriodCSS: function() {
      var cssClasses = "center-md new-grading-period pad-box border border-round";

      if (!this.state.periods || this.state.periods.length === 0) {
        cssClasses += " no-active-grading-periods";
      }

      return cssClasses;
    },

    createNewGradingPeriod: function() {
      var newPeriod = {title: '', startDate: '', endDate: '', id: _.uniqueId('new'), permissions: { read: true, manage: true }};
      var periods = update(this.state.periods, {$push: [newPeriod]});
      this.setState({periods: periods});
    },

    getPeriodById: function(id) {
      return _.find(this.state.periods, function(period){ return period.id === id });
    },

    updateGradingPeriodCollection: function(updatedGradingPeriod, permissions, previousStateId) {
      if (this.state.needsToCopy && previousStateId) {
        var periodsToCopy = _.reject(this.state.periods, p => p.id === previousStateId || isNaN(p.id));
        this.copyTemplatePeriods(periodsToCopy, previousStateId);
      } else if (previousStateId) {
        this.getPeriods(previousStateId);
      } else {
        updatedGradingPeriod.permissions = permissions;
        var id = updatedGradingPeriod.id;
        var existingGradingPeriod = this.getPeriodById(id);
        var indexToUpdate = this.state.periods.indexOf(existingGradingPeriod);
        var updatedPeriods = update(this.state.periods, {$splice: [[indexToUpdate, 1, updatedGradingPeriod]]});
        this.setState({ periods: updatedPeriods });
      }
    },

    renderLinkToSettingsPage: function() {
      if (this.state.periods && this.state.periods.length <= 1) {
        return (
          <span id="disable-feature-message">
            {I18n.t("You can disable this feature ")}
            <a href={ENV.CONTEXT_SETTINGS_URL + "#tab-features"} aria-label={I18n.t("Feature Options")}> {I18n.t("here.")} </a>
          </span>);
      }
    },

    renderAdminPeriodsMessage: function() {
      if (this.state.periods && this.state.periods.length > 0 && !this.canManageAtLeastOnePeriod(this.state.periods)) {
        return <span id="admin-periods-message"> {I18n.t("These grading periods were created for you by an administrator.")} </span>;
      }
    },

    renderGradingPeriods: function() {
      if (!this.state.periods) return null;
      return this.state.periods.map(function(period){
        return (<GradingPeriod id={period.id} key={period.id} title={period.title} startDate={period.startDate}
                               endDate={period.endDate} weight={period.weight} permissions={period.permissions}
                               onDeleteGradingPeriod={this.deleteGradingPeriod} cannotDelete={this.cannotDeleteLastPeriod}
                               updateGradingPeriodCollection={this.updateGradingPeriodCollection}
                               disabled={this.state.disabled}/>);
      }, this);
    },

    render: function () {
      return(
        <div>
          <div id="messages">
            {this.renderAdminPeriodsMessage()}
            {this.renderLinkToSettingsPage()}
          </div>
          <div id="grading_periods" className="content-box">
            {this.renderGradingPeriods()}
          </div>
          <div className={this.getCreateGradingPeriodCSS()}>
            <button id="add-period-button" className="Button--link" ref="addPeriodButton"
                    onClick={this.createNewGradingPeriod} disabled={this.state.disabled}>
              <i className="icon-plus grading-period-add-icon"/>
              {I18n.t('Add Grading Period')}
            </button>
          </div>
        </div>
      );
    }
  });

  return GradingPeriodCollection;
});
