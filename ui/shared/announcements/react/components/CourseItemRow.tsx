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
import {useScope as createI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {bool, node, string, func, shape, oneOf} from 'prop-types'
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

const I18n = createI18nScope('shared_components')

export default class CourseItemRow extends Component {
  static propTypes = {
    actionsContent: node,
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
    // @ts-expect-error TS7006 (typescriptify)
    connectDragSource: component => component,
    // @ts-expect-error TS7006 (typescriptify)
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
    // @ts-expect-error TS2339 (typescriptify)
    isSelected: this.props.defaultSelected,
    manageMenuShown: false,
  }

  componentDidMount() {
    this.onFocusManage(this.props)
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillReceiveProps(nextProps) {
    this.onFocusManage(nextProps)
  }

  componentWillUnmount() {
    this.unmountMasterCourseLock()
  }

  // @ts-expect-error TS7006 (typescriptify)
  onFocusManage(props) {
    if (props.focusOn) {
      switch (props.focusOn) {
        case 'title':
          // @ts-expect-error TS2339 (typescriptify)
          this._titleElement.focus()
          break
        case 'manageMenu':
          // @ts-expect-error TS2339 (typescriptify)
          this._manageMenu.focus()
          break
        case 'toggleButton':
          break
        default:
          throw new Error('Illegal element focus request')
      }
      // @ts-expect-error TS2339 (typescriptify)
      this.props.clearFocusDirectives()
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  onSelectChanged = e => {
    this.setState({isSelected: e.target.checked}, () => {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.onSelectedChanged({selected: this.state.isSelected, id: this.props.id})
    })
  }

  // @ts-expect-error TS7006 (typescriptify)
  toggleManageMenuShown = (shown, _) => {
    this.setState({manageMenuShown: shown})
  }

  // @ts-expect-error TS7006 (typescriptify)
  initializeMasterCourseIcon = container => {
    // @ts-expect-error TS2339 (typescriptify)
    const {courseData = {}, getLockOptions} = this.props.masterCourse || {}
    if (container && (courseData.isMasterCourse || courseData.isChildCourse)) {
      this.unmountMasterCourseLock()
      const opts = getLockOptions()

      // initialize master course lock icon, which is a Backbone view
      // I know, I know, backbone in react is grosssss but wachagunnado
      // @ts-expect-error TS2339 (typescriptify)
      this.masterCourseLock = new LockIconView({...opts, el: container})
      // @ts-expect-error TS2339 (typescriptify)
      this.masterCourseLock.render()
    }
  }

  unmountMasterCourseLock() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.masterCourseLock) {
      // @ts-expect-error TS2339 (typescriptify)
      this.masterCourseLock.remove()
      // @ts-expect-error TS2339 (typescriptify)
      this.masterCourseLock = null
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  renderClickableDiv(component, refName = undefined) {
    // @ts-expect-error TS7006 (typescriptify)
    const refFn = c => {
      if (refName) {
        // @ts-expect-error TS2322 (typescriptify)
        this[refName] = c
      }
    }

    return (
      // @ts-expect-error TS2339 (typescriptify)
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

  // @ts-expect-error TS7006 (typescriptify)
  renderDiv(component) {
    return <div className="ic-item-row__content-container">{component}</div>
  }

  render() {
    const classes = cx('ic-item-row')
    // @ts-expect-error TS2339 (typescriptify)
    return this.props.connectDropTarget(
      // @ts-expect-error TS2339 (typescriptify)
      this.props.connectDragSource(
        <div
          // @ts-expect-error TS2339 (typescriptify)
          style={{opacity: this.props.isDragging ? 0 : 1}}
          // @ts-expect-error TS2339 (typescriptify)
          className={`${classes} ${this.props.className}`}
        >
          {/* @ts-expect-error TS2339 (typescriptify) */}
          {this.props.draggable && this.props.connectDragSource && (
            <div className="ic-item-row__drag-col">
              <span>
                <Text color="secondary" size="large">
                  <IconDragHandleLine />
                </Text>
              </span>
            </div>
          )}
          {/* @ts-expect-error TS2339 (typescriptify) */}
          {!this.props.isRead ? (
            <View display="block" margin="0 medium 0 0">
              <Badge margin="0 0 0 0" standalone={true} type="notification" />
            </View>
            // @ts-expect-error TS2339 (typescriptify)
          ) : this.props.hasReadBadge ? (
            <View display="block" margin="0 small 0 0">
              <View display="block" margin="0 medium 0 0" />
            </View>
          ) : null}
          {/* @ts-expect-error TS2339 (typescriptify) */}
          {this.props.icon}
          {/* @ts-expect-error TS2339 (typescriptify) */}
          {this.props.selectable && (
            <div className="ic-item-row__select-col">
              <Checkbox
                data-testid="select-announcement-checkbox"
                // @ts-expect-error TS2339 (typescriptify)
                defaultChecked={this.props.defaultSelected}
                onChange={this.onSelectChanged}
                // @ts-expect-error TS2339 (typescriptify)
                label={<ScreenReaderContent>{this.props.title}</ScreenReaderContent>}
              />
            </div>
          )}
          {/* @ts-expect-error TS2339 (typescriptify) */}
          {this.props.showAvatar && (
            <div className="ic-item-row__author-col">
              <Avatar
                size="small"
                // @ts-expect-error TS2339 (typescriptify)
                alt={this.props.author?.display_name || I18n.t('Unknown')}
                // @ts-expect-error TS2339 (typescriptify)
                name={this.props.author?.display_name || I18n.t('Unknown')}
                // @ts-expect-error TS2339 (typescriptify)
                src={this.props.author?.avatar_image_url}
                data-fs-exclude={true}
              />
            </div>
          )}
          <div className="ic-item-row__content-col">
            {this.renderClickableDiv(
              <Heading level="h3">
                {/* @ts-expect-error TS2339 (typescriptify) */}
                {!this.props.isRead && (
                  <ScreenReaderContent>{I18n.t('unread,')}</ScreenReaderContent>
                )}
                {/* @ts-expect-error TS2339 (typescriptify) */}
                {this.props.title}
              </Heading>,
              // @ts-expect-error TS2345 (typescriptify)
              '_titleElement',
            )}
            {/* @ts-expect-error TS2339 (typescriptify) */}
            {this.props.sectionToolTip}
            {/* @ts-expect-error TS2339 (typescriptify) */}
            {this.props.body ? this.renderDiv(this.props.body) : null}
            {/* @ts-expect-error TS2339 (typescriptify) */}
            {this.props.replyButton ? this.renderClickableDiv(this.props.replyButton) : null}
          </div>
          <div className="ic-item-row__meta-col">
            <div className="ic-item-row__meta-actions">
              {/* @ts-expect-error TS2339 (typescriptify) */}
              {this.props.peerReview ? (
                <span className="ic-item-row__peer_review">
                  <Text color="success" size="medium">
                    <IconPeerReviewLine />
                  </Text>
                </span>
              ) : null}
              {/* @ts-expect-error TS2339 (typescriptify) */}
              {this.props.actionsContent}
              <span
                ref={this.initializeMasterCourseIcon}
                className="ic-item-row__master-course-lock lock-icon"
              />
              {/* @ts-expect-error TS2339 (typescriptify) */}
              {this.props.showManageMenu && (
                <span className="ic-item-row__manage-menu">
                  <Menu
                    // @ts-expect-error TS2339 (typescriptify)
                    ref={c => (this._manageMenu = c)}
                    // @ts-expect-error TS2339 (typescriptify)
                    onSelect={this.props.onManageMenuSelect}
                    onToggle={this.toggleManageMenuShown}
                    trigger={
                      <IconButton
                        withBorder={false}
                        withBackground={false}
                        size="small"
                        screenReaderLabel={I18n.t('Manage options for %{name}', {
                          // @ts-expect-error TS2339 (typescriptify)
                          name: this.props.title,
                        })}
                        data-testid="manage-announcement-options"
                      >
                        <IconMoreLine />
                      </IconButton>
                    }
                  >
                    {/* @ts-expect-error TS2339 (typescriptify) */}
                    {this.state.manageMenuShown ? this.props.manageMenuOptions() : null}
                  </Menu>
                </span>
              )}
            </div>
            {/* @ts-expect-error TS2339 (typescriptify) */}
            <div className="ic-item-row__meta-content">{this.props.metaContent}</div>
          </div>
        </div>,
        {dropEffect: 'copy'},
      ),
    )
  }
}
