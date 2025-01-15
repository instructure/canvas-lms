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
import {useNode, type Node} from '@craftjs/core'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const DividerBlock = () => {
  const {
    connectors: {connect, drag},
    node,
  } = useNode((n: Node) => {
    return {
      node: n,
    }
  })

  return (
    <div
      role="treeitem"
      aria-label={node.data.displayName}
      aria-selected={node.events.selected}
      className="block divider-block"
      ref={el => el && connect(drag(el as HTMLElement))}
      tabIndex={-1}
    />
  )
}

DividerBlock.craft = {
  displayName: I18n.t('Divider'),
  custom: {
    isBlock: true,
  },
}

export {DividerBlock}
