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

// TODO: Get rid of this component.  AnnouncementRow should manage its own layout
// with the shared utilities created in g/something.
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {bool, node, string, func, shape, arrayOf, oneOf} from 'prop-types'
import cx from 'classnames'

import {Text} from '@instructure/ui-text'
import {Badge} from '@instructure/ui-badge'
import {Avatar} from '@instructure/ui-avatar'
import {Heading} from '@instructure/ui-heading'
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {IconMoreLine, IconDragHandleLine, IconPeerReviewLine} from '@instructure/ui-icons'
import LockIconView from '@canvas/lock-icon'
import {author as authorShape} from '@canvas/users/react/proptypes/user'
import masterCourseDataShape from '@canvas/courses/react/proptypes/masterCourseData'

const I18n = useI18nScope('shared_components')

export default class CourseItemRow extends Component {
  static propTypes = {
    actionsContent: arrayOf(node),
    metaContent: node,
    masterCourse: shape({
      courseData: masterCourseDataShape,
      getLockOptions: func.isRequired,
    }),
    author: authorShape,
    title: string.isRequired,
    body: node,
    isDragging: bool,
    connectDragSource: func,
    connectDropTarget: func,
    id: string,
    className: string,
    itemUrl: string,
    selectable: bool,
    draggable: bool,
    defaultSelected: bool,
    isRead: bool,
    showAvatar: bool,
    onSelectedChanged: func,
    peerReview: bool,
    icon: node,
    showManageMenu: bool,
    manageMenuOptions: func,
    onManageMenuSelect: func,
    sectionToolTip: node,
    replyButton: node,
    focusOn: oneOf(['title', 'manageMenu', 'toggleButton']),
    clearFocusDirectives: func, // Required if focusOn is provided
    hasReadBadge: bool,
  }

  static defaultProps = {
    actionsContent: null,
    body: null,
    metaContent: null,
    masterCourse: null,
    author: {
      id: null,
      display_name: '',
      html_url: '',
      avatar_image_url: null,
    },
    id: null,
    className: '',
    isDragging: false,
    itemUrl: null,
    selectable: false,
    draggable: false,
    peerReview: false,
    defaultSelected: false,
    isRead: true,
    icon: null,
    showAvatar: false,
    connectDragSource: component => component,
    connectDropTarget: component => component,
    onSelectedChanged() {},
    showManageMenu: false,
    manageMenuOptions: () => [],
    onManageMenuSelect() {},
    sectionToolTip: null,
    replyButton: null,
    focusOn: null,
    clearFocusDirectives: () => {},
    hasReadBadge: false,
  }

  state = {
    isSelected: this.props.defaultSelected,
    manageMenuShown: false,
  }

  componentDidMount() {
    this.onFocusManage(this.props)
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    this.onFocusManage(nextProps)
  }

  componentWillUnmount() {
    this.unmountMasterCourseLock()
  }

  onFocusManage(props) {
    if (props.focusOn) {
      switch (props.focusOn) {
        case 'title':
          this._titleElement.focus()
          break
        case 'manageMenu':
          this._manageMenu.focus()
          break
        case 'toggleButton':
          break
        default:
          throw new Error('Illegal element focus request')
      }
      this.props.clearFocusDirectives()
    }
  }

  onSelectChanged = e => {
    this.setState({isSelected: e.target.checked}, () => {
      this.props.onSelectedChanged({selected: this.state.isSelected, id: this.props.id})
    })
  }

  toggleManageMenuShown = (shown, _) => {
    this.setState({manageMenuShown: shown})
  }

  initializeMasterCourseIcon = container => {
    const {courseData = {}, getLockOptions} = this.props.masterCourse || {}
    if (container && (courseData.isMasterCourse || courseData.isChildCourse)) {
      this.unmountMasterCourseLock()
      const opts = getLockOptions()

      // initialize master course lock icon, which is a Backbone view
      // I know, I know, backbone in react is grosssss but wachagunnado
      this.masterCourseLock = new LockIconView({...opts, el: container})
      this.masterCourseLock.render()
    }
  }

