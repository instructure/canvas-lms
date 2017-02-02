import React from 'react'
import GradingStandardCollection from 'jsx/grading/gradingStandardCollection'
import GradingPeriodSetCollection from 'jsx/grading/GradingPeriodSetCollection'
import $ from 'jquery'
import I18n from 'i18n!grading_periods'
  const { bool, string, shape } = React.PropTypes;

  class AccountTabContainer extends React.Component {
    static propTypes = {
      readOnly: bool.isRequired,
      urls: shape({
        gradingPeriodSetsURL: string.isRequired,
        gradingPeriodsUpdateURL: string.isRequired,
        enrollmentTermsURL: string.isRequired,
        deleteGradingPeriodURL: string.isRequired
      }).isRequired,
    }

    componentDidMount () {
      $(this.tabContainer).children('.ui-tabs-minimal').tabs();
    }

    render () {
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
              <GradingPeriodSetCollection
                urls={this.props.urls}
                readOnly={this.props.readOnly}
              />
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
  }

export default AccountTabContainer
