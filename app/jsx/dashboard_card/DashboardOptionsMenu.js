import React from 'react'
import I18n from 'i18n!dashboard'
import axios from 'axios'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu'
import { MenuItem, MenuItemGroup } from 'instructure-ui/lib/components/Menu'
import Button from 'instructure-ui/lib/components/Button'
import IconSettings2Solid from 'instructure-icons/react/Solid/IconSettings2Solid'

export default class DashboardOptionsMenu extends React.Component {
  static propTypes = {
    recent_activity_dashboard: React.PropTypes.bool.isRequired,
    planner_enabled: React.PropTypes.bool,
    planner_selected: React.PropTypes.bool
  }

  static defaultProps = {
    planner_enabled: false,
    planner_selected: false,
  }

  constructor (props) {
    super(props)

    let view;
    if (props.planner_enabled) {
      view = props.planner_selected ? ['planner'] : ['cards']
    } else {
      view = props.recent_activity_dashboard ? ['activity'] : ['cards']
    }

    this.state = { view }
  }

  handleViewOptionSelect = (e, newSelected) => {
    if (newSelected.length === 0) {
      return
    }
    this.setState({view: newSelected}, () => {
      this.toggleDashboardView()
      this.postDashboardToggle()
    })
  }

  toggleDashboardView () {
    if (this.props.planner_enabled) {
      const dashboardPlanner = document.getElementById('dashboard-planner')
      dashboardPlanner.style.display = (dashboardPlanner.style.display === 'none') ? 'block' : 'none'
    } else {
      const dashboardActivity = document.getElementById('dashboard-activity')
      dashboardActivity.style.display = (dashboardActivity.style.display === 'none') ? 'block' : 'none'
    }

    const dashboardCards = document.getElementById('DashboardCard_Container')
    dashboardCards.style.display = (dashboardCards.style.display === 'none') ? 'block' : 'none'
  }

  postDashboardToggle () {
    if (this.props.planner_enabled) {
      axios.put('/dashboard/view', {
        dashboard_view: this.state.view[0]
      })
    } else {
      axios.post('/users/toggle_recent_activity_dashboard')
    }
  }

  render () {
    return (
      <PopoverMenu
        trigger={
          <Button variant="icon">
            <ScreenReaderContent>{I18n.t('Dashboard Options')}</ScreenReaderContent>
            <IconSettings2Solid />
          </Button>
        }
        contentRef={(el) => { this.menuContentRef = el; }}
      >
        <MenuItemGroup
          label={I18n.t('Dashboard View')}
          onSelect={this.handleViewOptionSelect}
          selected={this.state.view}
        >
          {
            (this.props.planner_enabled) ?
              <MenuItem value="planner">{I18n.t('Planner')}</MenuItem> :
              <MenuItem value="activity">{I18n.t('Recent Activity')}</MenuItem>
          }
          <MenuItem value="cards">
            {I18n.t('Course Cards')}
          </MenuItem>
        </MenuItemGroup>
      </PopoverMenu>
    )
  }
}
