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

import React, {useCallback} from 'react'
import {useNode} from '@craftjs/core'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconBoldLine,
  IconItalicLine,
  IconUnderlineLine,
  IconStrikethroughLine,
} from '@instructure/ui-icons'
import {
  isSelectionAllStyled,
  isElementBold,
  makeSelectionBold,
  unstyleSelection,
  unboldElement,
} from '../../../../utils'

const RCEBlockToolbar = () => {
  const {
    actions: {setProp},
    node,
    props,
  } = useNode(node => ({
    node,
    props: node.data.props,
  }))

  const handleBold = useCallback(() => {
    if (isSelectionAllStyled(isElementBold)) {
      unstyleSelection(isElementBold, unboldElement)
    } else {
      makeSelectionBold()
    }
    setProp(prps => (prps.text = node.dom?.firstElementChild?.innerHTML))
  }, [node.dom, setProp])

  return (
    <>
      <IconButton
        screenReaderLabel="Bold"
        withBackground={false}
        withBorder={false}
        onClick={handleBold}
      >
        <IconBoldLine size="x-small" />
      </IconButton>
      <IconButton screenReaderLabel="Italic" withBackground={false} withBorder={false}>
        <IconItalicLine size="x-small" />
      </IconButton>
      <IconButton screenReaderLabel="Underline" withBackground={false} withBorder={false}>
        <IconUnderlineLine size="x-small" />
      </IconButton>
      <IconButton screenReaderLabel="Strikethrough" withBackground={false} withBorder={false}>
        <IconStrikethroughLine size="x-small" />
      </IconButton>
    </>
  )
}

export {RCEBlockToolbar}
