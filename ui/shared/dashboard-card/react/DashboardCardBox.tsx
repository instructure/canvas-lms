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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {Text} from '@instructure/ui-text'

import DraggableDashboardCard from './DraggableDashboardCard'
import DashboardCardBackgroundStore from './DashboardCardBackgroundStore'
import MovementUtils from './MovementUtils'
import {showNoFavoritesAlert} from './ConfirmUnfavoriteCourseModal'
import type {Card} from '../types'

const I18n = useI18nScope('dashcards')

type Props = {
  cardComponent: any
  courseCards: any[]
  headingLevel: string // 'h2' | 'h3'
  hideColorOverlays: boolean
  connectDropTarget: any
  showSplitDashboardView: boolean
  observedUserId: string
}

type State = {
  courseCards: Card[]
  observedUserId: string
}

export default class DashboardCardBox extends React.Component<Props, State> {
  static defaultProps = {
    courseCards: [],
    headingLevel: 'h2',
    hideColorOverlays: false,
    connectDropTarget: (el: unknown) => el,
    showSplitDashboardView: false,
  }

  constructor(props: Props) {
    super(props)

    this.state = {
      observedUserId: props.observedUserId,
      courseCards: [],
    }
    this.handleRerenderCards = this.handleRerenderCards.bind(this)
  }

  UNSAFE_componentWillMount() {
    this.setState({
      courseCards: this.props.courseCards,
    })
  }

  componentDidMount() {
    DashboardCardBackgroundStore.addChangeListener(this.colorsUpdated)
    DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings())
  }

  UNSAFE_componentWillReceiveProps(newProps: Props) {
    DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings())

    // Only reset card state if the passed-in card props actually changed
    if (this.props.courseCards !== newProps.courseCards) {
      this.setState({
        courseCards: newProps.courseCards,
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

  colorForCard = (assetString: string) => DashboardCardBackgroundStore.colorForCourse(assetString)

  handleColorChange = (assetString: string, newColor: string) => {
    DashboardCardBackgroundStore.setColorForCourse(assetString, newColor)
  }

  getOriginalIndex = (assetString: string) =>
    this.state.courseCards.findIndex(c => c.assetString === assetString)

  moveCard = (assetString: string, atIndex: number, cb: () => void) => {
    const cardIndex = this.state.courseCards.findIndex(card => card.assetString === assetString)
    let newCards = this.state.courseCards.slice()
    newCards.splice(atIndex, 0, newCards.splice(cardIndex, 1)[0])
    newCards = newCards.map((card, index) => {
      const newCard = {...card}
      newCard.position = index
      return newCard
    })
    this.setState(
      () => {
        return {
          courseCards: newCards,
        }
      },
      () => {
        MovementUtils.updatePositions(this.state.courseCards, String(window.ENV.current_user_id))
        if (typeof cb === 'function') {
          cb()
        }
      }
    )
  }

  handleRerenderCards(courseId: string) {
    const cardIndex = this.state.courseCards.findIndex(card => card.id === courseId)
    const newCards = this.state.courseCards.slice()
    newCards[cardIndex].isFavorited = false
    newCards.splice(cardIndex, 1)
    this.setState(
      () => {
        return {
          courseCards: newCards,
        }
      },
      () => {
        if (newCards.length === 0) {
          showNoFavoritesAlert()
        }
      }
    )
  }

  handlePublishedCourse = (courseId: string) => {
    const cardIndex = this.state.courseCards.findIndex(card => card.id === courseId)
    const newCards = this.state.courseCards.slice()
    newCards[cardIndex].published = true
    this.setState(() => {
      return {
        courseCards: newCards,
      }
    })
  }

  renderCard = (card: Card) => {
    const position =
      card.position !== null ? card.position : () => this.getOriginalIndex(card.assetString)
    const cardHeadingLevel = this.props.showSplitDashboardView
      ? // @ts-expect-error
        this.props.headingLevel.replace(/\d/, n => ++n)
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
        courseColor={card.color}
        handleColorChange={(newColor: string) => this.handleColorChange(card.assetString, newColor)}
        image={card.image}
        hideColorOverlays={this.props.hideColorOverlays}
        onConfirmUnfavorite={this.handleRerenderCards}
        onPublishedCourse={this.handlePublishedCourse}
        position={position}
        moveCard={this.moveCard}
        totalCards={this.state.courseCards.length}
        isFavorited={card.isFavorited}
        enrollmentType={card.enrollmentType}
        observee={card.observee}
        published={!!card.published}
        canChangeCoursePublishState={!!card.canChangeCoursePublishState}
        defaultView={card.defaultView}
        pagesUrl={card.pagesUrl}
        frontPageTitle={card.frontPageTitle}
        cardComponent={this.props.cardComponent}
        headingLevel={cardHeadingLevel}
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
      <div key={this.state.observedUserId} className="unpublished_courses_redesign">
        <div className="ic-DashboardCard__box">
          {/* @ts-expect-error */}
          <HeadingElement className="ic-DashboardCard__box__header">
            {I18n.t(`Published Courses (%{count})`, {
              count: I18n.n(publishedCourses.length),
            })}
          </HeadingElement>
          {publishedCourses.length > 0 ? (
            <div className="ic-DashboardCard__box__container">{publishedCourses}</div>
          ) : (
            emptyEl
          )}
        </div>
        <div className="ic-DashboardCard__box">
          {/* @ts-expect-error */}
          <HeadingElement className="ic-DashboardCard__box__header">
            {I18n.t(`Unpublished Courses (%{count})`, {
              count: I18n.n(unpublishedCourses.length),
            })}
          </HeadingElement>
          {unpublishedCourses.length > 0 ? (
            <div className="ic-DashboardCard__box__container">{unpublishedCourses}</div>
          ) : (
            emptyEl
          )}
        </div>
      </div>
    )
  }

  render() {
    const {connectDropTarget, showSplitDashboardView} = this.props
    let dashboardCardBox
    if (!showSplitDashboardView) {
      const cards = this.state.courseCards.map(card => this.renderCard(card))
      dashboardCardBox = (
        <div key={this.state.observedUserId} className="ic-DashboardCard__box">
          <div className="ic-DashboardCard__box__container">{cards}</div>
        </div>
      )
    } else {
      dashboardCardBox = this.renderSplitDashboard()
    }

    return connectDropTarget(dashboardCardBox)
  }
}
