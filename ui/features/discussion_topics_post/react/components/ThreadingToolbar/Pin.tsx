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
import {IconPinLine} from '@instructure/ui-icons'
import {AccessibleContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('discussion_posts')

interface PinProps {
  onClick: () => void
}

export const Pin: React.FC<PinProps> = ({onClick}) => {
  return (
    <View className="discussion-pin-btn" style={{display: 'inline-flex', alignItems: 'center'}}>
      <Link
        isWithinText={false}
        as="button"
        onClick={onClick}
        renderIcon={<IconPinLine />}
        data-testid="pin-button"
      >
        <AccessibleContent alt={I18n.t('Pin')}>
          <Text weight="bold">{I18n.t('Pin')}</Text>
        </AccessibleContent>
      </Link>
    </View>
  )
}

Pin.defaultProps = {
  onClick: () => {},
}
