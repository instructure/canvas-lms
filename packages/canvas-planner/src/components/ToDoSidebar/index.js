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
import Text from '@instructure/ui-elements/lib/components/Text';

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
    changeDashboardView: func,
    forCourse: string,
  };

  static defaultProps = {
    loaded: false,
    timeZone: moment.tz.guess(),
    locale: 'en',
    forCourse: undefined,
  }

  constructor (props) {
    super(props);
    this.dismissedItemIndex = null;
    this.titleFocus = null;

    this.state = {
      visibleToDos: this.getVisibleItems(props.items),
    };
  }

  componentDidMount () {
    this.props.sidebarLoadInitialItems(moment.tz(this.props.timeZone).startOf('day'), this.props.forCourse);
  }

  componentWillReceiveProps (nextProps) {
    const visibleToDos = this.getVisibleItems(nextProps.items);
    this.setState({
      visibleToDos,
    });
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

  getVisibleItems (items) {
    const incompletedFilter = (item) => {
      if (!item) return false;
      return !item.completed;
    };
    return items.filter(incompletedFilter).slice(0, 5);
  }

  handleDismissClick (itemIndex, item) {
    this.dismissedItemIndex = itemIndex;
    this.props.sidebarCompleteItem(item)
      .catch(() => {this.dismissedItemIndex = null;});
  }

  renderShowAll () {
    if (this.props.changeDashboardView && this.state.visibleToDos.length > 0) {
      return (
        <View as="div" textAlign="center">
          <Button variant="link" onClick={() => this.props.changeDashboardView('planner')}>
            {formatMessage('Show All')}
          </Button>
        </View>
      );
    }
    return null;
  }

  renderItems () {
    this.todoItemComponents = [];

    if (this.state.visibleToDos.length === 0) {
      return <Text size="small">{formatMessage('Nothing for now')}</Text>
    }

    return (
      <List id="planner-todosidebar-item-list" variant="unstyled">
        {
          this.state.visibleToDos.map((item, itemIndex) => (
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
    );
  }

  render () {
    if (!this.props.loaded) {
      return (
        <div>
          <h2 className="todo-list-header">
            {formatMessage('To Do')}
          </h2>
          <View as="div" textAlign="center">
            <Spinner title={formatMessage('To Do Items Loading')} size="small" />
          </View>
        </div>
      );
    }

    return (
      <div>
        <h2 className="todo-list-header">
          <span tabIndex="-1" ref={elt => {this.titleFocus = elt;}}>{formatMessage('To Do')}</span>
        </h2>
        { this.renderItems() }
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
