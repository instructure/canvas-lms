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

import React, {useEffect, useState} from 'react'
import {useNode, type Node} from '@craftjs/core'
import {getIcon, IconAlarm} from '../../../../assets/user-icons'
import {IconBlockToolbar} from './IconBlockToolbar'
import {type IconBlockProps, type IconSize} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const IconBlock = ({iconName, size, color}: IconBlockProps) => {
  const {
    connectors: {connect, drag},
    node,
  } = useNode((n: Node) => {
    return {
      node: n,
    }
  })
  const [Icon, setIcon] = useState(() => {
    return getIcon(iconName) || IconAlarm
  })

  useEffect(() => {
    setIcon(() => getIcon(iconName) || IconAlarm)
  }, [iconName])

  const styl: React.CSSProperties = {}
  if (color) {
    styl.color = color
  }

  return (
    <div
      role="treeitem"
      aria-label={node.data.displayName}
      aria-selected={node.events.selected}
      className="block icon-block"
      ref={el => el && connect(drag(el as HTMLElement))}
      style={styl}
      tabIndex={-1}
      data-testid="icon-block"
    >
      <Icon size={size} />
    </div>
  )
}

IconBlock.craft = {
  displayName: I18n.t('Icon'),
  defaultProps: {
    iconName: 'apple',
    size: 'small' as IconSize,
  },
  related: {
    toolbar: IconBlockToolbar,
  },
  custom: {
    isBlock: true,
  },
}

export {IconBlock}
