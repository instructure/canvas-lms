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

import I18n from 'i18n!shared_components'
import React, {Component} from 'react'
import {bool, node, string, func, shape} from 'prop-types'
import cx from 'classnames'

import Checkbox from '@instructure/ui-core/lib/components/Checkbox'
import Avatar from '@instructure/ui-core/lib/components/Avatar'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'

import LockIconView from 'compiled/views/LockIconView'
import {author as authorShape} from '../proptypes/user'
import masterCourseDataShape from '../proptypes/masterCourseData'

export default class CourseItemRow extends Component {
  static propTypes = {
    children: node.isRequired,
    actionsContent: node,
    metaContent: node,
    masterCourse: shape({
      courseData: masterCourseDataShape,
      getLockOptions: func.isRequired
    }),
    author: authorShape,
    title: string.isRequired,
    id: string,
    className: string,
    itemUrl: string,
    selectable: bool,
    defaultSelected: bool,
    isRead: bool,
    showAvatar: bool,
    onSelectedChanged: func
  }

  static defaultProps = {
    actionsContent: null,
    metaContent: null,
    masterCourse: null,
    author: {
      id: '4',
      display_name: '',
      html_url: '',
      avatar_image_url: null
    },
    id: null,
    className: '',
    itemUrl: null,
    selectable: false,
    defaultSelected: false,
    isRead: true,
    showAvatar: false,
    onSelectedChanged() {}
  }

  state = {
    isSelected: this.props.defaultSelected
  }

  componentWillUnmount() {
    this.unmountMasterCourseLock()
  }

  onSelectChanged = e => {
    this.setState({isSelected: e.target.checked}, () => {
      this.props.onSelectedChanged({selected: this.state.isSelected, id: this.props.id})
    })
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

  renderChildren() {
    if (this.props.itemUrl) {
      return (
        <a className="ic-item-row__content-link" href={this.props.itemUrl}>
          {this.props.children}
        </a>
      )
    } else {
      return this.props.children
    }
  }

  render() {
    const classes = cx('ic-item-row', {
      'ic-item-row__unread': !this.props.isRead
    })

    return (
      <div className={`${classes} ${this.props.className}`}>
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
              name={this.props.author.display_name || I18n.t('Unknown')}
              src={this.props.author.avatar_image_url}
            />
          </div>
        )}
        <div className="ic-item-row__content-col">
          {!this.props.isRead && <ScreenReaderContent>{I18n.t('Unread')}</ScreenReaderContent>}
          {this.renderChildren()}
        </div>
        <div className="ic-item-row__meta-col">
          <div className="ic-item-row__meta-actions">
            {this.props.actionsContent}
            <span
              ref={this.initializeMasterCourseIcon}
              className="ic-item-row__master-course-lock"
            />
          </div>
          <div className="ic-item-row__meta-content">{this.props.metaContent}</div>
        </div>
      </div>
    )
  }
}
