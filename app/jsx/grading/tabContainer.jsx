define([
  'react',
  'react-dom',
  'jsx/grading/gradingStandardCollection',
  'jsx/grading/gradingPeriodCollection',
  'jquery',
  'i18n!external_tools',
  'jquery.instructure_misc_plugins'
],
function(React, ReactDOM, GradingStandardCollection, GradingPeriodCollection, $, I18n) {

  var TabContainer = React.createClass({

    propTypes: {
      multipleGradingPeriodsEnabled: React.PropTypes.bool.isRequired
    },

    componentDidMount: function() {
      $(ReactDOM.findDOMNode(this)).children(".ui-tabs-minimal").tabs();
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
                <GradingPeriodCollection/>
              </div>
              <div ref="gradingStandards" id="grading-standards-tab">
                <GradingStandardCollection/>
              </div>
            </div>
          </div>
        );
      } else{
        return (
          <div ref="gradingStandards">
            <h1>{I18n.t("Grading Schemes")}</h1>
            <GradingStandardCollection/>
          </div>
        );
      }
    }
  });

  return TabContainer;

});
