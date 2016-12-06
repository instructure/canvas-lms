import React from 'react'
import I18n from 'i18n!dashboard'
import axios from 'axios'
import ScreenReaderContent from 'instructure-ui/ScreenReaderContent'
import PopoverMenu from 'instructure-ui/PopoverMenu'
import { MenuItem, MenuItemGroup } from 'instructure-ui/Menu'
import Button from 'instructure-ui/Button'
import IconSettings2Solid from 'instructure-icons/react/Solid/IconSettings2Solid'

export default class DashboardOptionsMenu extends React.Component {
  static propTypes = {
    recent_activity_dashboard: React.PropTypes.bool.isRequired
  }

  constructor (props) {
    super(props)

    this.state = {
      view: props.recent_activity_dashboard ? ['activity'] : ['cards']
    }
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
    const dashboardActivity = document.getElementById('dashboard-activity')
    const dashboardCards = document.getElementById('DashboardCard_Container')

    dashboardActivity.style.display = (dashboardActivity.style.display === 'none') ? 'block' : 'none'
    dashboardCards.style.display = (dashboardCards.style.display === 'none') ? 'block' : 'none'
  }

  postDashboardToggle () {
    axios.post('/users/toggle_recent_activity_dashboard')
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
      >
        <MenuItemGroup
          label={I18n.t('Dashboard View')}
          onSelect={this.handleViewOptionSelect}
          selected={this.state.view}
        >
          <MenuItem value="activity">
            {I18n.t('Recent Activity')}
          </MenuItem>
          <MenuItem value="cards">
            {I18n.t('Course Cards')}
          </MenuItem>
        </MenuItemGroup>
      </PopoverMenu>
    )
  }
}
