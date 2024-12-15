/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React from 'react'
import {SVGIcon} from '@instructure/ui-svg-images'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export type DisplayType = 'grid' | 'rows'

export default function DisplayLayoutButtons({
  displayType,
  setDisplayType,
}: {
  displayType: DisplayType
  setDisplayType: (dtype: DisplayType) => void
}) {
  const gridSVG = `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18" fill="none">
      <g id="Icon">
        <g id="Union">
          <path
            fill-rule="evenodd"
            clip-rule="evenodd"
            d="M0 0.5C0 0.223858 0.223858 0 0.5 0H8C8.27614 0 8.5 0.223858 8.5 0.5V8C8.5 8.27614 8.27614 8.5 8 8.5H0.5C0.223858 8.5 0 8.27614 0 8V0.5ZM1 1.4C1 1.17909 1.17909 1 1.4 1H7.1C7.32091 1 7.5 1.17909 7.5 1.4V7.1C7.5 7.32091 7.32091 7.5 7.1 7.5H1.4C1.17909 7.5 1 7.32091 1 7.1V1.4Z"
            fill="currentColor"
          />
          <path
            fill-rule="evenodd"
            clip-rule="evenodd"
            d="M0 10C0 9.72386 0.223858 9.5 0.5 9.5H8C8.27614 9.5 8.5 9.72386 8.5 10V17.5C8.5 17.7761 8.27614 18 8 18H0.5C0.223858 18 0 17.7761 0 17.5V10ZM1 10.9C1 10.6791 1.17909 10.5 1.4 10.5H7.1C7.32091 10.5 7.5 10.6791 7.5 10.9V16.6C7.5 16.8209 7.32091 17 7.1 17H1.4C1.17909 17 1 16.8209 1 16.6V10.9Z"
            fill="currentColor"
          />
          <path
            fill-rule="evenodd"
            clip-rule="evenodd"
            d="M10 0C9.72386 0 9.5 0.223858 9.5 0.5V8C9.5 8.27614 9.72386 8.5 10 8.5H17.5C17.7761 8.5 18 8.27614 18 8V0.5C18 0.223858 17.7761 0 17.5 0H10ZM10.9 1C10.6791 1 10.5 1.17909 10.5 1.4V7.1C10.5 7.32091 10.6791 7.5 10.9 7.5H16.6C16.8209 7.5 17 7.32091 17 7.1V1.4C17 1.17909 16.8209 1 16.6 1H10.9Z"
            fill="currentColor"
          />
          <path
            fill-rule="evenodd"
            clip-rule="evenodd"
            d="M9.5 10C9.5 9.72386 9.72386 9.5 10 9.5H17.5C17.7761 9.5 18 9.72386 18 10V17.5C18 17.7761 17.7761 18 17.5 18H10C9.72386 18 9.5 17.7761 9.5 17.5V10ZM10.5 10.9C10.5 10.6791 10.6791 10.5 10.9 10.5H16.6C16.8209 10.5 17 10.6791 17 10.9V16.6C17 16.8209 16.8209 17 16.6 17H10.9C10.6791 17 10.5 16.8209 10.5 16.6V10.9Z"
            fill="currentColor"
          />
        </g>
      </g>
    </svg>`

  const rowSVG = `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18" fill="none">
      <g id="Icon">
        <g id="Union">
          <path
            fill-rule="evenodd"
            clip-rule="evenodd"
            d="M0 0.5C0 0.223858 0.223858 0 0.5 0H17.5C17.7761 0 18 0.223858 18 0.5V8C18 8.27614 17.7761 8.5 17.5 8.5H0.5C0.223858 8.5 0 8.27614 0 8V0.5ZM1 1.4C1 1.17909 1.17909 1 1.4 1H16.6C16.8209 1 17 1.17909 17 1.4V7.1C17 7.32091 16.8209 7.5 16.6 7.5H1.4C1.17909 7.5 1 7.32091 1 7.1V1.4Z"
            fill="currentColor"
          />
          <path
            fill-rule="evenodd"
            clip-rule="evenodd"
            d="M0 10C0 9.72386 0.223858 9.5 0.5 9.5H17.5C17.7761 9.5 18 9.72386 18 10V17.5C18 17.7761 17.7761 18 17.5 18H0.5C0.223858 18 0 17.7761 0 17.5V10ZM1 10.9C1 10.6791 1.17909 10.5 1.4 10.5H16.6C16.8209 10.5 17 10.6791 17 10.9V16.6C17 16.8209 16.8209 17 16.6 17H1.4C1.17909 17 1 16.8209 1 16.6V10.9Z"
            fill="currentColor"
          />
        </g>
      </g>
    </svg>`

  const selectGrid = () => {
    setDisplayType('grid')
  }
  const selectRows = () => {
    setDisplayType('rows')
  }

  return (
    <Flex justifyItems="end">
      <IconButton
        withBackground={displayType === 'grid'}
        withBorder={displayType === 'grid'}
        onClick={selectGrid}
        screenReaderLabel={I18n.t('Display templates as grid')}
        title={I18n.t('Display templates as grid')}
      >
        <SVGIcon src={gridSVG} />
      </IconButton>
      <IconButton
        withBackground={displayType === 'rows'}
        withBorder={displayType === 'rows'}
        onClick={selectRows}
        screenReaderLabel={I18n.t('Display templates as rows')}
        title={I18n.t('Display templates as rows')}
      >
        <SVGIcon src={rowSVG} />
      </IconButton>
    </Flex>
  )
}
