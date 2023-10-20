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

import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'

import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussion_posts')

export function SearchResultsCount({...props}) {
  return (
    <View margin="0 0 0 medium">
      <Text size="small">
        {I18n.t(
          {
            one: '1 result found',
            other: '%{count} results found',
          },
          {
            count: props.resultsFound,
          }
        )}
      </Text>
    </View>
  )
}

SearchResultsCount.propTypes = {
  resultsFound: PropTypes.number.isRequired,
}
