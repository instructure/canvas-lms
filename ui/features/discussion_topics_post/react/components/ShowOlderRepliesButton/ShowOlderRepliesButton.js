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

import {CondensedButton} from '@instructure/ui-buttons'
import I18n from 'i18n!discussion_posts'
import PropTypes from 'prop-types'
import React from 'react'
import {Text} from '@instructure/ui-text'

export function ShowOlderRepliesButton({onClick, ...props}) {
  return (
    <CondensedButton
      onClick={onClick}
      color="primary"
      data-testid="show-older-replies-button"
      {...props}
    >
      <Text weight="bold">{I18n.t('Show older replies')}</Text>
    </CondensedButton>
  )
}

ShowOlderRepliesButton.propTypes = {
  /**
   * Behavior for showing older replies.
   */
  onClick: PropTypes.func
}

ShowOlderRepliesButton.defaultProps = {
  onClick: () => {}
}
