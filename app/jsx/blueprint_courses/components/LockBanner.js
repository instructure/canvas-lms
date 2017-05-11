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

import I18n from 'i18n!blueprint_courses'
import React, { PropTypes, Component } from 'react'
import Alert from 'instructure-ui/lib/components/Alert'
import Typography from 'instructure-ui/lib/components/Typography'
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'

const lockLabels = {
  content: I18n.t('Content'),
  points: I18n.t('Points'),
  settings: I18n.t('Settings'),
  due_dates: I18n.t('Due Dates'),
  availability_dates: I18n.t('Availability Dates'),
}

export default class LockBanner extends Component {
  static propTypes = {
    isLocked: PropTypes.bool.isRequired,
    itemLocks: PropTypes.shape({
      content: PropTypes.bool.isRequired,
      points: PropTypes.bool.isRequired,
      due_dates: PropTypes.bool.isRequired,
      availability_dates: PropTypes.bool.isRequired,
    }).isRequired,
  }

  static setupRootNode () {
    const bannerNode = document.createElement('div')
    bannerNode.id = 'blueprint-lock-banner'
    bannerNode.setAttribute('style', 'margin-bottom: 2em')
    const contentNode = document.querySelector('#content')
    return contentNode.insertBefore(bannerNode, contentNode.firstChild)
  }

  componentDidUpdate (prevProps) {
    if (this.props.isLocked && !prevProps.isLocked) {
      $.screenReaderFlashMessage(I18n.t('%{attributes} locked', { attributes: this.composeLockedList() }))
    }
  }

  composeLockedList () {
    const itemLocks = this.props.itemLocks
    const items = Object.keys(itemLocks)
      .filter(item => itemLocks[item])
      .map(item => lockLabels[item])

    if (items.length > 1) {
      return `${items.slice(0, -1).join(', ')} & ${items.slice(-1)[0]}`
    }

    return items[0]
  }

  render () {
    if (this.props.isLocked) {
      return (
        <Alert>
          <Typography weight="bold" size="small">{I18n.t('Locked:')}&nbsp;</Typography>
          <Typography size="small">{this.composeLockedList()}</Typography>
        </Alert>
      )
    }

    return null
  }
}
