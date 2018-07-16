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

import React, { Component } from 'react';
import { connect } from 'react-redux';
import { func, arrayOf, object, bool, string } from 'prop-types';
import moment from 'moment-timezone';

import formatMessage from '../../format-message';
import List from '@instructure/ui-elements/lib/components/List';
import ListItem from '@instructure/ui-elements/lib/components/List/ListItem';
import View from '@instructure/ui-layout/lib/components/View';
import Spinner from '@instructure/ui-elements/lib/components/Spinner';
import Button from '@instructure/ui-buttons/lib/components/Button';

import { sidebarLoadInitialItems, sidebarCompleteItem } from '../../actions';
import ToDoItem from './ToDoItem';

export class ToDoSidebar extends Component {
  static propTypes = {
    sidebarLoadInitialItems: func.isRequired,
    sidebarCompleteItem: func.isRequired,
    items: arrayOf(object).isRequired,
    loaded: bool,
    courses: arrayOf(object).isRequired,
    timeZone: string,
    locale: string,
    changeDashboardView: func.isRequired,
  };

  static defaultProps = {
    loaded: false,
    timeZone: moment.tz.guess(),
    locale: 'en',
  }

  constructor () {
    super();
    this.dismissedItemIndex = null;
    this.titleFocus = null;
  }

  componentDidMount () {
    this.props.sidebarLoadInitialItems(moment.tz(this.props.timeZone).startOf('day'));
  }

  componentDidUpdate () {
    if (this.dismissedItemIndex != null) {
      const previousIndex = this.dismissedItemIndex - 1;
      this.dismissedItemIndex = null;
      if (previousIndex >= 0) {
        this.todoItemComponents[previousIndex].focus();
      } else {
        this.titleFocus.focus();
      }
    }
  }

  handleDismissClick (itemIndex, item) {
    this.dismissedItemIndex = itemIndex;
    this.props.sidebarCompleteItem(item)
      .catch(() => {this.dismissedItemIndex = null;});
  }

  renderShowAll () {
    return (
      <View as="div" textAlign="center">
        <Button variant="link" onClick={() => this.props.changeDashboardView('planner')}>
          {formatMessage('Show All')}
        </Button>
      </View>
    );
  }

  render () {
    if (!this.props.loaded) {
      return (
        <View as="div" textAlign="center">
          <Spinner title={formatMessage('To Do Items Loading')} size="small" />
        </View>
      );
    }

    const incompletedFilter = (item) => {
      if (!item) return false;
      return !item.completed;
    };

    const visibleTodos = this.props.items.filter(incompletedFilter).slice(0, 5);

    this.todoItemComponents = [];
    return (
      <div>
        <h2 className="todo-list-header">
          <span tabIndex="-1" ref={elt => {this.titleFocus = elt;}}>{formatMessage('To Do')}</span>
        </h2>
        <List variant="unstyled">
          {
            visibleTodos.map((item, itemIndex) => (
              <ListItem key={item.uniqueId}>
                <ToDoItem
                  ref={component => {this.todoItemComponents[itemIndex] = component;}}
                  item={item}
                  courses={this.props.courses}
                  handleDismissClick={(...args) => this.handleDismissClick(itemIndex, item)}
                  locale={this.props.locale}
                  timeZone={this.props.timeZone}
                />
              </ListItem>
            ))
          }
        </List>
        { this.renderShowAll() }
      </div>
    );
  }
}

const mapStateToProps = state => ({
  items: state.sidebar.items,
  loaded: state.sidebar.loaded,
});
const mapDispatchToProps = { sidebarLoadInitialItems, sidebarCompleteItem };

export default connect(mapStateToProps, mapDispatchToProps)(ToDoSidebar);
