import React from 'react'
import TabList, { TabPanel, Tab } from 'instructure-ui/lib/components/TabList'
import ApplyTheme from 'instructure-ui/lib/components/ApplyTheme'
import I18n from 'i18n!cyoe_assignment_sidebar'
import scoreHelpers from 'jsx/shared/conditional_release/score'
import StudentRange from './student-range'

  const { array, func, object } = React.PropTypes

  const tabsTheme = {
    [Tab.theme]: {
      accordionBackgroundColor: '#f7f7f7',
      accordionBackgroundColorSelected: '#f7f7f7',
      accordionBackgroundColorHover: '#e7e7e7',
      accordionTextColor: '#000000',
      accordionTextColorSelected: '#000000',

      spacingSmall: '10px',
      spacingExtraSmall: '12px',
    },

    [TabPanel.theme]: {
      borderColor: 'transparent',
    },
  }

export default class StudentRangesView extends React.Component {
    static propTypes = {
      assignment: object.isRequired,
      ranges: array.isRequired,
      selectedPath: object.isRequired,

      // actions
      selectStudent: func.isRequired,
      selectRange: func.isRequired,
    }

    renderTabs () {
      return this.props.ranges.map((range, i) => {
        const lower = scoreHelpers.transformScore(range.scoring_range.lower_bound, this.props.assignment, false)
        const upper = scoreHelpers.transformScore(range.scoring_range.upper_bound, this.props.assignment, true)
        const rangeTitle = `> ${lower} - ${upper}`
        return (
          <TabPanel key={i} title={rangeTitle}>
            <StudentRange
              range={range}
              onStudentSelect={this.props.selectStudent}
             />
          </TabPanel>
        )
      })
    }

    render () {
      return (
        <div className='crs-ranges-view'>
          <header className='crs-ranges-view__header'>
            <h4>{I18n.t('Mastery Paths Breakdown')}</h4>
          </header>
          <ApplyTheme theme={tabsTheme}>
            <TabList variant='accordion' selectedIndex={this.props.selectedPath.range} onChange={this.props.selectRange}>
              {this.renderTabs()}
            </TabList>
          </ApplyTheme>
        </div>
      )
    }
  }
