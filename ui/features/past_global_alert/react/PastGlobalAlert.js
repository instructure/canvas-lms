/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('past_global_announcements')

export default class PastGlobalAlert extends React.Component {
  state = {
    shouldRender: false,
  }

  componentDidMount() {
    document.addEventListener('globalAlertShouldRender', this.handleAlertRender)
  }

  handleAlertRender = () => {
    this.setState({shouldRender: true})
  }

  componentWillUnmount() {
    document.removeEventListener('globalAlertShouldRender', this.handleAlertRender)
  }

  render() {
    if (this.state.shouldRender) {
      return (
        <Alert renderCloseButtonLabel={I18n.t('Close')}>
          <div data-testid="globalAnnouncementsAlert">
            {I18n.t(`You can view dismissed announcements by going to Account and selecting Global
            Announcements from the menu.`)}
          </div>
          <Button
            data-testid="globalAnnouncementsButton"
            href="/account_notifications"
            color="primary"
            margin="small 0 0 0"
          >
            {I18n.t('View')}
          </Button>
        </Alert>
      )
    }
    return null
  }
}
