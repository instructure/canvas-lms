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

import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconPlusLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('rubrics-criterion-modal')

type AddRatingRowProps = {
  unassessed: boolean
  onClick: () => void
  isDragging: boolean
}
export const AddRatingRow = ({unassessed, onClick, isDragging}: AddRatingRowProps) => {
  const [isHovered, setIsHovered] = useState(false)

  return (
    <View
      as="div"
      data-testid="add-rating-row"
      textAlign="center"
      margin="0"
      height="1.688rem"
      width="100%"
      tabIndex={0}
      position="relative"
      onKeyDown={e => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          onClick()
        }
      }}
      label="Add New Rating"
      onFocus={() => setIsHovered(true)}
      onMouseOver={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      {isHovered && unassessed && !isDragging && (
        <View as="div" cursor="pointer" onClick={onClick} onBlur={() => setIsHovered(false)}>
          <IconButton
            screenReaderLabel={I18n.t('Add new rating')}
            shape="circle"
            size="small"
            color="primary"
            themeOverride={{smallHeight: '1.5rem'}}
          >
            <IconPlusLine />
          </IconButton>
          <div
            style={{
              border: 'none',
              borderTop: '0.125rem solid var(--ic-brand-primary)',
              width: '100%',
              height: '0.063rem',
              margin: '-0.75rem 0 0 0',
            }}
          />
        </View>
      )}
    </View>
  )
}
