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
import React, { Component } from 'react';
import themeable from '@instructure/ui-themeable/lib';
import classnames from 'classnames';
import { partition } from 'lodash';
import { arrayOf, string, number, shape, func } from 'prop-types';
import { userShape, itemShape, sizeShape } from '../plannerPropTypes';
import styles from './styles.css';
import theme from './theme.js';
import PlannerItem from '../PlannerItem';
import CompletedItemsFacade from '../CompletedItemsFacade';
import NotificationBadge, { MissingIndicator, NewActivityIndicator } from '../NotificationBadge';
import moment from 'moment-timezone';
import formatMessage from '../../format-message';
import { getBadgesForItem, getBadgesForItems, showPillForOverdueStatus } from '../../utilities/statusUtils';
import { animatable } from '../../dynamic-ui';
import responsiviser from '../responsiviser';

export class Grouping extends Component {
  static propTypes = {
    items: arrayOf(shape(itemShape)).isRequired,
    animatableIndex: number,
    title: string,
    color: string,
    image_url: string,
    timeZone: string.isRequired,
    url: string,
    toggleCompletion: func,
    updateTodo: func,
    registerAnimatable: func,
    deregisterAnimatable: func,
    currentUser: shape(userShape),
    responsiveSize: sizeShape,
  };
  static defaultProps = {
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
    responsiveSize: 'large',
  };

  constructor (props) {
    super(props);

    this.state = {
      showCompletedItems: false,
      badgeMap: this.setupItemBadgeMap(props.items),
    };

  }

  componentDidMount () {
    this.props.registerAnimatable('group', this, this.props.animatableIndex, this.itemUniqueIds());
  }

  componentWillReceiveProps (newProps) {
    this.props.deregisterAnimatable('group', this, this.itemUniqueIds());
    this.props.registerAnimatable('group', this, newProps.animatableIndex, this.itemUniqueIds(newProps));
  }

  componentWillUnmount () {
    this.props.deregisterAnimatable('group', this, this.itemUniqueIds());
  }

  itemUniqueIds (props = this.props) { return props.items.map(item => item.uniqueId); }

  setupItemBadgeMap (items) {
    const mapping = {};
    items.forEach((item) => {
      const badges = getBadgesForItem(item);
      if (badges.length) mapping[item.id] = badges;
    });
    return mapping;
  }

  groupingLinkRef = (link) => {
    this.groupingLink = link;
  }

  getFocusable = () => { return this.groupingLink; }
  getScrollable () { return this.groupingLink || this.plannerNoteHero; }

  handleFacadeClick = (e) => {
    if (e) { e.preventDefault(); }
    this.setState(() => ({
      showCompletedItems: true
    }), () => {
      if (this.groupingLink) this.groupingLink.focus();
    });
  }

  getLayout() {
    return this.props.responsiveSize;
  }

  renderItemsAndFacade (items) {
    const [completedItems, otherItems ] = partition(items, item => (item.completed && !item.show));
    let itemsToRender = otherItems;
    if (this.state.showCompletedItems) {
      itemsToRender = items;
    }

    const componentsToRender = this.renderItems(itemsToRender);
    componentsToRender.push(this.renderFacade(completedItems, this.props.animatableIndex * 100 + itemsToRender.length + 1));
    return componentsToRender;
  }

  renderItems (items) {
    const showNotificationBadgeOnItem = this.getLayout() !== 'large';
    return items.map((item, itemIndex) => (
      <li
        className={styles.item}
        key={item.uniqueId}
      >
        <PlannerItem
          theme={{
            iconColor: this.props.color
          }}
          color={this.props.color}
          completed={item.completed}
          overrideId={item.overrideId}
          id={item.id}
          uniqueId={item.uniqueId}
          animatableIndex={this.props.animatableIndex * 100 + itemIndex + 1}
          courseName={this.props.title}
          context={item.context || {}}
          date={moment(item.date).tz(this.props.timeZone)}
          associated_item={item.type}
          title={item.title}
          points={item.points}
          updateTodo={this.props.updateTodo}
          html_url={item.html_url}
          toggleCompletion={() => this.props.toggleCompletion(item)}
          badges={this.state.badgeMap[item.id]}
          details={item.details}
          toggleAPIPending={item.toggleAPIPending}
          status={item.status}
          newActivity={item.newActivity}
          allDay={item.allDay}
          showNotificationBadge={showNotificationBadgeOnItem}
          currentUser={this.props.currentUser}
          feedback={item.feedback}
          location={item.location}
          address={item.address}
          endTime={item.endTime}
          dateStyle={item.dateStyle}
          timeZone={this.props.timeZone}
        />
      </li>
    ));
  }

