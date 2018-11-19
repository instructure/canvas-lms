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

import React from 'react'
import PropTypes from 'prop-types'
import DraggableDashboardCard from './DraggableDashboardCard'
import DashboardCardBackgroundStore from './DashboardCardBackgroundStore'
import MovementUtils from './MovementUtils'

export default class DashboardCardBox extends React.Component {
  static propTypes = {
    courseCards: PropTypes.arrayOf(PropTypes.object),
    hideColorOverlays: PropTypes.bool,
    connectDropTarget: PropTypes.func
  }

  static defaultProps = {
    courseCards: [],
    hideColorOverlays: false,
    connectDropTarget: el => el
  }

  componentWillMount() {
    this.setState({
      courseCards: this.props.courseCards
    })
  }

  componentDidMount() {
    DashboardCardBackgroundStore.addChangeListener(this.colorsUpdated)
    DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings())
  }

  componentWillReceiveProps(newProps) {
    DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings())

    this.setState({
      courseCards: newProps.courseCards
    })
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
      const newCard = Object.assign({}, card)
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

  render() {
    const Component = DraggableDashboardCard
    const cards = this.state.courseCards.map((card, index) => {
      const position =
        card.position != null ? card.position : () => this.getOriginalIndex(card.assetString)
      return (
        <Component
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
          position={position}
          currentIndex={index}
          moveCard={this.moveCard}
          totalCards={this.state.courseCards.length}
        />
      )
    })

    const dashboardCardBox = <div className="ic-DashboardCard__box">{cards}</div>

    const {connectDropTarget} = this.props
    return connectDropTarget(dashboardCardBox)
  }
}
