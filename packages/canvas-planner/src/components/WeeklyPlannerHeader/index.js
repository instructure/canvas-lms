/*
 * Copyright (C) 2021 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React, {Component} from 'react'
import PropTypes from 'prop-types'
import {connect} from 'react-redux'
import {themeable} from '@instructure/ui-themeable'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenEndLine, IconArrowOpenStartLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {loadNextWeekItems, loadPastWeekItems, loadThisWeekItems, scrollToToday} from '../../actions'
import ErrorAlert from '../ErrorAlert'
import formatMessage from '../../format-message'

import theme from './theme'
import styles from './styles.css'

// Breaking our encapsulation by reaching outside our dom sub-tree
// I suppose we could wire up the event handlers in K5Dashboard.js
// and pass the height as a prop to all the pages. Maybe it will be
// worth the complexity when another page needs the info.
function findStickyOffset() {
  const dashboardTabs = document.querySelector('.ic-Dashboard-tabs')
  const so = dashboardTabs?.getBoundingClientRect().bottom || 122
  return so
}

// Theming a functional component blew up because there was no super.prototpye
export class WeeklyPlannerHeader extends Component {
  static propTypes = {
    loadNextWeekItems: PropTypes.func.isRequired,
    loadPastWeekItems: PropTypes.func.isRequired,
    loadThisWeekItems: PropTypes.func.isRequired,
    scrollToToday: PropTypes.func.isRequired,
    loading: PropTypes.shape({
      isLoading: PropTypes.bool,
      loadingWeek: PropTypes.bool,
      loadingError: PropTypes.string
    }).isRequired,
    visible: PropTypes.bool
  }

  state = {
    stickyOffset: findStickyOffset()
  }

  handleStickyOffset = () => {
    this.setState({stickyOffset: findStickyOffset()})
  }

  handleToday = () => {
    this.props.loadThisWeekItems()
  }

  componentDidMount() {
    if (this.props.visible) {
      this.handleStickyOffset()
      document.addEventListener('scroll', this.handleStickyOffset)
      window.addEventListener('resize', this.handleStickyOffset)
    }
  }

  componentDidUpdate(prevProps) {
    // the tabs panel above the weekly planner changes size when
    // 1. the user scrolls up and the heading shrinks, or
    // 2. the window becomes narrow enough for the tabs to wrap.
    // We need to relocate the WeeklyPlannerHeader so it sticks
    // to the bottom of the tabs panel.
    if (this.props.visible !== prevProps.visible) {
      if (this.props.visible) {
        this.handleStickyOffset()
        document.addEventListener('scroll', this.handleStickyOffset)
        window.addEventListener('resize', this.handleStickyOffset)
      } else {
        document.removeEventListener('scroll', this.handleStickyOffset)
        window.removeEventListener('resize', this.handleStickyOffset)
      }
    }
  }

  render() {
    return (
      <div
        data-testid="WeeklyPlannerHeader"
        className={`${styles.root} WeeklyPlannerHeader`}
        style={{
          top: `${this.state.stickyOffset}px`
        }}
      >
        {this.props.loading.loadingError && (
          <div className={styles.errorbox}>
            <ErrorAlert error={this.props.loading.loadingError} margin="xx-small">
              {formatMessage('Error loading items')}
            </ErrorAlert>
          </div>
        )}
        <View as="div" textAlign="end" padding="xx-small 0 xx-small xx-small" background="primary">
          <IconButton
            onClick={_event => {
              this.props.loadPastWeekItems()
            }}
            screenReaderLabel={formatMessage('View previous week')}
            interaction={
              this.props.wayPastItemDate < this.props.weekStartDate ? 'enabled' : 'disabled'
            }
          >
            <IconArrowOpenStartLine />
          </IconButton>
          <Button margin="0 xx-small" onClick={this.handleToday}>
            {formatMessage('Today')}
          </Button>
          <IconButton
            onClick={() => this.props.loadNextWeekItems({loadMoreButtonClicked: true})}
            screenReaderLabel={formatMessage('View next week')}
            interaction={
              this.props.wayFutureItemDate > this.props.weekEndDate ? 'enabled' : 'disabled'
            }
          >
            <IconArrowOpenEndLine />
          </IconButton>
        </View>
      </div>
    )
  }
}

export const ThemedWeeklyPlannerHeader = themeable(theme, styles)(WeeklyPlannerHeader)

const mapStateToProps = state => {
  return {
    loading: state.loading,
    weekStartDate: state.weeklyDashboard.weekStart.format(),
    weekEndDate: state.weeklyDashboard.weekEnd.format(),
    wayPastItemDate: state.weeklyDashboard.wayPastItemDate,
    wayFutureItemDate: state.weeklyDashboard.wayFutureItemDate
  }
}

const mapDispatchToProps = {
  loadNextWeekItems,
  loadPastWeekItems,
  loadThisWeekItems,
  scrollToToday
}

export default connect(mapStateToProps, mapDispatchToProps)(ThemedWeeklyPlannerHeader)
