/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import PropTypes from 'prop-types'

export default {
  link: PropTypes.shape({
    text: PropTypes.string.isRequired,
    url: PropTypes.string.isRequired,
    subtext: PropTypes.string,
    available_to: PropTypes.array,
    type: PropTypes.oneOf(['default', 'custom']),
    id: PropTypes.string,

    index: PropTypes.number,
    state: PropTypes.oneOf(['new', 'active', 'deleted']),
    action: PropTypes.oneOf(['edit', 'focus']),
    is_disabled: PropTypes.bool,
  }),
}