  unmountMasterCourseLock() {
    if (this.masterCourseLock) {
      this.masterCourseLock.remove()
      this.masterCourseLock = null
    }
  }

  renderClickableDiv(component, refName = undefined) {
    const refFn = c => {
      if (refName) {
        this[refName] = c
      }
    }

    return (
      <a className="ic-item-row__content-link" ref={refFn} href={this.props.itemUrl}>
        <div
          className="ic-item-row__content-link-container"
          data-testid="single-announcement-test-id"
        >
          {component}
        </div>
      </a>
    )
  }

  renderDiv(component) {
    return <div className="ic-item-row__content-container">{component}</div>
  }

  render() {
    const classes = cx('ic-item-row')
    return this.props.connectDropTarget(
      this.props.connectDragSource(
        <div
          style={{opacity: this.props.isDragging ? 0 : 1}}
          className={`${classes} ${this.props.className}`}
        >
          {this.props.draggable && this.props.connectDragSource && (
            <div className="ic-item-row__drag-col">
              <span>
                <Text color="secondary" size="large">
                  <IconDragHandleLine />
                </Text>
              </span>
            </div>
          )}
          {!this.props.isRead ? (
            <View display="block" margin="0 medium 0 0">
              <Badge margin="0 0 0 0" standalone={true} type="notification" />
            </View>
          ) : this.props.hasReadBadge ? (
            <View display="block" margin="0 small 0 0">
              <View display="block" margin="0 medium 0 0" />
            </View>
          ) : null}
          {this.props.icon}
          {this.props.selectable && (
            <div className="ic-item-row__select-col">
              <Checkbox
                defaultChecked={this.props.defaultSelected}
                onChange={this.onSelectChanged}
                label={<ScreenReaderContent>{this.props.title}</ScreenReaderContent>}
              />
            </div>
          )}
          {this.props.showAvatar && (
            <div className="ic-item-row__author-col">
              <Avatar
                size="small"
                alt={this.props.author?.display_name || I18n.t('Unknown')}
                name={this.props.author?.display_name || I18n.t('Unknown')}
                src={this.props.author?.avatar_image_url}
                data-fs-exclude={true}
              />
            </div>
          )}
          <div className="ic-item-row__content-col">
            {this.renderClickableDiv(
              <Heading level="h3">
                {!this.props.isRead && (
                  <ScreenReaderContent>{I18n.t('unread,')}</ScreenReaderContent>
                )}
                {this.props.title}
              </Heading>,
              '_titleElement'
            )}
            {this.props.sectionToolTip}
            {this.props.body ? this.renderDiv(this.props.body) : null}
            {this.props.replyButton ? this.renderClickableDiv(this.props.replyButton) : null}
          </div>
          <div className="ic-item-row__meta-col">
            <div className="ic-item-row__meta-actions">
              {this.props.peerReview ? (
                <span className="ic-item-row__peer_review">
                  <Text color="success" size="medium">
                    <IconPeerReviewLine />
                  </Text>
                </span>
              ) : null}
              {this.props.actionsContent}
              <span
                ref={this.initializeMasterCourseIcon}
                className="ic-item-row__master-course-lock lock-icon"
              />
              {this.props.showManageMenu && (
                <span className="ic-item-row__manage-menu">
                  <Menu
                    ref={c => (this._manageMenu = c)}
                    onSelect={this.props.onManageMenuSelect}
                    onToggle={this.toggleManageMenuShown}
                    trigger={
                      <IconButton
                        withBorder={false}
                        withBackground={false}
                        size="small"
                        screenReaderLabel={I18n.t('Manage options for %{name}', {
                          name: this.props.title,
                        })}
                      >
                        <IconMoreLine />
                      </IconButton>
                    }
                  >
                    {this.state.manageMenuShown ? this.props.manageMenuOptions() : null}
                  </Menu>
                </span>
              )}
            </div>
            <div className="ic-item-row__meta-content">{this.props.metaContent}</div>
          </div>
        </div>,
        {dropEffect: 'copy'}
      )
    )
  }
}
