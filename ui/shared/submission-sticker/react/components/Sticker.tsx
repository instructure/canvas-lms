/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useState} from 'react'
import Confetti from '@canvas/confetti/react/Confetti'
import ClickableImage from './ClickableImage'
import type {StickerProps} from '../types/stickers.d'
import assetFactory, {stickerDescriptions} from '../helpers/assetFactory'
import {stickerContainerClass} from '../helpers/utils'
import {Img} from '@instructure/ui-img'

export default function Sticker({confetti, size, submission}: StickerProps) {
  const [confettiShowing, setConfettiShowing] = useState(false)

  const triggerConfetti = () => {
    if (!confettiShowing) {
      setConfettiShowing(true)
      setTimeout(() => {
        setConfettiShowing(false)
      }, 3000)
    }
  }

  if (confetti) {
    return (
      <>
        <ClickableImage sticker={submission.sticker} size={size} onClick={triggerConfetti} />
        {confettiShowing && <Confetti triggerCount={null} />}
      </>
    )
  }

  return (
    <div className={stickerContainerClass(size)}>
      <Img src={assetFactory(submission.sticker)} alt={stickerDescriptions(submission.sticker)} />
    </div>
  )
}
