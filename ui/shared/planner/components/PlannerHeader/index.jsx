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
import {useScope as useI18nScope} from '@canvas/i18n'
import {notifier} from '../../dynamic-ui'
import {getFirstLoadedMoment} from '../../utilities/dateUtils'
import {observedUserId} from '../../utilities/apiUtils'
import buildStyle from './style'

const I18n = useI18nScope('planner')

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
        ])
      )
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
      opportunitiesOpen: false,
    }
    this.style = buildStyle()
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
      this.props.startLoadingGradesSaga(this.props.isObserving ? this.props.selectedObservee : null)
    }
    this.props.setGradesTrayState(!this.state.gradesTrayOpen)
    this.setState(prevState => ({gradesTrayOpen: !prevState.gradesTrayOpen}))
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
    return I18n.t(
      {
        zero: '0 opportunities',
        one: '1 opportunity',
        other: '%{count} opportunities',
      },
      {
        count: this.state.newOpportunities.length,
      }
    )
  }

  getTrayLabel = () => {
    if (this.props.todo.updateTodoItem && this.props.todo.updateTodoItem.title) {
      return I18n.t('Edit %{title}', {title: this.props.todo.updateTodoItem.title})
    }
    return I18n.t('Add To Do')
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

  getPopupVerticalProperties() {
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
          elementRef={ref => (this.newActivityButtonRef = ref)}
          className="StickyButton-styles__newActivityButton"
          description={I18n.t('Scrolls up to the previous item with new activity.')}
        >
          {I18n.t('New Activity')}
        </StickyButton>
      </Portal>
    )
  }

  renderToday(buttonMargin, isSmallSize = null) {
    // if we're not displaying any items, don't show the today button
    // this is true if the planner is completely empty, or showing the balloons
    // because everything is in the past when first loaded
    if (this.props.days.length > 0) {
      return (
        <Button
          id="planner-today-btn"
          color={ENV.FEATURES?.instui_header ? 'secondary' : "primary-inverse"}
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

  renderOpportunitiesButton(margin, isSmallSize=false) {
    const badgeProps = {margin, countUntil: 100, display:(isSmallSize ? 'block' : 'inline-block')}
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
        {ENV.FEATURES?.instui_header ? 
          <Button
          renderIcon={IconAlertsLine}
          screenReaderLabel={I18n.t('opportunities popup')}
          onClick={this.toggleOpportunitiesDropdown}
          display={isSmallSize ? 'block' : 'inline-block'}
          ref={b => {
            this.opportunitiesButton = b
          }}
          elementRef={b => {
            this.opportunitiesHtmlButton = b
          }}
          >
            {I18n.t('Opportunities')}
          </Button>
        : 
          <IconButton
            renderIcon={IconAlertsLine}
            screenReaderLabel={I18n.t('opportunities popup')}
            withBorder={false}
            withBackground={false}
            onClick={this.toggleOpportunitiesDropdown}
            ref={b => {
              this.opportunitiesButton = b
            }}
            elementRef={b => {
              this.opportunitiesHtmlButton = b
            }}
          />
        }
      </Badge>
    )
  }

  renderLegacy() {
    const {
      verticalRoom,
      buttonMargin,
      withArrow,
      positionTarget,
      placement,
      offsetY
    } = this.getPopupVerticalProperties()

    return (
      <>
        <style>{this.style.css}</style>
        <div className={`${this.style.classNames.root} PlannerHeader`} data-testid="PlannerHeader">
          {this.renderToday(buttonMargin)}
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
            isShowingContent={this.state.opportunitiesOpen}
            on="click"
            renderTrigger={this.renderOpportunitiesButton(buttonMargin)}
            withArrow={withArrow}
            positionTarget={positionTarget}
            constrain="window"
            placement={placement}
            offsetY={offsetY}
          >
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
          </Popover>
          <Tray
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
              locale={this.props.locale}
              timeZone={this.props.timeZone}
              noteItem={this.props.todo.updateTodoItem}
              onSavePlannerItem={this.handleSavePlannerItem}
              onDeletePlannerItem={this.handleDeletePlannerItem}
              courses={this.props.courses}
            />
          </Tray>
          <Tray
            label={I18n.t('My Grades')}
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
                courses={this.props.courses}
                loading={this.props.loading.loadingGrades}
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

    const {
      verticalRoom,
      withArrow,
      positionTarget,
      placement,
      offsetY
    } = this.getPopupVerticalProperties()

    const isSmallSize = this.props.responsiveSize === 'small'
    const renderTodayButton = this.renderToday('none', isSmallSize)
    
    return (
      <Flex
        gap="small"
        withVisualDebug={false}
        direction={isSmallSize ? 'column' : 'row'}
      >
        {renderTodayButton &&
          <Flex.Item overflowY="visible">{renderTodayButton}</Flex.Item>
        }
        
        {!this.props.isObserving && (
          <Flex.Item overflowY="visible">
            <Button
              renderIcon={IconPlusLine}
              data-testid="add-to-do-button"
              screenReaderLabel={I18n.t('Add To Do')}
              onClick={this.handleToggleTray}
              ref={b => {
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
            isShowingContent={this.state.opportunitiesOpen}
            on="click"
            renderTrigger={this.renderOpportunitiesButton('none', isSmallSize)}
            withArrow={withArrow}
            positionTarget={positionTarget}
            constrain="window"
            placement={placement}
            offsetY={offsetY}
          >
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
          </Popover>        
        </Flex.Item>
          
        <Tray
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
            locale={this.props.locale}
            timeZone={this.props.timeZone}
            noteItem={this.props.todo.updateTodoItem}
            onSavePlannerItem={this.handleSavePlannerItem}
            onDeletePlannerItem={this.handleDeletePlannerItem}
            courses={this.props.courses}
          />
        </Tray>
        <Tray
          label={I18n.t('My Grades')}
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
              courses={this.props.courses}
              loading={this.props.loading.loadingGrades}
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
  opportunities,
  loading,
  courses,
  todo,
  days,
  timeZone,
  ui,
  firstNewActivityDate,
  selectedObservee,
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
