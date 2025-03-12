/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('discussions_posts')

const SwitchToIndividualPostsLink = props => {
  return (
    <Link id="switch-to-individual-posts-link" onClick={props.onSwitchLinkClick}>
      {I18n.t('Switch to individual posts')}
    </Link>
  )
}

export default SwitchToIndividualPostsLink

SwitchToIndividualPostsLink.propTypes = {
  onSwitchLinkClick: PropTypes.func.isRequired,
}