  renderFacade (completedItems, animatableIndex) {
    const showNotificationBadgeOnItem = this.getLayout() !== 'large';
    if (!this.state.showCompletedItems && completedItems.length > 0) {
      const theDay = completedItems[0].date.clone();
      theDay.startOf('day');
      let missing = false;
      let newActivity = false;
      const completedItemIds = completedItems.map(item => {
        if (showPillForOverdueStatus('missing', item)) missing = true;
        if (item.newActivity) newActivity = true;
        return item.uniqueId;
      });
      let notificationBadge = 'none';
      if (showNotificationBadgeOnItem) {
        if (newActivity) {
          notificationBadge = 'newActivity';
        } else if (missing) {
          notificationBadge = 'missing';
        }
      }

      return (
        <li
          className={styles.item}
          key='completed'
        >
          <CompletedItemsFacade
            onClick={this.handleFacadeClick}
            itemCount={completedItems.length}
            badges={getBadgesForItems(completedItems)}
            animatableIndex={animatableIndex}
            animatableItemIds={completedItemIds}
            notificationBadge={notificationBadge}
            theme={{
              labelColor: this.props.color
            }}
            date={theDay}
            responsiveSize={this.props.responsiveSize}
          />
        </li>
      );
    }
    return null;
  }

  renderToDoText () {
    return formatMessage('To Do');
  }

  renderNotificationBadge () {
    // narrower layout puts the indicator next to the actual items
    if (this.getLayout() !== 'large') {
      return null;
    }

    let missing = false;
    const newItem = this.props.items.find(item => {
      if (showPillForOverdueStatus('missing', item)) missing = true;
      return item.newActivity;
    });
    if (newItem || missing) {
      const IndicatorComponent = newItem ? NewActivityIndicator : MissingIndicator;
      const badgeMessage = this.props.title ? this.props.title : this.renderToDoText();
      return (
        <NotificationBadge>
          <IndicatorComponent
          title={badgeMessage}
          itemIds={this.itemUniqueIds()}
          animatableIndex={this.props.animatableIndex}
          getFocusable={this.getFocusable} />
        </NotificationBadge>
      );
    } else {
      return <NotificationBadge/>;
    }
  }

  // I wouldn't have broken the background and title apart, but wrapping them in a container span breaks styling
  renderGroupLinkBackground() {
    const clazz = classnames({
      [styles.overlay]: true,
      [styles.withImage]: this.props.image_url
    });
    const style = this.getLayout() === 'large' ? { backgroundColor: this.props.color } : null;
    return <span className={clazz} style={style} />;
  }

  renderGroupLinkTitle() {
    return <span className={styles.title}>
        {this.props.title || this.renderToDoText()}
      </span>;
  }

  renderGroupLink () {
    if (!this.props.title) {
      return <span className={styles.hero} ref={elt => this.plannerNoteHero = elt}>
        {this.renderGroupLinkBackground()}
        {this.renderGroupLinkTitle()}
      </span>;
    }
    const style = this.getLayout() === 'large' ? {backgroundImage: `url(${this.props.image_url || ''})`} : null;
    return <a
      href={this.props.url || "#"}
      ref={this.groupingLinkRef}
      className={`${styles.hero} ${styles.heroHover}`}
      style={style}
    >
      {this.renderGroupLinkBackground()}
      {this.renderGroupLinkTitle()}
    </a>;
  }

  render () {
    return (
      <div className={classnames(styles.root, styles[this.getLayout()], 'planner-grouping')} >
        {this.renderNotificationBadge()}
        {this.renderGroupLink()}
        <ol className={styles.items} style={{ borderColor: this.props.color }}>
          { this.renderItemsAndFacade(this.props.items)}
        </ol>
      </div>
    );
  }
}

const ResponsiveGrouping = responsiviser()(Grouping);

export default animatable(themeable(theme, styles)(ResponsiveGrouping));
