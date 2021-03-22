/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import I18n from 'i18n!conversations_2'
import PropTypes from 'prop-types'
import React from 'react'
import {CondensedButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

export function Expansion({...props}) {
  return (
    <CondensedButton
      onClick={props.onClick}
      withBackground={false}
      color="primary"
      data-testid="expand-button"
    >
      <ScreenReaderContent>
        {props.isExpanded
          ? I18n.t('Collapse discussion thread')
          : I18n.t('Expand discussion thread')}
      </ScreenReaderContent>
      {props.expandText}
    </CondensedButton>
  )
}

Expansion.propTypes = {
  /**
   * Behavior when clicking the expansion button
   */
  onClick: PropTypes.func.isRequired,
  /**
   * Whether or not the post has been expanded
   */
  isExpanded: PropTypes.bool.isRequired,
  /**
   * Text to display for the button
   */
  expandText: PropTypes.string.isRequired
}
