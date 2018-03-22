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

import I18n from 'i18n!todo_sidebar';
import Heading from '@instructure/ui-core/lib/components/Heading';
import List from '@instructure/ui-core/lib/components/List';
import ListItem from '@instructure/ui-core/lib/components/List/ListItem';
import Container from '@instructure/ui-core/lib/components/Container';
import Spinner from '@instructure/ui-core/lib/components/Spinner';
import ButtonLink from '@instructure/ui-core/lib/components/Link';

import { loadInitialItems, completeItem } from './actions';
import ToDoItem from './ToDoItem';

export class ToDoSidebar extends Component {
  static propTypes = {
    loadInitialItems: func.isRequired,
    completeItem: func.isRequired,
    items: arrayOf(object).isRequired,
    loading: bool,
    courses: arrayOf(object).isRequired,
    timeZone: string
  };

  static defaultProps = {
    loading: false,
    timeZone: moment.tz.guess()
  }

  constructor () {
    super()
    this.state = { showTodos: false }
    this.dismissedItemIndex = null;
    this.titleFocus = null;
  }

  componentDidMount () {
    this.props.loadInitialItems(moment.tz(this.props.timeZone).startOf('day'));
  }

  componentDidUpdate () {
    if (this.dismissedItemIndex != null) {
      const previousIndex = this.dismissedItemIndex - 1
      this.dismissedItemIndex = null
      if (previousIndex >= 0) {
        this.todoItemComponents[previousIndex].focus()
      } else {
        this.titleFocus.focus();
      }
    }
  }

  showMoreTodos = () => {
    this.setState({showTodos: true});
  }

  handleDismissClick (itemIndex, itemType, itemId) {
    this.dismissedItemIndex = itemIndex
    this.props.completeItem(itemType, itemId)
      .catch(() => {this.dismissedItemIndex = null})
  }

  renderShowMoreTodos (items) {
    if (items.length > 5 && !this.state.showTodos) {
      const number = items.length - 5
      return (
        <ButtonLink onClick={this.showMoreTodos}>{I18n.t("%{number} More...", {number})}</ButtonLink>
      );
    }
    return null;
  }

  render () {
    if (this.props.loading) {
      return (
        <Container as="div" textAlign="center">
          <Spinner title={I18n.t('To Do Items Loading')} size="small" />
        </Container>
      );
    }

    const completedFilter = (item) => {
      if (!item) return false
      return item.planner_override == null || !item.planner_override.marked_complete
    };

    const filteredTodos = this.props.items.filter(completedFilter)
    const visibleTodos = this.state.showTodos ? filteredTodos : filteredTodos.slice(0, 5);

    this.todoItemComponents = [];
    return (
      <div>
        <h2 className="todo-list-header">
          <span tabIndex="-1" ref={elt => {this.titleFocus = elt}}>{I18n.t('To Do')}</span>
        </h2>
        <List variant="unstyled">
          {
            visibleTodos.map((item, itemIndex) => (
              <ListItem key={`${item.plannable_type}_${item.plannable_id}`}>
                <ToDoItem
                  ref={component => {this.todoItemComponents[itemIndex] = component}}
                  itemId={item.plannable_id}
                  title={item.plannable.name || item.plannable.title}
                  href={item.html_url}
                  itemType={item.plannable_type}
                  courses={this.props.courses}
                  courseId={item.course_id || item.plannable.course_id}
                  dueAt={item.plannable_date}
                  points={item.plannable.points_possible}
                  handleDismissClick={(...args) => this.handleDismissClick(itemIndex, ...args)}
                />
              </ListItem>
            ))
          }
        </List>
        { this.renderShowMoreTodos(filteredTodos) }
      </div>
    );
  }
}

const mapStateToProps = state => ({
  items: state.items,
  loading: state.loading
});
const mapDispatchToProps = { loadInitialItems, completeItem };

export default connect(mapStateToProps, mapDispatchToProps)(ToDoSidebar);
