define([
  'react',
  'underscore',
  'jquery',
  'convert_case',
  'axios',
  'i18n!grading_periods',
  'jsx/grading/GradingPeriodSet'
], function(React, _, $, ConvertCase, axios, I18n, GradingPeriodSet) {

  const deserializeSets = function(sets) {
    return _.map(sets, function(set) {
      let newSet = ConvertCase.camelize(set);
      newSet.id = set.id.toString();
      newSet.gradingPeriods = deserializePeriods(set.grading_periods);
      return newSet;
    });
  };

  const deserializePeriods = function(periods) {
    return _.map(periods, function(period) {
      let newPeriod = ConvertCase.camelize(period);
      newPeriod.id = period.id.toString();
      newPeriod.startDate = new Date(period.start_date);
      newPeriod.endDate = new Date(period.end_date);
      return newPeriod;
    });
  };

  let GradingPeriodSetCollection = React.createClass({
    propTypes: {
      URLs: React.PropTypes.shape({
        gradingPeriodSetsURL: React.PropTypes.string.isRequired
      }).isRequired
    },

    getInitialState: function() {
      return { gradingPeriodSets: [] };
    },

    componentWillMount: function() {
      this.getSets();
    },

    getSets: function() {
      axios.get(this.props.URLs.gradingPeriodSetsURL)
           .then((response) => {
              this.setState({
                gradingPeriodSets: deserializeSets(response.data.grading_period_sets)
              });
            })
            .catch(() => {
              $.flashError(I18n.t("An error occured while fetching grading period sets."));
            });
    },

    renderSets: function() {
      return _.map(this.state.gradingPeriodSets, function(set) {
        return (
          <GradingPeriodSet
            key={set.id}
            set={set}
            gradingPeriods={set.gradingPeriods}
          />
        );
      });
    },

    render: function() {
      return (
        <div>
          <div className="GradingPeriodSets__toolbar header-bar no-line">
            <div className="header-bar-right">
            </div>
          </div>
          <div>
            {this.renderSets()}
          </div>
        </div>
      );
    }
  });

  return GradingPeriodSetCollection;
});
