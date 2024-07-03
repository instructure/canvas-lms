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

import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconBackgroundColor} from '../../../assets/internal-icons'

import {ColorModal} from './ColorModal'
import {type ContainerProps} from '../blocks/Container/types'

const SectionToolbar = () => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))
  const [colorModalOpen, setColorModalOpen] = useState(false)

  const handleBackgroundColorChange = useCallback(
    (color: string) => {
      setProp((prps: ContainerProps) => (prps.background = color))
      setColorModalOpen(false)
    },
    [setProp]
  )

  const handleBackgroundColorButtonClick = useCallback(() => {
    setColorModalOpen(true)
  }, [])

  const handleCloseColorModal = useCallback(() => {
    setColorModalOpen(false)
  }, [])

  return (
    <Flex gap="small">
      <IconButton
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel="Color"
        disabled={props.variant === 'condensed'}
        onClick={handleBackgroundColorButtonClick}
      >
        <IconBackgroundColor size="x-small" />
      </IconButton>

      <ColorModal
        open={colorModalOpen}
        color={props.background}
        variant="background"
        onClose={handleCloseColorModal}
        onSubmit={handleBackgroundColorChange}
      />
    </Flex>
  )
}

export {SectionToolbar}
