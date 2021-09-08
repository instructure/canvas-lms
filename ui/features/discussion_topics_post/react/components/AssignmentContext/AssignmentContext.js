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

import React from 'react'
import {responsiveQuerySizes} from '../../utils/index'

import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import PropTypes from 'prop-types'

export function AssignmentContext({...props}) {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true})}
      props={{
        tablet: {
          textSize: 'x-small',
          displayText: null
        },
        desktop: {
          textSize: 'small',
          displayText: props.group ? props.group : I18n.t('Everyone')
        }
      }}
      render={responsiveProps => {
        return responsiveProps.displayText ? (
          <Text weight="normal" size={responsiveProps.textSize}>
            {responsiveProps.displayText}
          </Text>
        ) : null
      }}
    />
  )
}

AssignmentContext.propTypes = {
  group: PropTypes.string
}
