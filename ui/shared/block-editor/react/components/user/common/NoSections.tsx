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
import {useEditor, useNode, type Node} from '@craftjs/core'
import {useClassNames} from '../../../utils'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor/no-sections')

export type NoSectionsProps = {
  className?: string
  children?: React.ReactNode
}

export const NoSections = ({className = '', children}: NoSectionsProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect},
  } = useNode()
  const clazz = useClassNames(enabled, {empty: !children}, [className, 'no-sections'])

  return (
    <div
      ref={el => el && connect(el)}
      className={clazz}
      data-placeholder={I18n.t('Drop a block to add it here')}
    >
      {children}
    </div>
  )
}

NoSections.craft = {
  rules: {
    canMoveIn: (nodes: Node[]) => !nodes.some(node => node.data.custom.isSection),
  },
  custom: {
    noToolbar: true,
  },
}
