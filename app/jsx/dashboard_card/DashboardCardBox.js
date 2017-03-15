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

import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import DashboardCard from './DashboardCard'
import DraggableDashboardCard from './DraggableDashboardCard'
import DashboardCardBackgroundStore from './DashboardCardBackgroundStore'
import MovementUtils from './MovementUtils'
  const DashboardCardBox = React.createClass({

    displayName: 'DashboardCardBox',

    propTypes: {
      courseCards: PropTypes.array,
      reorderingEnabled: PropTypes.bool,
      hideColorOverlays: PropTypes.bool,
      connectDropTarget: PropTypes.func
    },

    componentWillMount () {
      this.setState({
        courseCards: this.props.courseCards
      });
    },

    componentDidMount: function(){
      DashboardCardBackgroundStore.addChangeListener(this.colorsUpdated);
      DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings());
    },

    componentWillReceiveProps: function (newProps) {
      DashboardCardBackgroundStore.setDefaultColors(this.allCourseAssetStrings());

      this.setState({
        courseCards: newProps.courseCards
      });
    },

    getDefaultProps: function () {
      return {
        courseCards: [],
        hideColorOverlays: false
      };
    },

    colorsUpdated: function(){
      if(this.isMounted()){
        this.forceUpdate();
      }
    },

    allCourseAssetStrings: function(){
      return this.props.courseCards.map(card => card.assetString);
    },

    colorForCard: function(assetString){
      return DashboardCardBackgroundStore.colorForCourse(assetString);
    },

    handleColorChange: function(assetString, newColor){
      DashboardCardBackgroundStore.setColorForCourse(assetString, newColor);
    },

    getOriginalIndex (assetString) {
      return this.state.courseCards.findIndex(c => c.assetString === assetString);
    },

    moveCard (assetString, atIndex, cb) {
      const cardIndex = this.state.courseCards.findIndex(card => card.assetString === assetString);
      let newCards = this.state.courseCards.slice();
      newCards.splice(atIndex, 0, newCards.splice(cardIndex, 1)[0]);
      newCards = newCards.map((card, index) => {
        const newCard = Object.assign({}, card);
        newCard.position = index;
        return newCard;
      });
      this.setState({
        courseCards: newCards
      }, () => {
        MovementUtils.updatePositions(this.state.courseCards, window.ENV.current_user_id);
        if (typeof cb === 'function') {
          cb()
        }
      });
    },

    render: function () {
      const Component = (this.props.reorderingEnabled) ? DraggableDashboardCard : DashboardCard;
      const cards = this.state.courseCards.map((card, index) => {
        const position = (card.position != null) ? card.position : this.getOriginalIndex.bind(this, card.assetString)
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
            handleColorChange={this.handleColorChange.bind(this, card.assetString)}
            image={card.image}
            imagesEnabled={card.imagesEnabled}
            reorderingEnabled={this.props.reorderingEnabled}
            hideColorOverlays={this.props.hideColorOverlays}
            position={position}
            currentIndex={index}
            moveCard={this.moveCard}
            totalCards={this.state.courseCards.length}
          />
        );
      });

      const dashboardCardBox = (
        <div className="ic-DashboardCard__box">
          {cards}
        </div>
      );

      if (this.props.reorderingEnabled) {
        const { connectDropTarget } = this.props;
        return connectDropTarget(dashboardCardBox);
      }

      return dashboardCardBox;
    }
  });

export default DashboardCardBox
