import React from 'react'
import GradingStandardCollection from 'jsx/grading/gradingStandardCollection'
import GradingPeriodCollection from 'jsx/grading/gradingPeriodCollection'
import $ from 'jquery'
import I18n from 'i18n!external_tools'
import 'jquery.instructure_misc_plugins'
  class CourseTabContainer extends React.Component {
    static propTypes = {
      hasGradingPeriods: React.PropTypes.bool.isRequired
    }

    componentDidMount () {
      if (!this.props.hasGradingPeriods) return;
      $(this.tabContainer).children('.ui-tabs-minimal').tabs();
    }

    renderSetsAndStandards () {
      return (
        <div ref={(el) => { this.tabContainer = el; }}>
          <h1>{I18n.t('Grading')}</h1>
          <div className="ui-tabs-minimal">
            <ul>
              <li><a href="#grading-periods-tab" className="grading_periods_tab"> {I18n.t('Grading Periods')}</a></li>
              <li><a href="#grading-standards-tab" className="grading_standards_tab"> {I18n.t('Grading Schemes')}</a></li>
            </ul>
            <div
              ref={(el) => { this.gradingPeriods = el; }}
              id="grading-periods-tab"
            >
              <GradingPeriodCollection />
            </div>
            <div
              ref={(el) => { this.gradingStandards = el; }}
              id="grading-standards-tab"
            >
              <GradingStandardCollection />
            </div>
          </div>
        </div>
      );
    }

    renderStandards () {
      return (
        <div ref={(el) => { this.gradingStandards = el; }}>
          <h1>{I18n.t('Grading Schemes')}</h1>
          <GradingStandardCollection />
        </div>
      );
    }

    render () {
      if (this.props.hasGradingPeriods) {
        return this.renderSetsAndStandards();
      }
      return this.renderStandards();
    }
  }

export default CourseTabContainer
