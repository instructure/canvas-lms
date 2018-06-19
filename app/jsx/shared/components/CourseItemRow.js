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
import I18n from 'i18n!shared_components'
import React, { Component } from 'react'
import { bool, node, string, func, shape, arrayOf, oneOf } from 'prop-types'
import cx from 'classnames'

import Heading from '@instructure/ui-core/lib/components/Heading'
import Checkbox from '@instructure/ui-core/lib/components/Checkbox'
import Container from '@instructure/ui-core/lib/components/Container'
import Avatar from '@instructure/ui-core/lib/components/Avatar'
import Badge from '@instructure/ui-core/lib/components/Badge'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-core/lib/components/Text'
import Button from '@instructure/ui-core/lib/components/Button'
import PopoverMenu from '@instructure/ui-core/lib/components/PopoverMenu'
import IconMore from 'instructure-icons/lib/Line/IconMoreLine'

import IconDragHandleLine from 'instructure-icons/lib/Line/IconDragHandleLine'
import IconPeerReviewLine from 'instructure-icons/lib/Line/IconPeerReviewLine'
import LockIconView from 'compiled/views/LockIconView'
import { author as authorShape } from '../proptypes/user'
import masterCourseDataShape from '../proptypes/masterCourseData'

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
    connectDragSource: (component) => component,
    connectDropTarget: (component) => component,
    onSelectedChanged () {},
    showManageMenu: false,
    manageMenuOptions: () => [],
    onManageMenuSelect () {},
    sectionToolTip: null,
    replyButton: null,
    focusOn: null,
    clearFocusDirectives: () => {},
    hasReadBadge: false
  }

  state = {
    isSelected: this.props.defaultSelected,
    manageMenuShown: false
  }

  componentDidMount () {
    this.onFocusManage(this.props)
  }

  componentWillReceiveProps(nextProps) {
    this.onFocusManage(nextProps)
  }

  componentWillUnmount () {
    this.unmountMasterCourseLock()
  }

  onFocusManage(props) {
    if (props.focusOn) {
      switch (props.focusOn) {
        case 'title':
          this._titleElement.focus()
          break;
        case 'manageMenu':
          this._manageMenu.focus()
          break;
        case 'toggleButton':
          break;
        default:
          throw new Error(I18n.t('Illegal element focus request'))
      }
      this.props.clearFocusDirectives()
    }
  }

  onSelectChanged = (e) => {
    this.setState({ isSelected: e.target.checked }, () => {
      this.props.onSelectedChanged({ selected: this.state.isSelected, id: this.props.id })
    })
  }

  toggleManageMenuShown = (shown, _) => {
    this.setState({ manageMenuShown: shown })
  }

  initializeMasterCourseIcon = (container) => {
    const { courseData = {}, getLockOptions } = this.props.masterCourse || {}
    if (container && (courseData.isMasterCourse || courseData.isChildCourse)) {
      this.unmountMasterCourseLock()
      const opts = getLockOptions()

      // initialize master course lock icon, which is a Backbone view
      // I know, I know, backbone in react is grosssss but wachagunnado
      this.masterCourseLock = new LockIconView({ ...opts, el: container })
      this.masterCourseLock.render()
    }
  }

  unmountMasterCourseLock () {
    if (this.masterCourseLock) {
      this.masterCourseLock.remove()
      this.masterCourseLock = null
    }
  }

  renderClickableDiv (component, refName = undefined) {
    const refFn = (c) => {
      if (refName) {
        this[refName] = c
      }
    }

    return (
      <a className="ic-item-row__content-link" ref={refFn} href={this.props.itemUrl}>
        <div className="ic-item-row__content-link-container">
          {component}
        </div>
      </a>
    )
  }

  render () {
    const classes = cx('ic-item-row')
    return (
      this.props.connectDropTarget(this.props.connectDragSource(
      <div style={{ opacity: (this.props.isDragging) ? 0 : 1 }} className={`${classes} ${this.props.className}`}>
        {(this.props.draggable && this.props.connectDragSource && <div className="ic-item-row__drag-col">
          <span>
            <Text color="secondary" size="large">
              <IconDragHandleLine />
            </Text>
          </span>
        </div>)}
        {
          !this.props.isRead ? (
            <Container display="block" margin="0 medium 0 0">
              <Badge margin="0 0 0 0" standalone type="notification" />
            </Container>
          ) : this.props.hasReadBadge ? (
            <Container display="block" margin="0 small 0 0">
              <Container display="block" margin="0 medium 0 0" />
            </Container>
          ) : null
        }
        {this.props.icon}
        {(this.props.selectable && <div className="ic-item-row__select-col">
          <Checkbox
            defaultChecked={this.props.defaultSelected}
            onChange={this.onSelectChanged}
            label={<ScreenReaderContent>{this.props.title}</ScreenReaderContent>}
          />
        </div>)}
        {(this.props.showAvatar && <div className="ic-item-row__author-col">
          <Avatar
            size="small"
            name={this.props.author.display_name || I18n.t('Unknown')}
            src={this.props.author.avatar_image_url}
          />
        </div>)}
        <div className="ic-item-row__content-col">
          {!this.props.isRead && <ScreenReaderContent>{I18n.t('Unread')}</ScreenReaderContent>}
          {this.renderClickableDiv(<Heading level="h3">{this.props.title}</Heading>, "_titleElement")}
          {this.props.sectionToolTip}
          {this.props.body ? this.renderClickableDiv(this.props.body) : null}
          {this.props.replyButton ? this.renderClickableDiv(this.props.replyButton) : null}
        </div>
        <div className="ic-item-row__meta-col">
          <div className="ic-item-row__meta-actions">
            { this.props.peerReview ? (
              <span className="ic-item-row__peer_review">
                <Text color="success" size="medium">
                  <IconPeerReviewLine />
                </Text>
              </span>
              ) : null
            }
            {this.props.actionsContent}
            <span ref={this.initializeMasterCourseIcon} className="ic-item-row__master-course-lock" />
            {this.props.showManageMenu &&
              (<span className="ic-item-row__manage-menu">
                <PopoverMenu
                  ref={(c) => { this._manageMenu = c }}
                  onSelect={this.props.onManageMenuSelect}
                  onToggle={this.toggleManageMenuShown}
                  trigger={
                    <Button variant="icon" size="small">
                      <IconMore />
                      <ScreenReaderContent>{I18n.t('Manage options for %{name}', { name: this.props.title })}</ScreenReaderContent>
                    </Button>
                  }>{this.state.manageMenuShown ? this.props.manageMenuOptions() : null}</PopoverMenu>
              </span>)}
          </div>
          <div className="ic-item-row__meta-content">
            {this.props.metaContent}
          </div>
        </div>
      </div>, {dropEffect: 'copy'}))
    )
  }
}
