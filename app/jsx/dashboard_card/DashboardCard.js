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

import _ from 'underscore'
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!dashcards'
import DashboardCardAction from './DashboardCardAction'
import CourseActivitySummaryStore from './CourseActivitySummaryStore'
import DashboardCardMenu from './DashboardCardMenu'

export default class DashboardCard extends Component {

  // ===============
  //     CONFIG
  // ===============

  static propTypes = {
    id: PropTypes.string.isRequired,
    backgroundColor: PropTypes.string,
    shortName: PropTypes.string.isRequired,
    originalName: PropTypes.string.isRequired,
    courseCode: PropTypes.string.isRequired,
    assetString: PropTypes.string.isRequired,
    term: PropTypes.string,
    href: PropTypes.string.isRequired,
    links: PropTypes.arrayOf(PropTypes.object),
    image: PropTypes.string,
    handleColorChange: PropTypes.func,
    hideColorOverlays: PropTypes.bool,
    reorderingEnabled: PropTypes.bool,
    isDragging: PropTypes.bool,
    connectDragSource: PropTypes.func,
    connectDropTarget: PropTypes.func,
    moveCard: PropTypes.func,
    totalCards: PropTypes.number,
    position: PropTypes.oneOfType([PropTypes.number, PropTypes.func])
  }

  static defaultProps = {
    backgroundColor: '#394B58',
    term: null,
    links: [],
    hideColorOverlays: false,
    handleColorChange: () => {},
    image: '',
    reorderingEnabled: false,
    isDragging: false,
    connectDragSource: () => {},
    connectDropTarget: () => {},
    moveCard: () => {},
    totalCards: 0,
    position: 0
  }

  constructor (props) {
    super()

    this.state = _.extend(
      { nicknameInfo: this.nicknameInfo(props.shortName, props.originalName, props.id) },
      CourseActivitySummaryStore.getStateForCourse(props.id)
    )
  }

  // ===============
  //    LIFECYCLE
  // ===============

  componentDidMount () {
    CourseActivitySummaryStore.addChangeListener(this.handleStoreChange)
    this.parentNode = this.cardDiv
  }

  componentWillUnmount () {
    CourseActivitySummaryStore.removeChangeListener(this.handleStoreChange)
  }

  // ===============
  //    ACTIONS
  // ===============

  settingsClick = (e) => {
    if (e) { e.preventDefault(); }
    this.toggleEditing();
  }

  getCardPosition () {
    return typeof this.props.position === 'function' ? this.props.position() : this.props.position
  }

  handleNicknameChange = (nickname) => {
    this.setState({ nicknameInfo: this.nicknameInfo(nickname, this.props.originalName, this.props.id) })
  }

  handleStoreChange = () => {
    this.setState(
      CourseActivitySummaryStore.getStateForCourse(this.props.id)
    );
  }

  toggleEditing = () => {
    const currentState = !!this.state.editing;
    this.setState({editing: !currentState});
  }

  headerClick = (e) => {
    if (e) { e.preventDefault(); }
    window.location = this.props.href;
  }

  doneEditing = () => {
    this.setState({editing: false})
    this.settingsToggle.focus();
  }

  handleColorChange = (color) => {
    const hexColor = `#${color}`;
    this.props.handleColorChange(hexColor)
  }

  handleMove = (assetString, atIndex) => {
    if (typeof this.props.moveCard === 'function') {
      this.props.moveCard(assetString, atIndex, () => { this.settingsToggle.focus() })
    }
  }

  // ===============
  //    HELPERS
  // ===============

  nicknameInfo (nickname, originalName, courseId) {
    return {
      nickname,
      originalName,
      courseId,
      onNicknameChange: this.handleNicknameChange
    }
  }

  unreadCount (icon, stream) {
    const activityType = {
      'icon-announcement': 'Announcement',
      'icon-assignment': 'Message',
      'icon-discussion': 'DiscussionTopic'
    }[icon];

    const itemStream = stream || [];
    const streamItem = _.find(itemStream, item => (
      // only return 'Message' type if category is 'Due Date' (for assignments)
      item.type === activityType &&
        (activityType !== 'Message' || item.notification_category === I18n.t('Due Date'))
    ));

    // TODO: unread count is always 0 for assignments (see CNVS-21227)
    return (streamItem) ? streamItem.unread_count : 0;
  }

  calculateMenuOptions () {
    const position = this.getCardPosition()
    const isFirstCard = position === 0;
    const isLastCard = position === this.props.totalCards - 1;
    return {
      canMoveLeft: !isFirstCard,
      canMoveRight: !isLastCard,
      canMoveToBeginning: !isFirstCard,
      canMoveToEnd: !isLastCard
    }
  }

