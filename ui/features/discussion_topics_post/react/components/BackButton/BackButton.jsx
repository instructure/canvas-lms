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

import {Button} from '@instructure/ui-buttons'
import {IconArrowStartLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../utils'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('discussion_posts')

export function BackButton({onClick, ...props}) {
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
        },
      }}
      render={responsiveProps => (
        <span className="discussions-back-button">
          <Button
            onClick={onClick}
            withBorder={false}
            withBackground={false}
            color="primary"
            renderIcon={<IconArrowStartLine />}
            themeOverride={{borderWidth: 0}}
            data-testid="back-button"
            {...props}
          >
            <Text weight="bold" size={responsiveProps.textSize}>
              {I18n.t('Back')}
            </Text>
          </Button>
        </span>
      )}
    />
  )
}

BackButton.propTypes = {
  /**
   * Behavior for going back to the parent's thread.
   */
  onClick: PropTypes.func,
}

BackButton.defaultProps = {
  onClick: () => {},
}
