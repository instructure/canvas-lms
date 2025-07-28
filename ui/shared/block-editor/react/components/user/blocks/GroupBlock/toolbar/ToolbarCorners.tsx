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
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {SVGIcon} from '@instructure/ui-svg-images'
import {useScope as createI18nScope} from '@canvas/i18n'

const roundedCorners = `<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg">
  <rect width="16" height="16" rx="4" ry="4" fill="none" stroke="currentColor" />
</svg>`

const squareCorners = `<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg">
  <rect width="16" height="16" fill="none" stroke="currentColor" />
</svg>`

const I18n = createI18nScope('block-editor')

type ToolbarCornersProps = {
  rounded: boolean
  onSave(value: boolean): void
}

const ToolbarCorners = ({rounded, onSave}: ToolbarCornersProps) => {
  const renderTrigger = () => {
    return (
      <IconButton
        withBorder={false}
        withBackground={false}
        screenReaderLabel={I18n.t('Rouned corners')}
        title={I18n.t('Rouned corners')}
      >
        <SVGIcon size="x-small" src={rounded ? roundedCorners : squareCorners} />
      </IconButton>
    )
  }

  return (
    <Menu trigger={renderTrigger()}>
      <Menu.Item type="checkbox" value="square" selected={!rounded} onSelect={() => onSave(false)}>
        {I18n.t('Square')}
      </Menu.Item>
      <Menu.Item type="checkbox" value="rounded" selected={rounded} onSelect={() => onSave(true)}>
        {I18n.t('Rounded')}
      </Menu.Item>
    </Menu>
  )
}

export {ToolbarCorners}
