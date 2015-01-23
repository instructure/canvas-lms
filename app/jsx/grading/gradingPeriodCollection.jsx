/** @jsx React.DOM */

define([
  'react',
  'jsx/grading/gradingPeriod',
  'jquery',
  'i18n!external_tools',
  'underscore',
  'jquery.instructure_misc_plugins'
],
function(React, GradingPeriod, $, I18n, _) {

  var GradingPeriodCollection = React.createClass({

    getInitialState: function() {
      return {periods: null};
    },

    componentWillMount: function() {
      $.getJSON(ENV.GRADING_PERIODS_URL)
      .done(this.gotPeriods)
    },

    gotPeriods: function(periods) {
      this.setState({periods: periods.grading_periods});
    },

    deleteGradingPeriod: function(event, uniqueId) {
      var self = this,
        $period = $(event.target).parents(".grading-period");

      $period.confirmDelete({
        url: ENV.GRADING_PERIODS_URL + "/" + uniqueId,
        message: I18n.t("Are you sure you want to delete this grading period?"),
        success: function() {
          $(this).slideUp(function() {
            $(this).remove();
          });
          var newPeriods = _.reject(self.state.periods, function(period){ return period.id === uniqueId });
          self.setState({periods: newPeriods});
        },
        error: function() {
          $.flashError(I18n.t("There was a problem deleting the grading period"));
        }
      });
    },

    renderGradingPeriods: function() {
      if(!this.state.periods){
        return null;
      } else if(this.state.periods.length === 0){
        return <h3>{I18n.t("No grading periods to display")}</h3>;
      }
      var self = this;
      return this.state.periods.map(function(period){
        return (<GradingPeriod key={period.id} uniqueId={period.id} title={period.title}
                               startDate={new Date(period.start_date)} endDate={new Date(period.end_date)}
                               weight={period.weight} onDeleteGradingPeriod={self.deleteGradingPeriod}/>);
      });
    },

    render: function () {
      return(
        <div id="grading_periods" className="content-box">
          {this.renderGradingPeriods()}
        </div>
      );
    }
  });

  return GradingPeriodCollection;
});
