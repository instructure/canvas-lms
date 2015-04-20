/** @jsx React.DOM */

define([
  'react',
  'jsx/grading/gradingStandardCollection',
  'jsx/grading/gradingPeriodCollection',
  'jquery',
  'i18n!external_tools',
  'jquery.instructure_misc_plugins'
],
function(React, GradingStandardCollection, GradingPeriodCollection, $, I18n) {

  var TabContainer = React.createClass({

    componentDidMount: function() {
      $(this.getDOMNode()).children(".ui-tabs-minimal").tabs();
    },

    render: function () {
      if(ENV.MULTIPLE_GRADING_PERIODS){
        return (
          <div>
            <div className="ui-tabs-minimal">
              <ul>
                <li><a href="#grading-periods-tab" className="grading_periods_tab"> {I18n.t('Grading Periods')}</a></li>
                <li><a href="#grading-standards-tab" className="grading_standards_tab"> {I18n.t('Grading Schemes')}</a></li>
              </ul>
              <div id="grading-periods-tab">
                <GradingPeriodCollection/>
              </div>
              <div id="grading-standards-tab">
                <GradingStandardCollection/>
              </div>
            </div>
          </div>
        );
      } else{
        return (
          <div>
            <h1 tabIndex="0">{I18n.t("Grading Schemes")}</h1>
            <GradingStandardCollection/>
          </div>
        );
      }
    }
  });

  React.render(<TabContainer/>, document.getElementById("react_grading_tabs"));

});
