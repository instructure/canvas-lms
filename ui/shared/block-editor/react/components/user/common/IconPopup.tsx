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

import React, {useCallback, useState} from 'react'
import {useNode} from '@craftjs/core'
import {Button} from '@instructure/ui-buttons'
import {Popover} from '@instructure/ui-popover'
import {IconImageLine} from '@instructure/ui-icons'
import {IconPicker} from '../blocks/IconBlock'

type IconPopupProps = {
  iconName?: string
}

const IconPopup = ({iconName}: IconPopupProps) => {
  const {
    actions: {setProp},
  } = useNode(node => ({
    props: node.data.props,
  }))
  const [isShowingContent, setIsShowingContent] = useState(false)
  const [selectedIcon, setSelectedIcon] = useState(iconName)

  const handleShowContent = useCallback(() => {
    setIsShowingContent(true)
  }, [])

  const handleHideContent = useCallback(() => {
    setIsShowingContent(false)
  }, [])

  const handleSelectIcon = useCallback(
    (newIconName: string) => {
      setSelectedIcon(newIconName)
      setProp((prps: {iconName: string}) => (prps.iconName = newIconName))
    },
    [setProp]
  )

  return (
    <Popover
      renderTrigger={
        <Button size="small" withBackground={false}>
          Select Icon
        </Button>
      }
      isShowingContent={isShowingContent}
      onShowContent={handleShowContent}
      onHideContent={handleHideContent}
      on="click"
      placement="bottom start"
      shadow="resting"
      screenReaderLabel="Popover Dialog Example"
      shouldAlignArrow={true}
      shouldContainFocus={true}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={true}
    >
      <IconPicker iconName={selectedIcon} onSelect={handleSelectIcon} />
    </Popover>
  )
}

export {IconPopup}
