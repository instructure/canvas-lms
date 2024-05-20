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
import {Link} from '@instructure/ui-link'
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
          textSize: 'small',
        },
        desktop: {
          textSize: 'medium',
          itemSpacing: 'none',
        },
      }}
      render={responsiveProps => (
        <span className="discussion-expand-btn">
          <Link
            isWithinText={false}
            as="button"
            onClick={props.onClick}
            data-testid="expand-button"
            interaction={props.isReadOnly ? 'disabled' : 'enabled'}
            aria-expanded={props.isExpanded}
            ref={props.expansionButtonRef}
          >
            <ScreenReaderContent
              data-testid={
                props.isExpanded ? 'reply-expansion-btn-collapse' : 'reply-expansion-btn-expand'
              }
            >
              {props.isExpanded
                ? I18n.t('Collapse discussion thread from %{author}', {
                    author: props.authorName,
                  })
                : I18n.t('Expand discussion thread from %{author}', {
                    author: props.authorName,
                  })}
            </ScreenReaderContent>
            <Text
              weight="bold"
              size={responsiveProps.textSize}
              data-testid={`text-${responsiveProps.textSize}`}
            >
              {props.expandText}
            </Text>
          </Link>
        </span>
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
   * Name of author of the post being replied to
   */
  authorName: PropTypes.string,
  /**
   * Disable/Enable for the button
   */
  isReadOnly: PropTypes.bool,
  expansionButtonRef: PropTypes.any,
}

Expansion.defaultPropTypes = {
  isReadOnly: true,
}
