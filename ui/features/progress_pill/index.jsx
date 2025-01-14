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

import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {createRoot} from 'react-dom/client'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconUploadLine, IconWarningLine} from '@instructure/ui-icons'
import ready from '@instructure/ready'

const I18n = createI18nScope('progress_pill')

ready(() => {
  const presenter = document.querySelectorAll('.assignment_presenter_for_submission')
  const progressIcon = presenterObject => {
    switch (presenterObject.innerText) {
      case 'pending':
        return [<IconUploadLine />, I18n.t('Uploading Submission')]
      case 'failed':
        return [<IconWarningLine />, I18n.t('Submission Failed to Submit')]
      default:
        return null
    }
  }

  const progressElements = document.querySelectorAll('.react_pill_container')
  const roots = []
  for (let i = 0; i < progressElements.length; i++) {
    const icon = progressIcon(presenter[i])
    if (icon !== null) {
      const root = createRoot(progressElements[i])
      root.render(<Tooltip renderTip={icon[1]}>{icon[0]}</Tooltip>)
      roots.push(root)
    }
  }
})
