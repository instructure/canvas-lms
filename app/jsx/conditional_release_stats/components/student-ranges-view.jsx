define([
  'react',
  'instructure-ui/TabList',
  'instructure-ui/ApplyTheme',
  'i18n!cyoe_assignment_sidebar',
  './student-range',
  '../helpers/score',
], (React, { default: TabList, TabPanel, Tab }, { default: ApplyTheme }, I18n, StudentRange, scoreHelpers) => {
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

  return class StudentRangesView extends React.Component {
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
})
