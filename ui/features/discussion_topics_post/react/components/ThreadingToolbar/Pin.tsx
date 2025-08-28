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
import React from 'react'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {IconPinLine, IconPinSolid} from '@instructure/ui-icons'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {responsiveQuerySizes} from '../../utils'
import {Responsive} from '@instructure/ui-responsive'

const I18n = createI18nScope('discussion_posts')

interface PinProps {
  onClick: () => void
  isPinned: boolean
}

export const Pin: React.FC<PinProps> = ({onClick, isPinned}) => {
  const pinText = I18n.t('Pin')
  const unpinText = I18n.t('Unpin')
  const currentText = isPinned ? unpinText : pinText

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true}) as any}
      props={{
        mobile: {
          isMobile: true,
        },
        desktop: {
          isMobile: false,
        },
      }}
      render={(responsiveProps: any) => (
        <View className="discussion-pin-btn" style={{display: 'inline-flex', alignItems: 'center'}}>
          <Link
            isWithinText={false}
            as="button"
            onClick={onClick}
            renderIcon={isPinned ? <IconPinSolid /> : <IconPinLine />}
            data-testid="threading-toolbar-pin"
            data-action-state={isPinned ? 'unpinButton' : 'pinButton'}
          >
            {!responsiveProps.isMobile && (
              <AccessibleContent alt={currentText}>
                <Text weight="bold">{currentText}</Text>
              </AccessibleContent>
            )}
          </Link>
        </View>
      )}
    />
  )
}

Pin.defaultProps = {
  onClick: () => {},
  isPinned: false,
}
