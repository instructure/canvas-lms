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

import I18n from 'i18n!progress_pill'
import React from 'react'
import ReactDOM from 'react-dom'
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip'
import IconUpload from '@instructure/ui-icons/lib/Line/IconUpload'
import IconWarning from '@instructure/ui-icons/lib/Line/IconWarning'

const presenter = document.querySelectorAll(".assignment_presenter_for_submission")
const progressIcon = (presenterObject) => {
  switch (presenterObject.innerText) {
    case 'pending_upload':
      return [<IconUpload />, I18n.t("Uploading Submission")]
    case 'errored':
      return [<IconWarning />, I18n.t("Submission Failed to Submit")]
    default:
      return null
  }
}

const progressElements = document.querySelectorAll(".react_pill_container")
for (let i = 0; i < progressElements.length; i++) {
  const icon = progressIcon(presenter[i])
  if (icon !== null) {
    ReactDOM.render((
      <Tooltip tip={ icon[1] }>
        { icon[0] }
      </Tooltip>
    ), progressElements[i])
  }
}
