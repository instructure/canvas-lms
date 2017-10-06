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
import DashboardColorPicker from './DashboardColorPicker'
import CourseActivitySummaryStore from './CourseActivitySummaryStore'
import DashboardCardMovementMenu from './DashboardCardMovementMenu'

export default class DashboardCard extends Component {

  // ===============
  //     CONFIG
  // ===============

  static propTypes = {
    id: PropTypes.string.isRequired,
    backgroundColor: PropTypes.string.isRequired,
    shortName: PropTypes.string.isRequired,
    originalName: PropTypes.string.isRequired,
    courseCode: PropTypes.string.isRequired,
    assetString: PropTypes.string.isRequired,
    term: PropTypes.string,
    href: PropTypes.string.isRequired,
    links: PropTypes.arrayOf(PropTypes.object),
    imagesEnabled: PropTypes.bool,
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
    term: null,
    links: [],
    hideColorOverlays: false,
    imagesEnabled: false,
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
    const isFirstCard = this.props.position === 0;
    const isLastCard = this.props.position === this.props.totalCards - 1;
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

  colorPickerID () {
    return `DashboardColorPicker-${this.props.assetString}`;
  }

  colorPickerIfEditing () {
    return (
      <DashboardColorPicker
        isOpen={this.state.editing}
        elementID={this.colorPickerID()}
        parentNode={this.parentNode}
        doneEditing={this.doneEditing}
        handleColorChange={this.handleColorChange}
        assetString={this.props.assetString}
        settingsToggle={this.settingsToggle}
        backgroundColor={this.props.backgroundColor}
        nicknameInfo={this.state.nicknameInfo}
      />
    );
  }

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
      imagesEnabled,
      image,
      backgroundColor,
      hideColorOverlays
    } = this.props;

    if (imagesEnabled && image) {
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

    return (
      <div>
        <div
          className="ic-DashboardCard__header-button-bg"
          style={{backgroundColor, opacity: hideColorOverlays ? 1 : 0}}
        />
        <button
          aria-expanded={this.state.editing}
          aria-controls={this.colorPickerID()}
          className="Button Button--icon-action-rev ic-DashboardCard__header-button"
          onClick={this.settingsClick}
          ref={(c) => { this.settingsToggle = c; }}
        >
          <i className="icon-more" aria-hidden="true" />
          <span className="screenreader-only">
            { I18n.t('Choose a color or course nickname for %{course}', { course: this.state.nicknameInfo.nickname}) }
          </span>
        </button>
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
              this.props.imagesEnabled && this.props.image ?
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
          {this.props.reorderingEnabled && (
            <DashboardCardMovementMenu
              cardTitle={this.state.nicknameInfo.nickname}
              handleMove={this.props.moveCard}
              currentPosition={this.props.position}
              lastPosition={this.props.totalCards - 1}
              assetString={this.props.assetString}
              menuOptions={this.calculateMenuOptions()}
            />
          )}
          { this.renderHeaderButton() }

        </div>
        <nav
          className="ic-DashboardCard__action-container"
          aria-label={I18n.t('Actions for %{course}', {course: this.state.nicknameInfo.nickname})}
        >
          { this.linksForCard() }
        </nav>
        { this.colorPickerIfEditing() }
      </div>
    );

    if (this.props.reorderingEnabled) {
      const { connectDragSource, connectDropTarget } = this.props;
      return connectDragSource(connectDropTarget(dashboardCard));
    }

    return dashboardCard;
  }
}
