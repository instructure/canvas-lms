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

import React, {Component} from 'react'
import {connect} from 'react-redux'
import {func, arrayOf, object, bool, string} from 'prop-types'
import moment from 'moment-timezone'

import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {IconWarningLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {observedUserId} from '../../utilities/apiUtils'

import {sidebarLoadInitialItems, sidebarCompleteItem} from '../../actions'
import ToDoItem from './ToDoItem'

const I18n = createI18nScope('planner')

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
    isObserving: bool,
    loadingError: string,
    additionalTitleContext: bool,
  }

  static defaultProps = {
    loaded: false,
    timeZone: moment.tz.guess(),
    locale: 'en',
    forCourse: undefined,
    additionalTitleContext: false,
  }

  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)
    // @ts-expect-error TS2339 (typescriptify)
    this.dismissedItemIndex = null
    // @ts-expect-error TS2339 (typescriptify)
    this.titleFocus = null

    this.state = {
      visibleToDos: this.getVisibleItems(props.items),
    }
  }

  componentDidMount() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.sidebarLoadInitialItems(
      moment
        // @ts-expect-error TS2339 (typescriptify)
        .tz(this.props.timeZone)
        .startOf('day'),
      // @ts-expect-error TS2339 (typescriptify)
      this.props.forCourse,
    )
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillReceiveProps(nextProps) {
    const visibleToDos = this.getVisibleItems(nextProps.items)
    this.setState({visibleToDos})
  }

  componentDidUpdate() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.dismissedItemIndex != null) {
      // @ts-expect-error TS2339 (typescriptify)
      const previousIndex = this.dismissedItemIndex - 1
      // @ts-expect-error TS2339 (typescriptify)
      this.dismissedItemIndex = null
      if (previousIndex >= 0) {
        // @ts-expect-error TS2339 (typescriptify)
        this.todoItemComponents[previousIndex].focus()
      } else {
        // @ts-expect-error TS2339 (typescriptify)
        this.titleFocus.focus()
      }
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  getVisibleItems(items) {
    // @ts-expect-error TS7006 (typescriptify)
    const incompletedFilter = item => {
      if (!item) return false
      return !item.completed
    }
    return items.filter(incompletedFilter).slice(0, 7)
  }

  // @ts-expect-error TS7006 (typescriptify)
  handleDismissClick(itemIndex, item) {
    // @ts-expect-error TS2339 (typescriptify)
    this.dismissedItemIndex = itemIndex
    // @ts-expect-error TS2339 (typescriptify)
    this.props.sidebarCompleteItem(item).catch(() => {
      // @ts-expect-error TS2339 (typescriptify)
      this.dismissedItemIndex = null
    })
  }

  renderShowAll() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.changeDashboardView && this.state.visibleToDos.length > 0) {
      return (
        <View as="div" textAlign="center">
          <Link
            isWithinText={false}
            as="button"
            // @ts-expect-error TS2339 (typescriptify)
            onClick={() => this.props.changeDashboardView('planner')}
          >
            {I18n.t('Show All')}
          </Link>
        </View>
      )
    }
    return null
  }

  renderItems() {
    // @ts-expect-error TS2339 (typescriptify)
    this.todoItemComponents = []

    // @ts-expect-error TS2339 (typescriptify)
    if (this.state.visibleToDos.length === 0) {
      return <Text size="small">{I18n.t('Nothing for now')}</Text>
    }

    return (
      <List id="planner-todosidebar-item-list" isUnstyled={true}>
        {/* @ts-expect-error TS2339,TS7006 (typescriptify) */}
        {this.state.visibleToDos.map((item, itemIndex) => (
          <List.Item key={item.uniqueId}>
            <ToDoItem
              ref={component => {
                // @ts-expect-error TS2339 (typescriptify)
                this.todoItemComponents[itemIndex] = component
              }}
              // @ts-expect-error TS2322 (typescriptify)
              item={item}
              // @ts-expect-error TS2339 (typescriptify)
              courses={this.props.courses}
              handleDismissClick={() => this.handleDismissClick(itemIndex, item)}
              // @ts-expect-error TS2339 (typescriptify)
              locale={this.props.locale}
              // @ts-expect-error TS2339 (typescriptify)
              timeZone={this.props.timeZone}
              // @ts-expect-error TS2339 (typescriptify)
              isObserving={this.props.isObserving}
            />
          </List.Item>
        ))}
      </List>
    )
  }

  renderTitle() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.additionalTitleContext) {
      return I18n.t('Student To Do')
    }
    return I18n.t('To Do')
  }

  render() {
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.loaded && !this.props.loadingError) {
      return (
        <div data-testid="ToDoSidebar">
          <h2 className="todo-list-header">{this.renderTitle()}</h2>
          <View as="div" textAlign="center">
            <Spinner renderTitle={() => I18n.t('To Do Items Loading')} size="small" />
          </View>
        </div>
      )
    }
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.loadingError) {
      return (
        <div data-testid="ToDoSidebar">
          <h2 className="todo-list-header">{this.renderTitle()}</h2>
          <Flex justifyItems="start">
            <Flex.Item>
              <IconWarningLine color="error" />
            </Flex.Item>
            <Flex.Item margin="xx-small none none xx-small">
              <Text color="danger">{I18n.t('Failure loading the To Do list')}</Text>
            </Flex.Item>
          </Flex>
        </div>
      )
    }

    return (
      <div data-testid="ToDoSidebar">
        <h2 className="todo-list-header">
          <span
            // @ts-expect-error TS2322 (typescriptify)
            tabIndex="-1"
            ref={elt => {
              // @ts-expect-error TS2339 (typescriptify)
              this.titleFocus = elt
            }}
          >
            {this.renderTitle()}
          </span>
        </h2>
        {this.renderItems()}
        {this.renderShowAll()}
      </div>
    )
  }
}

// @ts-expect-error TS7006 (typescriptify)
const mapStateToProps = state => ({
  courses: state.courses,
  items: state.sidebar.items,
  loaded: state.sidebar.loaded,
  isObserving: !!observedUserId(state),
  loadingError: state.sidebar.loadingError,
})
const mapDispatchToProps = {sidebarLoadInitialItems, sidebarCompleteItem}

export default connect(mapStateToProps, mapDispatchToProps)(ToDoSidebar)
