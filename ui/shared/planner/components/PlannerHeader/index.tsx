/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {connect} from 'react-redux'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {Portal} from '@instructure/ui-portal'
import {IconPlusLine, IconAlertsLine, IconGradebookLine} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import {Tray} from '@instructure/ui-tray'
import PropTypes from 'prop-types'
import {Badge} from '@instructure/ui-badge'
import {Flex} from '@instructure/ui-flex'
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
  scrollToNewActivity,
  setGradesTrayState,
} from '../../actions'
import {useScope as createI18nScope} from '@canvas/i18n'
import {notifier} from '../../dynamic-ui'
// @ts-expect-error TS2305 (typescriptify)
import {getFirstLoadedMoment} from '../../utilities/dateUtils'
import {observedUserId} from '../../utilities/apiUtils'
import buildStyle from './style'

const I18n = createI18nScope('planner')

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
    setGradesTrayState: PropTypes.func.isRequired,
    firstNewActivityDate: momentObj,
    isObserving: PropTypes.bool,
    selectedObservee: PropTypes.string,
    days: PropTypes.arrayOf(
      PropTypes.arrayOf(
        PropTypes.oneOfType([
          /* date */ PropTypes.string,
          PropTypes.arrayOf(/* items */ PropTypes.object),
        ]),
      ),
    ),
    ui: PropTypes.shape({
      naiAboveScreen: PropTypes.bool,
    }),
    todo: PropTypes.shape({
      updateTodoItem: PropTypes.shape({
        title: PropTypes.string,
      }),
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
      gradesLoadingError: PropTypes.string,
    }).isRequired,
    ariaHideElement: PropTypes.instanceOf(Element).isRequired,
    auxElement: PropTypes.instanceOf(Element).isRequired,
    stickyButtonId: PropTypes.string.isRequired,
    responsiveSize: sizeShape,
  }

  static defaultProps = {
    triggerDynamicUiUpdates: () => {},
    preTriggerDynamicUiUpdates: () => {},
    stickyZIndex: 0,
    responsiveSize: 'large',
  }

  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)

    const [newOpportunities, dismissedOpportunities] = this.segregateOpportunities(
      props.opportunities,
    )

    this.state = {
      newOpportunities,
      dismissedOpportunities,
      trayOpen: false,
      gradesTrayOpen: false,
      opportunitiesOpen: false,
    }
    // @ts-expect-error TS2339 (typescriptify)
    this.style = buildStyle()
  }

  // @ts-expect-error TS7006 (typescriptify)
  loadNextOpportunitiesIfNeeded(props) {
    if (!props.loading.allOpportunitiesLoaded && !props.loading.loadingOpportunities) {
      props.getNextOpportunities()
    }
  }

  componentDidMount() {
    this.loadNextOpportunitiesIfNeeded(this.props)
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillReceiveProps(nextProps) {
    const [newOpportunities, dismissedOpportunities] = this.segregateOpportunities(
      nextProps.opportunities,
    )

    this.loadNextOpportunitiesIfNeeded(nextProps)

    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.todo.updateTodoItem !== nextProps.todo.updateTodoItem) {
      this.setUpdateItemTray(!!nextProps.todo.updateTodoItem)
    }
    this.setState({newOpportunities, dismissedOpportunities})
  }

  UNSAFE_componentWillUpdate() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.preTriggerDynamicUiUpdates()
  }

  componentDidUpdate() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.todo.updateTodoItem) {
      // @ts-expect-error TS2339 (typescriptify)
      this.toggleAriaHiddenStuff(this.state.trayOpen)
    }
    // @ts-expect-error TS2339 (typescriptify)
    this.props.triggerDynamicUiUpdates()
  }

  // @ts-expect-error TS7006 (typescriptify)
  handleSavePlannerItem = plannerItem => {
    this.handleCloseTray()
    // @ts-expect-error TS2339 (typescriptify)
    this.props.savePlannerItem(plannerItem)
  }

  // @ts-expect-error TS7006 (typescriptify)
  handleDeletePlannerItem = plannerItem => {
    this.handleCloseTray()
    // @ts-expect-error TS2339 (typescriptify)
    this.props.deletePlannerItem(plannerItem)
  }

  handleCloseTray = () => {
    this.setUpdateItemTray(false)
  }

  handleToggleTray = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.state.trayOpen) {
      this.handleCloseTray()
    } else {
      this.setUpdateItemTray(true)
    }
  }

  // segregate new and dismissed opportunities
  // @ts-expect-error TS7006 (typescriptify)
  segregateOpportunities(opportunities) {
    // @ts-expect-error TS7034 (typescriptify)
    const newOpportunities = []
    // @ts-expect-error TS7034 (typescriptify)
    const dismissedOpportunities = []

    // @ts-expect-error TS7006 (typescriptify)
    opportunities.items.forEach(opportunity => {
      if (opportunity.planner_override && opportunity.planner_override.dismissed) {
        dismissedOpportunities.push(opportunity)
      } else {
        newOpportunities.push(opportunity)
      }
    })
    // @ts-expect-error TS7005 (typescriptify)
    return [newOpportunities, dismissedOpportunities]
  }

  // sets the tray open state and tells dynamic-ui what just happened
  // via open/cancelEditingPlannerItem
  // @ts-expect-error TS7006 (typescriptify)
  setUpdateItemTray(trayOpen) {
    if (trayOpen) {
      // @ts-expect-error TS2339 (typescriptify)
      if (this.props.openEditingPlannerItem) {
        // @ts-expect-error TS2339 (typescriptify)
        this.props.openEditingPlannerItem() // tell dynamic-ui we've started editing
      }
      // @ts-expect-error TS2339 (typescriptify)
    } else if (this.props.cancelEditingPlannerItem) {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.cancelEditingPlannerItem()
    }

    this.setState({trayOpen}, () => {
      // @ts-expect-error TS2339 (typescriptify)
      this.toggleAriaHiddenStuff(this.state.trayOpen)
    })
  }

  // @ts-expect-error TS7006 (typescriptify)
  toggleAriaHiddenStuff = hide => {
    if (hide) {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.ariaHideElement.setAttribute('aria-hidden', 'true')
    } else {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.ariaHideElement.removeAttribute('aria-hidden')
    }
  }

  toggleGradesTray = () => {
    if (
      // @ts-expect-error TS2339 (typescriptify)
      !this.state.gradesTrayOpen &&
      // @ts-expect-error TS2339 (typescriptify)
      !this.props.loading.loadingGrades &&
      // @ts-expect-error TS2339 (typescriptify)
      !this.props.loading.gradesLoaded
    ) {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.startLoadingGradesSaga(this.props.isObserving ? this.props.selectedObservee : null)
    }
    // @ts-expect-error TS2339 (typescriptify)
    this.props.setGradesTrayState(!this.state.gradesTrayOpen)
    // @ts-expect-error TS2339 (typescriptify)
    this.setState(prevState => ({gradesTrayOpen: !prevState.gradesTrayOpen}))
  }

  handleTodayClick = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.scrollToToday) {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.scrollToToday({autoFocus: true})
    }
  }

  handleNewActivityClick = () => {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.scrollToNewActivity()
  }

  // @ts-expect-error TS7006 (typescriptify)
  _doToggleOpportunitiesDropdown(openOrClosed) {
    this.setState({opportunitiesOpen: !!openOrClosed}, () => {
      // @ts-expect-error TS2339 (typescriptify)
      this.toggleAriaHiddenStuff(this.state.opportunitiesOpen)
      // @ts-expect-error TS2551 (typescriptify)
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
    // @ts-expect-error TS2339 (typescriptify)
    this._doToggleOpportunitiesDropdown(!this.state.opportunitiesOpen)
  }

  opportunityTitle = () => {
    return I18n.t(
      {
        zero: '0 opportunities',
        one: '1 opportunity',
        other: '%{count} opportunities',
      },
      {
        // @ts-expect-error TS2339 (typescriptify)
        count: this.state.newOpportunities.length,
      },
    )
  }

  getTrayLabel = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.todo.updateTodoItem && this.props.todo.updateTodoItem.title) {
      // @ts-expect-error TS2339 (typescriptify)
      return I18n.t('Edit %{title}', {title: this.props.todo.updateTodoItem.title})
    }
    return I18n.t('Add To Do')
  }

  // Size the opportunities popover so that it fits on the screen under the trigger button
  getPopupVerticalRoom() {
    // @ts-expect-error TS2339 (typescriptify)
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

  getPopupVerticalProperties() {
    let verticalRoom = this.getPopupVerticalRoom()
    let buttonMarginRight = 'medium'
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.responsiveSize === 'medium') {
      buttonMarginRight = 'small'
      // @ts-expect-error TS2339 (typescriptify)
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
      // @ts-expect-error TS18047 (typescriptify)
      offsetY = -positionTarget.offsetHeight
      // @ts-expect-error TS18047,TS2365 (typescriptify)
      verticalRoom += positionTarget.offsetHeight
    }

    return {
      verticalRoom,
      buttonMargin,
      withArrow,
      positionTarget,
      placement,
      offsetY,
    }
  }

  newActivityAboveView() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.loading.isLoading) return false
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.firstNewActivityDate) return false

    // @ts-expect-error TS2339 (typescriptify)
    const firstLoadedMoment = getFirstLoadedMoment(this.props.days, this.props.timeZone)
    const firstNewActivityLoaded =
      // @ts-expect-error TS2339 (typescriptify)
      firstLoadedMoment.isSame(this.props.firstNewActivityDate) ||
      // @ts-expect-error TS2339 (typescriptify)
      firstLoadedMoment.isBefore(this.props.firstNewActivityDate)
    // @ts-expect-error TS2339 (typescriptify)
    return !(firstNewActivityLoaded && !this.props.ui.naiAboveScreen)
  }

  renderNewActivity() {
    return (
      // @ts-expect-error TS2339 (typescriptify)
      <Portal mountNode={this.props.auxElement} open={this.newActivityAboveView()}>
        <StickyButton
          // @ts-expect-error TS2339 (typescriptify)
          id={this.props.stickyButtonId}
          direction="up"
          onClick={this.handleNewActivityClick}
          // @ts-expect-error TS2339 (typescriptify)
          zIndex={this.props.stickyZIndex}
          // @ts-expect-error TS2322,TS2339,TS7006 (typescriptify)
          elementRef={ref => (this.newActivityButtonRef = ref)}
          className="StickyButton-styles__newActivityButton"
          description={I18n.t('Scrolls up to the previous item with new activity.')}
        >
          {I18n.t('New Activity')}
        </StickyButton>
      </Portal>
    )
  }

  // @ts-expect-error TS7006 (typescriptify)
  renderToday(buttonMargin, isSmallSize = null) {
    // if we're not displaying any items, don't show the today button
    // this is true if the planner is completely empty, or showing the balloons
    // because everything is in the past when first loaded
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.days.length > 0) {
      return (
        <Button
          id="planner-today-btn"
          color={ENV.FEATURES?.instui_header ? 'secondary' : 'primary-inverse'}
          margin={buttonMargin}
          onClick={this.handleTodayClick}
          display={isSmallSize ? 'block' : 'inline-block'}
        >
          {I18n.t('Today')}
        </Button>
      )
    }
    return null
  }

  // @ts-expect-error TS7006 (typescriptify)
  renderOpportunitiesButton(margin, isSmallSize = false) {
    const badgeProps = {margin, countUntil: 100, display: isSmallSize ? 'block' : 'inline-block'}
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.loading.allOpportunitiesLoaded && this.state.newOpportunities.length) {
      // @ts-expect-error TS2339 (typescriptify)
      badgeProps.count = this.state.newOpportunities.length
      // @ts-expect-error TS2339,TS7006 (typescriptify)
      badgeProps.formatOutput = formattedCount => {
        return <AccessibleContent alt={this.opportunityTitle()}>{formattedCount}</AccessibleContent>
      }
    } else {
      // @ts-expect-error TS2339 (typescriptify)
      badgeProps.formatOutput = () => {
        return <AccessibleContent alt={this.opportunityTitle()} />
      }
    }

    return (
      // @ts-expect-error TS2322 (typescriptify)
      <Badge {...badgeProps}>
        {ENV.FEATURES?.instui_header ? (
          <Button
            // @ts-expect-error TS2769 (typescriptify)
            renderIcon={IconAlertsLine}
            screenReaderLabel={I18n.t('opportunities popup')}
            onClick={this.toggleOpportunitiesDropdown}
            display={isSmallSize ? 'block' : 'inline-block'}
            ref={b => {
              // @ts-expect-error TS2551 (typescriptify)
              this.opportunitiesButton = b
            }}
            elementRef={b => {
              // @ts-expect-error TS2339 (typescriptify)
              this.opportunitiesHtmlButton = b
            }}
          >
            {I18n.t('Opportunities')}
          </Button>
        ) : (
          <IconButton
            renderIcon={IconAlertsLine}
            screenReaderLabel={I18n.t('opportunities popup')}
            withBorder={false}
            withBackground={false}
            onClick={this.toggleOpportunitiesDropdown}
            ref={b => {
              // @ts-expect-error TS2551 (typescriptify)
              this.opportunitiesButton = b
            }}
            elementRef={b => {
              // @ts-expect-error TS2339 (typescriptify)
              this.opportunitiesHtmlButton = b
            }}
          />
        )}
      </Badge>
    )
  }

  renderLegacy() {
    const {verticalRoom, buttonMargin, withArrow, positionTarget, placement, offsetY} =
      this.getPopupVerticalProperties()

    return (
      <>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <style>{this.style.css}</style>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <div className={`${this.style.classNames.root} PlannerHeader`} data-testid="PlannerHeader">
          {this.renderToday(buttonMargin)}
          {/* @ts-expect-error TS2339 (typescriptify) */}
          {!this.props.isObserving && (
            <IconButton
              renderIcon={IconPlusLine}
              data-testid="add-to-do-button"
              screenReaderLabel={I18n.t('Add To Do')}
              withBorder={false}
              withBackground={false}
              margin={buttonMargin}
              onClick={this.handleToggleTray}
              ref={b => {
                // @ts-expect-error TS2339 (typescriptify)
                this.addNoteBtn = b
              }}
            />
          )}
          <IconButton
            data-testid="show-my-grades-button"
            renderIcon={IconGradebookLine}
            screenReaderLabel={I18n.t('Show My Grades')}
            withBorder={false}
            withBackground={false}
            margin={buttonMargin}
            onClick={this.toggleGradesTray}
          />
          <Popover
            onHideContent={this.closeOpportunitiesDropdown}
            // @ts-expect-error TS2339 (typescriptify)
            isShowingContent={this.state.opportunitiesOpen}
            on="click"
            renderTrigger={this.renderOpportunitiesButton(buttonMargin)}
            withArrow={withArrow}
            positionTarget={positionTarget}
            constrain="window"
            // @ts-expect-error TS2322 (typescriptify)
            placement={placement}
            offsetY={offsetY}
          >
            <Opportunities
              togglePopover={this.closeOpportunitiesDropdown}
              // @ts-expect-error TS2339 (typescriptify)
              newOpportunities={this.state.newOpportunities}
              // @ts-expect-error TS2339 (typescriptify)
              dismissedOpportunities={this.state.dismissedOpportunities}
              // @ts-expect-error TS2339 (typescriptify)
              courses={this.props.courses}
              // @ts-expect-error TS2339 (typescriptify)
              timeZone={this.props.timeZone}
              // @ts-expect-error TS2339 (typescriptify)
              dismiss={this.props.dismissOpportunity}
              maxHeight={verticalRoom}
              // @ts-expect-error TS2339 (typescriptify)
              isObserving={this.props.isObserving}
            />
          </Popover>
          <Tray
            // @ts-expect-error TS2339 (typescriptify)
            open={this.state.trayOpen}
            label={this.getTrayLabel()}
            placement="end"
            shouldContainFocus={true}
            shouldReturnFocus={false}
            onDismiss={this.handleCloseTray}
          >
            <CloseButton
              placement="start"
              onClick={this.handleCloseTray}
              screenReaderLabel={I18n.t('Close')}
            />
            <UpdateItemTray
              // @ts-expect-error TS2339 (typescriptify)
              locale={this.props.locale}
              // @ts-expect-error TS2339 (typescriptify)
              timeZone={this.props.timeZone}
              // @ts-expect-error TS2339 (typescriptify)
              noteItem={this.props.todo.updateTodoItem}
              onSavePlannerItem={this.handleSavePlannerItem}
              onDeletePlannerItem={this.handleDeletePlannerItem}
              // @ts-expect-error TS2339 (typescriptify)
              courses={this.props.courses}
            />
          </Tray>
          <Tray
            label={I18n.t('My Grades')}
            // @ts-expect-error TS2339 (typescriptify)
            open={this.state.gradesTrayOpen}
            placement="end"
            shouldContainFocus={true}
            shouldReturnFocus={true}
            onDismiss={this.toggleGradesTray}
          >
            <View as="div" padding="large large medium">
              <CloseButton
                placement="start"
                onClick={this.toggleGradesTray}
                screenReaderLabel={I18n.t('Close')}
              />
              <GradesDisplay
                // @ts-expect-error TS2339 (typescriptify)
                courses={this.props.courses}
                // @ts-expect-error TS2339 (typescriptify)
                loading={this.props.loading.loadingGrades}
                // @ts-expect-error TS2339 (typescriptify)
                loadingError={this.props.loading.gradesLoadingError}
              />
            </View>
          </Tray>
          {this.renderNewActivity()}
        </div>
      </>
    )
  }

  render() {
    if (!ENV.FEATURES?.instui_header) {
      return this.renderLegacy()
    }

    const {verticalRoom, withArrow, positionTarget, placement, offsetY} =
      this.getPopupVerticalProperties()

    // @ts-expect-error TS2339 (typescriptify)
    const isSmallSize = this.props.responsiveSize === 'small'
    // @ts-expect-error TS2345 (typescriptify)
    const renderTodayButton = this.renderToday('none', isSmallSize)

    return (
      <Flex gap="small" withVisualDebug={false} direction={isSmallSize ? 'column' : 'row'}>
        {renderTodayButton && <Flex.Item overflowY="visible">{renderTodayButton}</Flex.Item>}

        {/* @ts-expect-error TS2339 (typescriptify) */}
        {!this.props.isObserving && (
          <Flex.Item overflowY="visible">
            <Button
              // @ts-expect-error TS2769 (typescriptify)
              renderIcon={IconPlusLine}
              data-testid="add-to-do-button"
              screenReaderLabel={I18n.t('Add To Do')}
              onClick={this.handleToggleTray}
              ref={b => {
                // @ts-expect-error TS2339 (typescriptify)
                this.addNoteBtn = b
              }}
              display={isSmallSize ? 'block' : 'inline-block'}
            >
              {I18n.t('Add To Do')}
            </Button>
          </Flex.Item>
        )}

        <Flex.Item overflowY="visible">
          <Button
            data-testid="show-my-grades-button"
            // @ts-expect-error TS2769 (typescriptify)
            renderIcon={IconGradebookLine}
            screenReaderLabel={I18n.t('Show My Grades')}
            onClick={this.toggleGradesTray}
            display={isSmallSize ? 'block' : 'inline-block'}
          >
            {I18n.t('My Grades')}
          </Button>
        </Flex.Item>

        <Flex.Item overflowY="visible">
          <Popover
            onHideContent={this.closeOpportunitiesDropdown}
            // @ts-expect-error TS2339 (typescriptify)
            isShowingContent={this.state.opportunitiesOpen}
            on="click"
            renderTrigger={this.renderOpportunitiesButton('none', isSmallSize)}
            withArrow={withArrow}
            positionTarget={positionTarget}
            constrain="window"
            // @ts-expect-error TS2322 (typescriptify)
            placement={placement}
            offsetY={offsetY}
          >
            <Opportunities
              togglePopover={this.closeOpportunitiesDropdown}
              // @ts-expect-error TS2339 (typescriptify)
              newOpportunities={this.state.newOpportunities}
              // @ts-expect-error TS2339 (typescriptify)
              dismissedOpportunities={this.state.dismissedOpportunities}
              // @ts-expect-error TS2339 (typescriptify)
              courses={this.props.courses}
              // @ts-expect-error TS2339 (typescriptify)
              timeZone={this.props.timeZone}
              // @ts-expect-error TS2339 (typescriptify)
              dismiss={this.props.dismissOpportunity}
              maxHeight={verticalRoom}
              // @ts-expect-error TS2339 (typescriptify)
              isObserving={this.props.isObserving}
            />
          </Popover>
        </Flex.Item>

        <Tray
          // @ts-expect-error TS2339 (typescriptify)
          open={this.state.trayOpen}
          label={this.getTrayLabel()}
          placement="end"
          shouldContainFocus={true}
          shouldReturnFocus={false}
          onDismiss={this.handleCloseTray}
        >
          <CloseButton
            placement="start"
            onClick={this.handleCloseTray}
            screenReaderLabel={I18n.t('Close')}
          />
          <UpdateItemTray
            // @ts-expect-error TS2339 (typescriptify)
            locale={this.props.locale}
            // @ts-expect-error TS2339 (typescriptify)
            timeZone={this.props.timeZone}
            // @ts-expect-error TS2339 (typescriptify)
            noteItem={this.props.todo.updateTodoItem}
            onSavePlannerItem={this.handleSavePlannerItem}
            onDeletePlannerItem={this.handleDeletePlannerItem}
            // @ts-expect-error TS2339 (typescriptify)
            courses={this.props.courses}
          />
        </Tray>
        <Tray
          label={I18n.t('My Grades')}
          // @ts-expect-error TS2339 (typescriptify)
          open={this.state.gradesTrayOpen}
          placement="end"
          shouldContainFocus={true}
          shouldReturnFocus={true}
          onDismiss={this.toggleGradesTray}
        >
          <View as="div" padding="large large medium">
            <CloseButton
              placement="start"
              onClick={this.toggleGradesTray}
              screenReaderLabel={I18n.t('Close')}
            />
            <GradesDisplay
              // @ts-expect-error TS2339 (typescriptify)
              courses={this.props.courses}
              // @ts-expect-error TS2339 (typescriptify)
              loading={this.props.loading.loadingGrades}
              // @ts-expect-error TS2339 (typescriptify)
              loadingError={this.props.loading.gradesLoadingError}
            />
          </View>
        </Tray>
        {this.renderNewActivity()}
      </Flex>
    )
  }
}

