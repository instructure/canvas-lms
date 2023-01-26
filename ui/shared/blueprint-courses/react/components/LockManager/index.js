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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import '@canvas/jquery/jquery.instructure_misc_plugins'

import get from 'lodash/get'
import buildProps from './buildLockProps'
import ApiClient from '../../apiClient'
import LockBanner from './LockBanner'
import LockToggle from './LockToggle'

const I18n = useI18nScope('blueprint_coursesLockManageer')

export default class LockManager {
  constructor() {
    this.state = {
      isLocked: false,
      itemLocks: [],
      isMasterContent: false,
      isChildContent: false,
      itemId: '',
    }
  }

  init(options) {
    if (!this.shouldInit()) return
    this.props = buildProps(options)
    this.setupState()
    if (this.state.itemId !== undefined) {
      // will be undefined if creating a new assignment, discussion, etc.
      this.render()
    }
  }

  shouldInit() {
    return (
      ENV.MASTER_COURSE_DATA &&
      (ENV.MASTER_COURSE_DATA.is_master_course_master_content ||
        ENV.MASTER_COURSE_DATA.is_master_course_child_content)
    )
  }

  setupState() {
    this.state = {
      isLocked: ENV.MASTER_COURSE_DATA.restricted_by_master_course,
      itemLocks:
        ENV.MASTER_COURSE_DATA.master_course_restrictions ||
        ENV.MASTER_COURSE_DATA.default_restrictions,
      isMasterContent: ENV.MASTER_COURSE_DATA.is_master_course_master_content,
      isChildContent: ENV.MASTER_COURSE_DATA.is_master_course_child_content,
      courseId: ENV.COURSE_ID,
      itemId: get(ENV, this.props.itemIdPath),
    }
  }

  changeItemId(itemId) {
    this.state.itemId = itemId
  }

  setState(newState) {
    this.state = Object.assign(this.state, newState)
    this.render()
  }

  getItemLocks() {
    return {...this.state.itemLocks}
  }

  isMasterContent() {
    return this.state.isMasterContent
  }

  isChildContent() {
    return this.state.isChildContent
  }

  toggleLocked = () => {
    const {itemType} = this.props
    const {courseId, isLocked, itemId} = this.state
    ApiClient.toggleLocked({courseId, itemType, itemId, isLocked: !isLocked})
      .then(res => {
        if (res.data.success) {
          if (this.props.lockCallback) this.props.lockCallback(!isLocked)
          this.setState({
            isLocked: !isLocked,
          })
        } else {
          this.showToggleError()
        }
      })
      .catch(() => {
        this.showToggleError()
      })
  }

  showToggleError() {
    $.flashError(I18n.t('There was a problem toggling the content lock.'))
  }

  setupToggle(cb) {
    if (!this.props.toggleWrapperSelector) return
    if (this.toggleNode && !this.toggleNode.parentElement) this.toggleNode = false
    if (!this.toggleNode) {
      LockToggle.setupRootNode(
        this.props.toggleWrapperSelector,
        this.props.toggleWrapperChildIndex || 0,
        node => {
          this.toggleNode = node
          cb()
        }
      )
    } else {
      cb()
    }
  }

  renderLockToggle() {
    if (!this.props.toggleWrapperSelector) return
    this.setupToggle(() => {
      ReactDOM.render(
        <LockToggle
          isLocked={this.state.isLocked}
          isToggleable={this.props.page === 'show' && this.state.isMasterContent}
          onClick={this.toggleLocked}
        />,
        this.toggleNode
      )
    })
  }

  renderBanner() {
    if (!this.bannerNode) this.bannerNode = LockBanner.setupRootNode(this.props?.bannerSelector)
    ReactDOM.render(
      <LockBanner isLocked={this.state.isLocked} itemLocks={this.state.itemLocks} />,
      this.bannerNode
    )
  }

  render() {
    this.renderBanner()
    this.renderLockToggle()
  }
}
