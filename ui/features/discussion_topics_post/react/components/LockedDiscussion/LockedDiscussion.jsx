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
import {responsiveQuerySizes} from '../../utils'

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('discussion_posts')

export const LockedDiscussion = props => {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          titleMargin: 'x-small',
          titleTextSize: 'medium',
          titleTextWeight: 'bold',
        },
        desktop: {
          titleMargin: 'small 0 small large',
          titleTextSize: 'x-large',
          titleTextWeight: 'normal',
        },
      }}
      render={responsiveProps => (
        <View as="h2" margin={responsiveProps.titleMargin}>
          <Text
            data-testid="locked-discussion"
            size={responsiveProps.titleTextSize}
            weight={responsiveProps.titleTextWeight}
          >
            <AccessibleContent alt={I18n.t('Discussion Topic: %{title}', {title: props.title})}>
              {props.title}
            </AccessibleContent>
          </Text>
        </View>
      )}
    />
  )
}

LockedDiscussion.propTypes = {
  title: PropTypes.string.isRequired,
}
