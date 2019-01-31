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
import ReactDOM from 'react-dom'
import Alert from '@instructure/ui-alerts/lib/components/Alert'
import Link from '@instructure/ui-elements/lib/components/Link'
import Text from '@instructure/ui-elements/lib/components/Text'

const container = document.getElementById('content_notice_container')
if (container && ENV.CONTENT_NOTICES.length > 0) {
  const alerts = ENV.CONTENT_NOTICES.map(notice => {
    let link = null
    if (notice.link_text && notice.link_target) {
      link = <Link href={notice.link_target}>{notice.link_text}</Link>
    }
    return <Alert key={notice.tag} variant={notice.variant} liveRegion={() => document.getElementById('flash_screenreader_holder')}>
        <Text>{notice.text}</Text>&emsp;{link}
      </Alert>
  })
  ReactDOM.render(alerts, container)
}
