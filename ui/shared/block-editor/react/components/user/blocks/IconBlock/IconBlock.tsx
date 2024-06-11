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
import {useNode} from '@craftjs/core'
import {getIcon, IconAlarm, type IconSize} from '../../../../assets/icons'
import {IconBlockToolbar} from './IconBlockToolbar'

export type IconBlockProps = {
  iconName: string
  size?: IconSize
}

const IconBlock = ({iconName, size}: IconBlockProps) => {
  const {
    connectors: {connect, drag},
  } = useNode()
  const [Icon, setIcon] = useState(() => {
    return getIcon(iconName) || IconAlarm
  })

  useEffect(() => {
    setIcon(() => getIcon(iconName) || IconAlarm)
  }, [iconName])

  return <Icon elementRef={el => el && connect(drag(el as HTMLElement))} size={size} />
}

IconBlock.craft = {
  displayName: 'Icon',
  defaultProps: {
    iconName: 'apple',
    size: 'small',
  },
  related: {
    toolbar: IconBlockToolbar,
  },
}

export {IconBlock}