  // ===============
  //    RENDERING
  // ===============

  linksForCard () {
    return this.props.links.map((link) => {
      if (!link.hidden) {
        const screenReaderLabel = `${link.label} - ${this.state.nicknameInfo.nickname}`;
        return (
          <DashboardCardAction
            unreadCount={this.unreadCount(link.icon, this.state.stream)}
            iconClass={link.icon}
            linkClass={link.css_class}
            path={link.path}
            screenReaderLabel={screenReaderLabel}
            key={link.path}
          />
        );
      }
      return null;
    });
  }

  renderHeaderHero () {
    const {
      image,
      backgroundColor,
      hideColorOverlays
    } = this.props;

    if (image) {
      return (
        <div
          className="ic-DashboardCard__header_image"
          style={{backgroundImage: `url(${image})`}}
        >
          <div
            className="ic-DashboardCard__header_hero"
            style={{backgroundColor, opacity: hideColorOverlays ? 0 : 0.6}}
            onClick={this.headerClick}
            aria-hidden="true"
          />
        </div>
      );
    }

    return (
      <div
        className="ic-DashboardCard__header_hero"
        style={{backgroundColor}}
        onClick={this.headerClick}
        aria-hidden="true"
      />
    );
  }

  renderHeaderButton () {
    const {
      backgroundColor,
      hideColorOverlays
    } = this.props;

    const reorderingProps = this.props.reorderingEnabled && {
      reorderingEnabled: this.props.reorderingEnabled,
      handleMove: this.handleMove,
      currentPosition: this.getCardPosition(),
      lastPosition: this.props.totalCards - 1,
      menuOptions: this.calculateMenuOptions()
    }

    const nickname = this.state.nicknameInfo.nickname

    return (
      <div>
        <div
          className="ic-DashboardCard__header-button-bg"
          style={{backgroundColor, opacity: hideColorOverlays ? 1 : 0}}
        />
        <DashboardCardMenu
          afterUpdateColor={this.handleColorChange}
          currentColor={this.props.backgroundColor}
          nicknameInfo={this.state.nicknameInfo}
          assetString={this.props.assetString}
          {...reorderingProps}
          trigger={
            <button
              className="Button Button--icon-action-rev ic-DashboardCard__header-button"
              ref={(c) => { this.settingsToggle = c }}
            >
              <i className="icon-more" aria-hidden="true" />
              <span className="screenreader-only">
                { this.props.reorderingEnabled
                  ? I18n.t('Choose a color or course nickname or move course card for %{course}', { course: nickname })
                  : I18n.t('Choose a color or course nickname for %{course}', { course: nickname })
                }
              </span>
            </button>
          }
        />
      </div>
    )
  }

  render () {
    const dashboardCard = (
      <div
        className="ic-DashboardCard"
        ref={(c) => { this.cardDiv = c }}
        style={{ opacity: (this.props.reorderingEnabled && this.props.isDragging) ? 0 : 1 }}
        aria-label={this.props.originalName}
      >
        <div className="ic-DashboardCard__header">
          <span className="screenreader-only">
            {
              this.props.image ?
                I18n.t('Course image for %{course}', {course: this.state.nicknameInfo.nickname})
                : I18n.t('Course card color region for %{course}', {course: this.state.nicknameInfo.nickname})
            }
          </span>
          {this.renderHeaderHero()}
          <a href={this.props.href} className="ic-DashboardCard__link">
            <div className="ic-DashboardCard__header_content">
              <h2 className="ic-DashboardCard__header-title ellipsis" title={this.props.originalName}>
                <span style={{color: this.props.backgroundColor}}>
                  {this.state.nicknameInfo.nickname}
                </span>
              </h2>
              <div
                className="ic-DashboardCard__header-subtitle ellipsis"
                title={this.props.courseCode}
              >
                {this.props.courseCode}
              </div>
              <div
                className="ic-DashboardCard__header-term ellipsis"
                title={this.props.term}
              >
                {(this.props.term) ? this.props.term : null}
              </div>
            </div>
          </a>
          { this.renderHeaderButton() }
        </div>
        <nav
          className="ic-DashboardCard__action-container"
          aria-label={I18n.t('Actions for %{course}', {course: this.state.nicknameInfo.nickname})}
        >
          { this.linksForCard() }
        </nav>
      </div>
    );

    if (this.props.reorderingEnabled) {
      const { connectDragSource, connectDropTarget } = this.props;
      return connectDragSource(connectDropTarget(dashboardCard));
    }

    return dashboardCard;
  }
}
