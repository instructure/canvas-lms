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
import {IconImageLine} from '@instructure/ui-icons'
import {SVGImageModal} from './SVGImageModal'

const SVGImageToolbar = () => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))
  const [modalOpen, setModalOpen] = useState(false)

  const handleClickSVGButton = useCallback(() => {
    setModalOpen(true)
  }, [])

  const handleCloseSVGModal = useCallback(() => {
    setModalOpen(false)
  }, [])

  const handleSetSVG = useCallback(
    (newSVG: string) => {
      setProp(prps => (prps.src = newSVG))
      setModalOpen(false)
    },
    [setProp]
  )

  return (
    <>
      <IconButton
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel="Edit SVG"
        onClick={handleClickSVGButton}
      >
        <IconImageLine size="x-small" />
      </IconButton>
      <SVGImageModal
        open={modalOpen}
        svg={props.src}
        onClose={handleCloseSVGModal}
        onSubmit={handleSetSVG}
      />
    </>
  )
}

export {SVGImageToolbar}
