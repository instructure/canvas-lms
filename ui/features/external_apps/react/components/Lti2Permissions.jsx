/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import React from 'react'
import PropTypes from 'prop-types'
import htmlEscape from '@instructure/html-escape'

const I18n = useI18nScope('external_tools')

export default function Lti2Permissions(props) {
  const p1 = I18n.t('*name* has been successfully installed but has not yet been enabled.', {
    wrappers: [`<strong>${htmlEscape(props.tool.name)}</strong>`],
  })
  return (
    <div className="Lti2Permissions">
      <div className="ReactModal__Body">
        <p dangerouslySetInnerHTML={{__html: p1}} />
        <p>{I18n.t('Would you like to enable this app?')}</p>
      </div>
      <div className="ReactModal__Footer">
        <div className="ReactModal__Footer-Actions">
          <button type="button" className="Button" onClick={props.handleCancelLti2}>
            {I18n.t('Delete')}
          </button>
          <button
            type="button"
            className="Button Button--primary"
            onClick={props.handleActivateLti2}
          >
            {I18n.t('Enable')}
          </button>
        </div>
      </div>
    </div>
  )
}

Lti2Permissions.propTypes = {
  tool: PropTypes.object.isRequired,
  handleCancelLti2: PropTypes.func.isRequired,
  handleActivateLti2: PropTypes.func.isRequired,
}
