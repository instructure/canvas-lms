/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import axios from 'axios'
import classnames from 'classnames'
import I18n from 'i18n!lock_btn_module'
import FilesystemObject from 'compiled/models/FilesystemObject'
import { showFlashError } from './FlashAlert'

class MasterCourseLock extends React.Component {
  static propTypes = {
    model: PropTypes.instanceOf(FilesystemObject).isRequired,
    canManage: PropTypes.bool.isRequired
  }

  constructor (props) {
    super(props)
    this.state = this.extractStateFromModel(props.model)
  }

  componentWillMount () {
    const setState = model => this.setState(this.extractStateFromModel(model))
    this.props.model.on('change', setState, this)
  }

  componentWillUnmount () {
    this.props.model.off(null, null, this)
  }

  /* == Custom Functions == */
  setLocked (locked) {
    if (this.props.model) {
      this.props.model.set('restricted_by_master_course', locked)
    }
  }

  isLocked () {
    return !!(this.props.model && this.props.model.get('restricted_by_master_course'))
  }

  canLockUnlock () {
    return this.props.canManage && this.props.model.get('is_master_course_master_content')
  }

  // Function Summary
  // extractStateFromModel expects a backbone model wtih the follow attributes
  // * hidden, lock_at, unlock_at
  //
  // It takes those attributes and returns an object that can be used to set the
  // components internal state
  //
  // returns object
  extractStateFromModel (model) {
    return {
      locked: !!model.get('restricted_by_master_course')
    }
  }

  // Function Summary
  // allow locking/unlocking in this component.
  toggleLockedState = () => {
    const fileName = (this.props.model && this.props.model.displayName()) || I18n.t('this file');
    axios.put(
      `/api/v1/courses/${ENV.COURSE_ID}/blueprint_templates/default/restrict_item`,
      {
        content_type: 'attachment',
        content_id: this.props.model.id,
        restricted: !this.isLocked()
      }).then((/* response */) => {
        this.setLocked(!this.isLocked())
      }).catch(
        showFlashError(I18n.t('An error occurred changing the lock state for "%{fileName}"', {fileName}))
      )
  }

  // modeled after PUblishCloud to implement the adjacent lock icon|button
  render () {
    const locked = this.isLocked()
    const fileName = (this.props.model && this.props.model.displayName()) || I18n.t('This file');
    const wrapperClass = classnames('lock-icon', {disabled: !this.canLockUnlock(), 'lock-icon-locked': this.isLocked()})
    const buttonClass = `btn-link ${locked ? 'locked-status locked' : 'unlocked-status unlocked'}`
    const iconClass = locked ? 'icon-blueprint-lock' : 'icon-blueprint'
    const title = locked ? I18n.t('Locked') : I18n.t('Unlocked')
    const label = locked
      ? I18n.t('%{fileName}  is Locked - Click to modify', {fileName})
      : I18n.t('%{fileName}  is Unlocked - Click to modify', {fileName})
    return (
      <span className={wrapperClass}>
        {
          this.canLockUnlock() ?
            <button
              type="button"
              data-tooltip="left"
              onClick={this.toggleLockedState}
              className={buttonClass}
              title={title}
              aria-label={label}
            >
              <i className={iconClass} />
            </button> :
            <i className={iconClass} data-tooltip="left" title={title}>
              <span className="lock-text screenreader-only">{title}</span>
            </i>
        }
      </span>
    )
  }
}

export default MasterCourseLock
