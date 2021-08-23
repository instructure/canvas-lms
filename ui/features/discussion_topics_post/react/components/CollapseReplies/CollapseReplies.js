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

import I18n from 'i18n!discussion_posts'
import PropTypes from 'prop-types'
import React from 'react'
import {CondensedButton} from '@instructure/ui-buttons'

export function CollapseReplies({...props}) {
  return (
    <CondensedButton
      onClick={props.onClick}
      withBackground={false}
      color="primary"
      data-testid="collapse-replies"
    >
      {I18n.t('Collapse replies')}
    </CondensedButton>
  )
}

CollapseReplies.propTypes = {
  /**
   * Behavior when clicking the expansion button
   */
  onClick: PropTypes.func.isRequired
}
