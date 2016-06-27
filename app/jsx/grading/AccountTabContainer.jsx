define([
  'react',
  'react-dom',
  'jsx/grading/gradingStandardCollection',
  'jsx/grading/GradingPeriodSetCollection',
  'jquery',
  'i18n!grading_periods'
], function(React, ReactDOM, GradingStandardCollection, GradingPeriodSetCollection, $, I18n) {
  const { bool, string, shape } = React.PropTypes;

  let AccountTabContainer = React.createClass({
    propTypes: {
      multipleGradingPeriodsEnabled: bool.isRequired,
      readOnly:                      bool.isRequired,

      urls: shape({
        gradingPeriodSetsURL:    string.isRequired,
        gradingPeriodsUpdateURL: string.isRequired,
        enrollmentTermsURL:      string.isRequired,
        deleteGradingPeriodURL:  string.isRequired
      }).isRequired,
    },

    componentDidMount: function() {
      $(ReactDOM.findDOMNode(this)).children(".ui-tabs-minimal").tabs();
    },

    render: function () {
      if(this.props.multipleGradingPeriodsEnabled) {
        return (
          <div>
            <h1>{I18n.t("Grading")}</h1>
            <div className="ui-tabs-minimal">
              <ul>
                <li><a href="#grading-periods-tab" className="grading_periods_tab"> {I18n.t('Grading Periods')}</a></li>
                <li><a href="#grading-standards-tab" className="grading_standards_tab"> {I18n.t('Grading Schemes')}</a></li>
              </ul>
              <div ref="gradingPeriods" id="grading-periods-tab">
                <GradingPeriodSetCollection
                  urls        = {this.props.urls}
                  readOnly    = {this.props.readOnly}
                />
              </div>
              <div ref="gradingStandards" id="grading-standards-tab">
                <GradingStandardCollection />
              </div>
            </div>
          </div>
        );
      } else {
        return (
          <div ref="gradingStandards">
            <h1>{I18n.t("Grading Schemes")}</h1>
            <GradingStandardCollection />
          </div>
        );
      }
    }
  });

  return AccountTabContainer;
});
