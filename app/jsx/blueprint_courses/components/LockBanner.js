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
import React, { Component } from 'react'
import PropTypes from 'prop-types'
import Alert from '@instructure/ui-core/lib/components/Alert'
import Text from '@instructure/ui-core/lib/components/Text'
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'
import {formatLockObject} from '../LockItemFormat'
import propTypes from '../propTypes'

export default class LockBanner extends Component {
  static propTypes = {
    isLocked: PropTypes.bool.isRequired,
    itemLocks: propTypes.itemLocks,
  }

  static defaultProps = {
    itemLocks: {
      content: false,
      points: false,
      settings: false,
      due_dates: false,
      availability_dates: false,
    }
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
      $.screenReaderFlashMessage(I18n.t('%{attributes} locked', { attributes: formatLockObject(this.props.itemLocks) }))
    }
  }

  render () {
    if (this.props.isLocked) {
      return (
        <Alert>
          <Text weight="bold" size="small">{I18n.t('Locked:')}&nbsp;</Text>
          <Text size="small">{formatLockObject(this.props.itemLocks)}</Text>
        </Alert>
      )
    }

    return null
  }
}
