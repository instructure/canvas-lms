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
      return {periods: null};
    },

    componentWillMount: function() {
      this.getPeriods();
    },

    getPeriods: function() {
      $.getJSON(ENV.GRADING_PERIODS_URL)
      .done(this.gotPeriods)
    },

    gotPeriods: function(periods) {
      var camelizedPeriods = _.map(periods.grading_periods, function (gradingPeriod) {return ConvertCase.camelize(gradingPeriod)});
      this.setState({periods: camelizedPeriods});
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
        this.removeDeletedGradingPeriod($gradingPeriodElement, id);
        return;
      }

      $gradingPeriodElement.confirmDelete({
        url: ENV.GRADING_PERIODS_URL + "/" + id,
        message: I18n.t("Are you sure you want to delete this grading period?"),
        success: function () {
          $.flashMessage(I18n.t("The grading period was deleted"));
          if (self.lastRemainingPeriod()) {
            self.getPeriods();
          } else {
            self.removeDeletedGradingPeriod(this, id);
          }
        },
        error: function() {
          $.flashError(I18n.t("There was a problem deleting the grading period"));
        }
      });
    },

    lastRemainingPeriod: function() {
      return this.state.periods.length === 1;
    },

    removeDeletedGradingPeriod: function(gradingPeriodElement, id) {
      var newPeriods = _.reject(this.state.periods, function(period){ return period.id === id });
      this.setState({periods: newPeriods});
    },

    getCreateGradingPeriodCSS: function() {
      var cssClass = "center-md new-grading-period pad-box border border-round";

      if (!this.state.periods || this.state.periods.length === 0) {
        cssClass += " no-active-grading-periods";
      }

      return cssClass;
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
      if (previousStateId) {
        this.getPeriods();
      } else {
        updatedGradingPeriod.permissions = permissions;
        var id = updatedGradingPeriod.id;
        var existingGradingPeriod = this.getPeriodById(id);
        var indexToUpdate = this.state.periods.indexOf(existingGradingPeriod);
        var updatedPeriods = update(this.state.periods, {$splice: [[indexToUpdate, 1, updatedGradingPeriod]]});
        this.setState({ periods: updatedPeriods });
      }
    },

    renderGradingPeriods: function() {
      if (!this.state.periods) {
        return null;
      } else if(this.state.periods.length === 0) {
        return <h3>{I18n.t("No grading periods to display")}</h3>;
      }
      var self = this;
      return this.state.periods.map(function(period){
        return (<GradingPeriod id={period.id} key={period.id} title={period.title} startDate={period.startDate}
                               endDate={period.endDate} weight={period.weight} permissions={period.permissions}
                               onDeleteGradingPeriod={self.deleteGradingPeriod}
                               updateGradingPeriodCollection={self.updateGradingPeriodCollection}/>);
      });
    },

    render: function () {
      return(
        <div>
          <div id="grading_periods" className="content-box">
            {this.renderGradingPeriods()}
          </div>
          <div className={this.getCreateGradingPeriodCSS()}>
            <i className="icon-plus text-info grading-period-add-icon" />
            <a className="text-info" role="button" id="add-grading-period-button" ref="addPeriodButton" onClick={this.createNewGradingPeriod} href="#">
              {I18n.t('Add Grading Period')}
            </a>
          </div>
        </div>
      );
    }
  });

  return GradingPeriodCollection;
});
