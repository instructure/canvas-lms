import I18n from 'i18n!blueprint_courses'
import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import 'jquery.instructure_misc_plugins'

import dig from '../shared/dig'
import buildProps from './buildProps'
import ApiClient from './apiClient'
import LockBanner from './lockBanner'
import LockToggle from './lockToggle'

export default class LockManager {
  init (options) {
    if (!this.shouldInit()) return;
    this.props = buildProps(options)
    this.setupState()
    if (this.state.itemId !== undefined) {
      this.render()
    } else {
      $.flashError(I18n.t('Oops, there was a problem loading content locks.'))
    }
  }

  shouldInit () {
    return ENV.MASTER_COURSE_DATA &&
           (ENV.MASTER_COURSE_DATA.is_master_course_master_content ||
           ENV.MASTER_COURSE_DATA.is_master_course_child_content)
  }

  setupState () {
    this.state = {
      isLocked: ENV.MASTER_COURSE_DATA.restricted_by_master_course,
      itemLocks: ENV.MASTER_COURSE_DATA.master_course_restrictions || ENV.MASTER_COURSE_DATA.default_restrictions,
      isMasterContent: ENV.MASTER_COURSE_DATA.is_master_course_master_content,
      isChildContent: ENV.MASTER_COURSE_DATA.is_master_course_child_content,
      courseId: ENV.COURSE_ID,
      itemId: dig(ENV, this.props.itemIdPath),
    }
  }

  setState (newState) {
    this.state = Object.assign(this.state, newState)
    this.render()
  }

  getItemLocks () {
    return { ...this.state.itemLocks }
  }

  toggleLocked = () => {
    const { itemType } = this.props
    const { courseId, isLocked, itemId } = this.state
    ApiClient.toggleLocked({ courseId, itemType, itemId, isLocked: !isLocked })
      .then((res) => {
        if (res.data.success) {
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

  showToggleError () {
    $.flashError(I18n.t('There was a problem toggling the content lock.'))
  }

  setupToggle (cb) {
    if (!this.props.toggleWrapperSelector) return;
    if (!this.toggleNode) {
      LockToggle.setupRootNode(this.props.toggleWrapperSelector, this.props.toggleWrapperChildIndex || 0, (node) => {
        this.toggleNode = node
        cb()
      })
    } else {
      cb()
    }
  }

  renderLockToggle () {
    if (!this.props.toggleWrapperSelector) return;
    this.setupToggle(() => {
      ReactDOM.render(
        <LockToggle
          isLocked={this.state.isLocked}
          isToggleable={this.props.page === 'show' && this.state.isMasterContent}
          onClick={this.toggleLocked}
        />, this.toggleNode)
    })
  }

  renderBanner () {
    if (!this.bannerNode) this.bannerNode = LockBanner.setupRootNode()
    ReactDOM.render(
      <LockBanner
        isLocked={this.state.isLocked}
        itemLocks={this.state.itemLocks}
      />, this.bannerNode)
  }

  render () {
    this.renderBanner()
    this.renderLockToggle()
  }
}
