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

import {Link} from '@instructure/ui-link'
import PropTypes from 'prop-types'
import React from 'react'
import {Text} from '@instructure/ui-text'

export function ShowMoreRepliesButton({onClick, ...props}) {
  return (
    <span className="discussions-show-more-replies-button">
      <Link
        isWithinText={false}
        as="button"
        onClick={onClick}
        data-testid="show-more-replies-button"
        interaction={props.fetchingMoreReplies ? 'disabled' : 'enabled'}
        {...props}
      >
        <Text weight="bold">{props.buttonText}</Text>
      </Link>
    </span>
  )
}

ShowMoreRepliesButton.propTypes = {
  /**
   * Behavior for showing more replies.
   */
  onClick: PropTypes.func,
  /**
   * Text to be displayed on the button.
   */
  buttonText: PropTypes.string.isRequired,
  /**
   * Boolean that controls if the button is disabled.
   */
  fetchingMoreReplies: PropTypes.bool,
}

ShowMoreRepliesButton.defaultProps = {
  onClick: () => {},
  fetchingMoreReplies: false,
}
