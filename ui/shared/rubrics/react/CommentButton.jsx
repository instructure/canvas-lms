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
import PropTypes from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {IconFeedbackLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('edit_rubricCommentButton')

const CommentButton = ({onClick}) => (
  <div>
    <IconButton
      renderIcon={<IconFeedbackLine />}
      withBackground={false}
      withBorder={false}
      margin="0 x-small 0 0"
      onClick={onClick}
      screenReaderLabel={I18n.t('Add Additional Comments')}
    />
  </div>
)
CommentButton.propTypes = {
  onClick: PropTypes.func.isRequired,
}

export default CommentButton
