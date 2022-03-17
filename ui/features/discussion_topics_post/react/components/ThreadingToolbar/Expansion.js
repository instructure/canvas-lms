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
import {CondensedButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../utils'

const I18n = useI18nScope('discussion_posts')

export function Expansion({...props}) {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          textSize: 'small'
        },
        desktop: {
          textSize: 'medium',
          itemSpacing: 'none'
        }
      }}
      render={responsiveProps => (
        <CondensedButton
          onClick={props.onClick}
          withBackground={false}
          color="primary"
          data-testid="expand-button"
          interaction={props.isReadOnly ? 'disabled' : 'enabled'}
        >
          <ScreenReaderContent>
            {props.isExpanded
              ? I18n.t('Collapse discussion thread')
              : I18n.t('Expand discussion thread')}
          </ScreenReaderContent>
          <Text
            weight="bold"
            size={responsiveProps.textSize}
            data-testid={`text-${responsiveProps.textSize}`}
          >
            {props.expandText}
          </Text>
        </CondensedButton>
      )}
    />
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
  expandText: PropTypes.oneOfType([PropTypes.string, PropTypes.object]).isRequired,
  /**
   * Key consumed by ThreadingToolbar's InlineList
   */
  delimiterKey: PropTypes.string.isRequired,
  /**
   * Disable/Enable for the button
   */
  isReadOnly: PropTypes.bool
}

Expansion.defaultPropTypes = {
  isReadOnly: true
}
