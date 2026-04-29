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

import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {Link} from '@instructure/ui-link'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconArrowOpenEndLine, IconArrowOpenDownLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('discussion_posts')

export function Expansion({...props}) {
  return (
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
        <Flex gap="x-small">
          {props.isExpanded ? <IconArrowOpenDownLine /> : <IconArrowOpenEndLine />}
          <Text weight="bold" size="medium" data-testid="text-medium">
            {props.expandText}
          </Text>
        </Flex>
      </Link>
    </span>
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
