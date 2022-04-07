/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React, {Component} from 'react'
import {connect} from 'react-redux'
import {themeable} from '@instructure/ui-themeable'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {ScreenReaderContent, AccessibleContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {Portal} from '@instructure/ui-portal'
import {IconPlusLine, IconAlertsLine, IconGradebookLine} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import {Tray} from '@instructure/ui-tray'
import PropTypes from 'prop-types'
import {Badge} from '@instructure/ui-badge'
import {momentObj} from 'react-moment-proptypes'
import UpdateItemTray from '../UpdateItemTray'
import Opportunities from '../Opportunities'
import GradesDisplay from '../GradesDisplay'
import StickyButton from '../StickyButton'
import responsiviser from '../responsiviser'
import {sizeShape, courseShape, opportunityShape} from '../plannerPropTypes'
import {
  savePlannerItem,
  deletePlannerItem,
  cancelEditingPlannerItem,
  openEditingPlannerItem,
  getNextOpportunities,
  dismissOpportunity,
  clearUpdateTodo,
  startLoadingGradesSaga,
  scrollToToday,
  scrollToNewActivity
} from '../../actions'

import styles from './styles.css'
import theme from './theme'
import formatMessage from '../../format-message'
import {notifier} from '../../dynamic-ui'
import {getFirstLoadedMoment} from '../../utilities/dateUtils'
import {observedUserId} from '../../utilities/apiUtils'

export class PlannerHeader extends Component {
  static propTypes = {
    courses: PropTypes.arrayOf(PropTypes.shape(courseShape)).isRequired,
    savePlannerItem: PropTypes.func.isRequired,
    deletePlannerItem: PropTypes.func.isRequired,
    cancelEditingPlannerItem: PropTypes.func,
    openEditingPlannerItem: PropTypes.func,
    triggerDynamicUiUpdates: PropTypes.func,
    preTriggerDynamicUiUpdates: PropTypes.func,
    scrollToToday: PropTypes.func,
    scrollToNewActivity: PropTypes.func,
    locale: PropTypes.string.isRequired,
    timeZone: PropTypes.string.isRequired,
    opportunities: PropTypes.shape(opportunityShape).isRequired,
    getNextOpportunities: PropTypes.func.isRequired,
    dismissOpportunity: PropTypes.func.isRequired,
    clearUpdateTodo: PropTypes.func.isRequired,
    startLoadingGradesSaga: PropTypes.func.isRequired,
    firstNewActivityDate: momentObj,
    isObserving: PropTypes.bool,
    days: PropTypes.arrayOf(
      PropTypes.arrayOf(
        PropTypes.oneOfType([
          /* date */ PropTypes.string,
          PropTypes.arrayOf(/* items */ PropTypes.object)
        ])
      )
    ),
    ui: PropTypes.shape({
      naiAboveScreen: PropTypes.bool
    }),
    todo: PropTypes.shape({
      updateTodoItem: PropTypes.shape({
        title: PropTypes.string
      })
    }),
    stickyZIndex: PropTypes.number,
    loading: PropTypes.shape({
      isLoading: PropTypes.bool,
      allPastItemsLoaded: PropTypes.bool,
      allFutureItemsLoaded: PropTypes.bool,
      allOpportunitiesLoaded: PropTypes.bool,
      loadingOpportunities: PropTypes.bool,
      setFocusAfterLoad: PropTypes.bool,
      firstNewDayKey: PropTypes.object,
      futureNextUrl: PropTypes.string,
      pastNextUrl: PropTypes.string,
      seekingNewActivity: PropTypes.bool,
      loadingGrades: PropTypes.bool,
      gradesLoaded: PropTypes.bool,
      gradesLoadingError: PropTypes.string
    }).isRequired,
    ariaHideElement: PropTypes.instanceOf(Element).isRequired,
    auxElement: PropTypes.instanceOf(Element).isRequired,
    stickyButtonId: PropTypes.string.isRequired,
    responsiveSize: sizeShape
  }

  static defaultProps = {
    triggerDynamicUiUpdates: () => {},
    preTriggerDynamicUiUpdates: () => {},
    stickyZIndex: 0,
    responsiveSize: 'large'
  }

  constructor(props) {
    super(props)

    const [newOpportunities, dismissedOpportunities] = this.segregateOpportunities(
      props.opportunities
    )

    this.state = {
      newOpportunities,
      dismissedOpportunities,
      trayOpen: false,
      gradesTrayOpen: false,
      opportunitiesOpen: false
    }
  }

  loadNextOpportunitiesIfNeeded(props) {
    if (!props.loading.allOpportunitiesLoaded && !props.loading.loadingOpportunities) {
      props.getNextOpportunities()
    }
  }

  componentDidMount() {
    this.loadNextOpportunitiesIfNeeded(this.props)
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    const [newOpportunities, dismissedOpportunities] = this.segregateOpportunities(
      nextProps.opportunities
    )

    this.loadNextOpportunitiesIfNeeded(nextProps)

    if (this.props.todo.updateTodoItem !== nextProps.todo.updateTodoItem) {
      this.setUpdateItemTray(!!nextProps.todo.updateTodoItem)
    }
    this.setState({newOpportunities, dismissedOpportunities})
  }

  UNSAFE_componentWillUpdate() {
    this.props.preTriggerDynamicUiUpdates()
  }

  componentDidUpdate() {
    if (this.props.todo.updateTodoItem) {
      this.toggleAriaHiddenStuff(this.state.trayOpen)
    }
    this.props.triggerDynamicUiUpdates()
  }

  handleSavePlannerItem = plannerItem => {
    this.handleCloseTray()
    this.props.savePlannerItem(plannerItem)
  }

  handleDeletePlannerItem = plannerItem => {
    this.handleCloseTray()
    this.props.deletePlannerItem(plannerItem)
  }

  handleCloseTray = () => {
    this.setUpdateItemTray(false)
  }

  handleToggleTray = () => {
    if (this.state.trayOpen) {
      this.handleCloseTray()
    } else {
      this.setUpdateItemTray(true)
    }
  }

  // segregate new and dismissed opportunities
  segregateOpportunities(opportunities) {
    const newOpportunities = []
    const dismissedOpportunities = []

    opportunities.items.forEach(opportunity => {
      if (opportunity.planner_override && opportunity.planner_override.dismissed) {
        dismissedOpportunities.push(opportunity)
      } else {
        newOpportunities.push(opportunity)
      }
    })
    return [newOpportunities, dismissedOpportunities]
  }

  // sets the tray open state and tells dynamic-ui what just happened
  // via open/cancelEditingPlannerItem
  setUpdateItemTray(trayOpen) {
    if (trayOpen) {
      if (this.props.openEditingPlannerItem) {
        this.props.openEditingPlannerItem() // tell dynamic-ui we've started editing
      }
    } else if (this.props.cancelEditingPlannerItem) {
      this.props.cancelEditingPlannerItem()
    }

    this.setState({trayOpen}, () => {
      this.toggleAriaHiddenStuff(this.state.trayOpen)
    })
  }

  toggleAriaHiddenStuff = hide => {
    if (hide) {
      this.props.ariaHideElement.setAttribute('aria-hidden', 'true')
    } else {
      this.props.ariaHideElement.removeAttribute('aria-hidden')
    }
  }

  toggleGradesTray = () => {
    if (
      !this.state.gradesTrayOpen &&
      !this.props.loading.loadingGrades &&
      !this.props.loading.gradesLoaded
    ) {
      this.props.startLoadingGradesSaga()
    }
    this.setState({gradesTrayOpen: !this.state.gradesTrayOpen})
  }

  handleTodayClick = () => {
    if (this.props.scrollToToday) {
      this.props.scrollToToday()
    }
  }

  handleNewActivityClick = () => {
    this.props.scrollToNewActivity()
  }

  _doToggleOpportunitiesDropdown(openOrClosed) {
    this.setState({opportunitiesOpen: !!openOrClosed}, () => {
      this.toggleAriaHiddenStuff(this.state.opportunitiesOpen)
      this.opportunitiesButton.focus()
    })
  }

  closeOpportunitiesDropdown = () => {
    this._doToggleOpportunitiesDropdown(false)
  }

  openOpportunitiesDropdown = () => {
    this._doToggleOpportunitiesDropdown(true)
  }

  toggleOpportunitiesDropdown = () => {
    this._doToggleOpportunitiesDropdown(!this.state.opportunitiesOpen)
  }

  opportunityTitle = () => {
    return formatMessage(
      `{
        count, plural,
        =0 {# opportunities}
        one {# opportunity}
        other {# opportunities}
      }`,
      {count: this.state.newOpportunities.length}
    )
  }

  getTrayLabel = () => {
    if (this.props.todo.updateTodoItem && this.props.todo.updateTodoItem.title) {
      return formatMessage('Edit {title}', {title: this.props.todo.updateTodoItem.title})
    }
    return formatMessage('Add To Do')
  }

  // Size the opportunities popover so that it fits on the screen under the trigger button
  getPopupVerticalRoom() {
    const trigger = this.opportunitiesHtmlButton
    if (trigger) {
      const buffer = 30
      const minRoom = 250
      const rect = trigger.getBoundingClientRect()
      const offset = rect.top + rect.height
      return Math.max(window.innerHeight - offset - buffer, minRoom)
    }
    return 'none'
  }

  newActivityAboveView() {
    if (this.props.loading.isLoading) return false
    if (!this.props.firstNewActivityDate) return false

    const firstLoadedMoment = getFirstLoadedMoment(this.props.days, this.props.timeZone)
    const firstNewActivityLoaded =
      firstLoadedMoment.isSame(this.props.firstNewActivityDate) ||
      firstLoadedMoment.isBefore(this.props.firstNewActivityDate)
    return !(firstNewActivityLoaded && !this.props.ui.naiAboveScreen)
  }

  renderNewActivity() {
    return (
      <Portal mountNode={this.props.auxElement} open={this.newActivityAboveView()}>
        <StickyButton
          id={this.props.stickyButtonId}
          direction="up"
          onClick={this.handleNewActivityClick}
          zIndex={this.props.stickyZIndex}
          buttonRef={ref => (this.newActivityButtonRef = ref)}
          className="StickyButton-styles__newActivityButton"
          description={formatMessage('Scrolls up to the previous item with new activity.')}
        >
          {formatMessage('New Activity')}
        </StickyButton>
      </Portal>
    )
  }

  renderToday(buttonMargin) {
    // if we're not displaying any items, don't show the today button
    // this is true if the planner is completely empty, or showing the balloons
    // because everything is in the past when first loaded
    if (this.props.days.length > 0) {
      return (
        <Button
          id="planner-today-btn"
          variant="light"
          margin={buttonMargin}
          onClick={this.handleTodayClick}
        >
          {formatMessage('Today')}
        </Button>
      )
    }
    return null
  }

  renderOpportunitiesButton(margin) {
    const badgeProps = {margin, countUntil: 100}
    if (this.props.loading.allOpportunitiesLoaded && this.state.newOpportunities.length) {
      badgeProps.count = this.state.newOpportunities.length
      badgeProps.formatOutput = formattedCount => {
        return <AccessibleContent alt={this.opportunityTitle()}>{formattedCount}</AccessibleContent>
      }
    } else {
      badgeProps.formatOutput = () => {
        return <AccessibleContent alt={this.opportunityTitle()} />
      }
    }

    return (
      <Badge {...badgeProps}>
        <Button
          onClick={this.toggleOpportunitiesDropdown}
          variant="icon"
          icon={IconAlertsLine}
          ref={b => {
            this.opportunitiesButton = b
          }}
          buttonRef={b => {
            this.opportunitiesHtmlButton = b
          }}
        >
          <ScreenReaderContent>{formatMessage('opportunities popup')}</ScreenReaderContent>
        </Button>
      </Badge>
    )
  }

  render() {
    let verticalRoom = this.getPopupVerticalRoom()
    let buttonMarginRight = 'medium'
    if (this.props.responsiveSize === 'medium') {
      buttonMarginRight = 'small'
    } else if (this.props.responsiveSize === 'small') {
      buttonMarginRight = 'x-small'
    }
    const buttonMargin = `0 ${buttonMarginRight} 0 0`

    let withArrow = true
    let positionTarget = null
    let placement = 'bottom end'
    let offsetY = 0
    if (window.innerWidth < 400) {
      // there's not enough room to position the popover with an arrow, so turn off the arrow,
      // cover up the header, and center the popover in the window instead
      withArrow = false
      positionTarget = document.getElementById('dashboard_header_container')
      placement = 'bottom center'
      offsetY = -positionTarget.offsetHeight
      verticalRoom += positionTarget.offsetHeight
    }

    return (
      <div className={`${styles.root} PlannerHeader`} data-testid="PlannerHeader">
        {this.renderToday(buttonMargin)}
        {!this.props.isObserving && (
          <Button
            variant="icon"
            icon={IconPlusLine}
            margin={buttonMargin}
            onClick={this.handleToggleTray}
            ref={b => {
              this.addNoteBtn = b
            }}
          >
            <ScreenReaderContent>{formatMessage('Add To Do')}</ScreenReaderContent>
          </Button>
        )}
        <Button
          variant="icon"
          icon={IconGradebookLine}
          margin={buttonMargin}
          onClick={this.toggleGradesTray}
        >
          <ScreenReaderContent>{formatMessage('Show My Grades')}</ScreenReaderContent>
        </Button>
        <Popover
          onHideContent={this.closeOpportunitiesDropdown}
          isShowingContent={this.state.opportunitiesOpen}
          on="click"
          withArrow={withArrow}
          positionTarget={positionTarget}
          constrain="window"
          placement={placement}
          offsetY={offsetY}
        >
          <Popover.Trigger>{this.renderOpportunitiesButton(buttonMargin)}</Popover.Trigger>
          <Popover.Content>
            <Opportunities
              togglePopover={this.closeOpportunitiesDropdown}
              newOpportunities={this.state.newOpportunities}
              dismissedOpportunities={this.state.dismissedOpportunities}
              courses={this.props.courses}
              timeZone={this.props.timeZone}
              dismiss={this.props.dismissOpportunity}
              maxHeight={verticalRoom}
              isObserving={this.props.isObserving}
            />
          </Popover.Content>
        </Popover>
        <Tray
          open={this.state.trayOpen}
          label={this.getTrayLabel()}
          placement="end"
          shouldContainFocus
          shouldReturnFocus={false}
          onDismiss={this.handleCloseTray}
        >
          <CloseButton placement="start" variant="icon" onClick={this.handleCloseTray}>
            {formatMessage('Close')}
          </CloseButton>
          <UpdateItemTray
            locale={this.props.locale}
            timeZone={this.props.timeZone}
            noteItem={this.props.todo.updateTodoItem}
            onSavePlannerItem={this.handleSavePlannerItem}
            onDeletePlannerItem={this.handleDeletePlannerItem}
            courses={this.props.courses}
          />
        </Tray>
        <Tray
          label={formatMessage('My Grades')}
          open={this.state.gradesTrayOpen}
          placement="end"
          shouldContainFocus
          shouldReturnFocus
          onDismiss={this.toggleGradesTray}
        >
          <View as="div" padding="large large medium">
            <CloseButton placement="start" variant="icon" onClick={this.toggleGradesTray}>
              {formatMessage('Close')}
            </CloseButton>
            <GradesDisplay
              courses={this.props.courses}
              loading={this.props.loading.loadingGrades}
              loadingError={this.props.loading.gradesLoadingError}
            />
          </View>
        </Tray>
        {this.renderNewActivity()}
      </div>
    )
  }
}

export const ResponsivePlannerHeader = responsiviser()(PlannerHeader)
export const ThemedPlannerHeader = themeable(theme, styles)(ResponsivePlannerHeader)
export const NotifierPlannerHeader = notifier(ThemedPlannerHeader)

const mapStateToProps = ({
  opportunities,
  loading,
  courses,
  todo,
  days,
  timeZone,
  ui,
  firstNewActivityDate,
  selectedObservee,
  currentUser
}) => ({
  opportunities,
  loading,
  courses,
  todo,
  days,
  timeZone,
  ui,
  firstNewActivityDate,
  isObserving: !!observedUserId({selectedObservee, currentUser})
})
const mapDispatchToProps = {
  savePlannerItem,
  deletePlannerItem,
  cancelEditingPlannerItem,
  openEditingPlannerItem,
  getNextOpportunities,
  dismissOpportunity,
  clearUpdateTodo,
  startLoadingGradesSaga,
  scrollToToday,
  scrollToNewActivity
}

export default connect(mapStateToProps, mapDispatchToProps)(NotifierPlannerHeader)
