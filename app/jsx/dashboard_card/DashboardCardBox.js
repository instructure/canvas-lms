/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import I18n from 'i18n!dashcards'
import React from 'react'
import PropTypes from 'prop-types'
import {Text} from '@instructure/ui-elements'

import DraggableDashboardCard from './DraggableDashboardCard'
import DashboardCardBackgroundStore from './DashboardCardBackgroundStore'
import MovementUtils from './MovementUtils'
import {showNoFavoritesAlert} from './ConfirmUnfavoriteCourseModal'

export default class DashboardCardBox extends React.Component {
  static propTypes = {
    cardComponent: PropTypes.elementType.isRequired,
    courseCards: PropTypes.arrayOf(PropTypes.object),
    headingLevel: PropTypes.oneOf(['h2', 'h3']),
    hideColorOverlays: PropTypes.bool,
    connectDropTarget: PropTypes.func,
    requestTabChange: PropTypes.func,
    showSplitDashboardView: PropTypes.bool
  }

  static defaultProps = {
    courseCards: [],
    headingLevel: 'h2',
    hideColorOverlays: false,
    connectDropTarget: el => el,
    showSplitDashboardView: false
  }

  constructor(props) {
    super(props)

    this.handleRerenderCards = this.handleRerenderCards.bind(this)
  }

  UNSAFE_componentWillMount() {
    this.setState({
      courseCards: this.props.courseCards
    })
  }

  componentDidMount() {
    DashboardCardBackgroundStore.addChangeListener(this.colorsUpdated)
    DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings())
  }

  UNSAFE_componentWillReceiveProps(newProps) {
    DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings())

    // Only reset card state if the passed-in card props actually changed
    if (this.props.courseCards !== newProps.courseCards) {
      this.setState({
        courseCards: newProps.courseCards
      })
    }
  }

  componentWillUnmount() {
    DashboardCardBackgroundStore.removeChangeListener(this.colorsUpdated)
  }

  colorsUpdated = () => {
    this.forceUpdate()
  }

  allCourseAssetStrings = () => this.props.courseCards.map(card => card.assetString)

  colorForCard = assetString => DashboardCardBackgroundStore.colorForCourse(assetString)

  handleColorChange = (assetString, newColor) => {
    DashboardCardBackgroundStore.setColorForCourse(assetString, newColor)
  }

  getOriginalIndex = assetString =>
    this.state.courseCards.findIndex(c => c.assetString === assetString)

  moveCard = (assetString, atIndex, cb) => {
    const cardIndex = this.state.courseCards.findIndex(card => card.assetString === assetString)
    let newCards = this.state.courseCards.slice()
    newCards.splice(atIndex, 0, newCards.splice(cardIndex, 1)[0])
    newCards = newCards.map((card, index) => {
      const newCard = {...card}
      newCard.position = index
      return newCard
    })
    this.setState(
      {
        courseCards: newCards
      },
      () => {
        MovementUtils.updatePositions(this.state.courseCards, window.ENV.current_user_id)
        if (typeof cb === 'function') {
          cb()
        }
      }
    )
  }

  handleRerenderCards(courseId) {
    const cardIndex = this.state.courseCards.findIndex(card => card.id === courseId)
    const newCards = this.state.courseCards.slice()
    newCards[cardIndex].isFavorited = false
    newCards.splice(cardIndex, 1)
    this.setState(
      {
        courseCards: newCards
      },
      () => {
        if (newCards.length === 0) {
          showNoFavoritesAlert()
        }
      }
    )
  }

  renderCard = card => {
    const position =
      card.position !== null ? card.position : () => this.getOriginalIndex(card.assetString)
    const cardHeadingLevel = this.props.showSplitDashboardView
      ? this.props.headingLevel.replace(/\d/, n => ++n)
      : this.props.headingLevel
    return (
      <DraggableDashboardCard
        key={card.id}
        shortName={card.shortName}
        originalName={card.originalName}
        courseCode={card.courseCode}
        id={card.id}
        href={card.href}
        links={card.links}
        term={card.term}
        assetString={card.assetString}
        backgroundColor={this.colorForCard(card.assetString)}
        handleColorChange={newColor => this.handleColorChange(card.assetString, newColor)}
        image={card.image}
        hideColorOverlays={this.props.hideColorOverlays}
        onConfirmUnfavorite={this.handleRerenderCards}
        position={position}
        moveCard={this.moveCard}
        totalCards={this.state.courseCards.length}
        isFavorited={card.isFavorited}
        enrollmentType={card.enrollmentType}
        observee={card.observee}
        published={!!card.published}
        canChangeCourseState={!!card.canChangeCourseState}
        defaultView={card.defaultView}
        pagesUrl={card.pagesUrl}
        frontPageTitle={card.frontPageTitle}
        cardComponent={this.props.cardComponent}
        headingLevel={cardHeadingLevel}
        requestTabChange={this.props.requestTabChange}
      />
    )
  }

  renderSplitDashboard = () => {
    const HeadingElement = this.props.headingLevel
    const {courseCards} = this.state
    const publishedCourses = courseCards
      .filter(card => card.published)
      .map(card => this.renderCard(card))

    const unpublishedCourses = courseCards
      .filter(card => !card.published)
      .map(card => this.renderCard(card))

    const emptyEl = <Text size="medium">{I18n.t('No courses to display')}</Text>

    return (
      <div className="unpublished_courses_redesign">
        <div className="ic-DashboardCard__box">
          <HeadingElement className="ic-DashboardCard__box__header">
            {I18n.t(`Published Courses (%{count})`, {
              count: I18n.n(publishedCourses.length)
            })}
          </HeadingElement>
          {publishedCourses.length > 0 ? publishedCourses : emptyEl}
        </div>
        <div className="ic-DashboardCard__box">
          <HeadingElement className="ic-DashboardCard__box__header">
            {I18n.t(`Unpublished Courses (%{count})`, {
              count: I18n.n(unpublishedCourses.length)
            })}
          </HeadingElement>
          {unpublishedCourses.length > 0 ? unpublishedCourses : emptyEl}
        </div>
      </div>
    )
  }

  render() {
    const {connectDropTarget, showSplitDashboardView} = this.props
    let dashboardCardBox = null
    if (!showSplitDashboardView) {
      const cards = this.state.courseCards.map(card => this.renderCard(card))
      dashboardCardBox = <div className="ic-DashboardCard__box">{cards}</div>
    } else {
      dashboardCardBox = this.renderSplitDashboard()
    }

    return connectDropTarget(dashboardCardBox)
  }
}