export const ResponsivePlannerHeader = responsiviser()(PlannerHeader)
export const NotifierPlannerHeader = notifier(ResponsivePlannerHeader)

const mapStateToProps = ({
  // @ts-expect-error TS7031 (typescriptify)
  opportunities,
  // @ts-expect-error TS7031 (typescriptify)
  loading,
  // @ts-expect-error TS7031 (typescriptify)
  courses,
  // @ts-expect-error TS7031 (typescriptify)
  todo,
  // @ts-expect-error TS7031 (typescriptify)
  days,
  // @ts-expect-error TS7031 (typescriptify)
  timeZone,
  // @ts-expect-error TS7031 (typescriptify)
  ui,
  // @ts-expect-error TS7031 (typescriptify)
  firstNewActivityDate,
  // @ts-expect-error TS7031 (typescriptify)
  selectedObservee,
  // @ts-expect-error TS7031 (typescriptify)
  currentUser,
}) => ({
  opportunities,
  loading,
  courses,
  todo,
  days,
  timeZone,
  ui,
  firstNewActivityDate,
  isObserving: !!observedUserId({selectedObservee, currentUser}),
  selectedObservee,
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
  scrollToNewActivity,
  setGradesTrayState,
}

export default connect(mapStateToProps, mapDispatchToProps)(NotifierPlannerHeader)
