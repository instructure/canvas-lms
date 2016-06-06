define([
  'react',
  'jsx/grading/gradingStandardCollection',
  'jsx/grading/GradingPeriodSetCollection',
  'jquery',
  'i18n!grading_periods'
], function(React, GradingStandardCollection, GradingPeriodSetCollection, $, I18n) {
  const types = React.PropTypes;

  let AccountTabContainer = React.createClass({
    propTypes: {
      multipleGradingPeriodsEnabled: types.bool.isRequired,
      readOnly: types.bool.isRequired,
      urls: types.shape({
        gradingPeriodSetsURL:    types.string.isRequired,
        gradingPeriodsUpdateURL: types.string.isRequired,
        enrollmentTermsURL:      types.string.isRequired,
        deleteGradingPeriodURL:  types.string.isRequired
      }).isRequired
    },

    componentDidMount: function() {
      $(this.getDOMNode()).children(".ui-tabs-minimal").tabs();
    },

    render: function () {
      if(this.props.multipleGradingPeriodsEnabled) {
        return (
          <div>
            <div className="ui-tabs-minimal">
              <ul>
                <li><a href="#grading-periods-tab" className="grading_periods_tab"> {I18n.t('Grading Periods')}</a></li>
                <li><a href="#grading-standards-tab" className="grading_standards_tab"> {I18n.t('Grading Schemes')}</a></li>
              </ul>
              <div ref="gradingPeriods" id="grading-periods-tab">
                <GradingPeriodSetCollection urls={this.props.urls}
                                            readOnly={this.props.readOnly} />
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
            <h1 tabIndex="0">{I18n.t("Grading Schemes")}</h1>
            <GradingStandardCollection />
          </div>
        );
      }
    }
  });

  return AccountTabContainer;
});
