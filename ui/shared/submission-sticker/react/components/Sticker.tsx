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

import {Img} from '@instructure/ui-img'
import ConfettiExplosion from 'react-confetti-explosion'
import React, {useState} from 'react'

import {stickerContainerClass} from '../helpers/utils'
import Api from '../helpers/api'
import assetFactory, {stickerDescription} from '../helpers/assetFactory'
import ClickableImage from './ClickableImage'
import Sparkles from '@canvas/sparkles/react/components/Sparkles'
import StickerModal from './StickerModal'
import type {StickerProps} from '../types/stickers.d'

export default function Sticker({
  confetti,
  editable,
  liveRegion = () => document.getElementById('flash_screenreader_holder'),
  onStickerChange,
  size,
  submission,
}: StickerProps) {
  const [confettiShowing, setConfettiShowing] = useState(false)
  const [modalShowing, setModalShowing] = useState(false)
  const [hovering, setHovering] = useState(false)

  const triggerConfetti = () => {
    if (!confettiShowing) {
      setConfettiShowing(true)
      setTimeout(() => {
        setConfettiShowing(false)
      }, 3000)
    }
  }

  const openModal = () => setModalShowing(true)
  const closeModal = () => setModalShowing(false)
  const changeSticker = (newSticker: string | null) => {
    const oldSticker = submission.sticker
    closeModal()

    if (oldSticker !== newSticker) {
      const onFailure = (_err: Error) => onStickerChange?.(oldSticker)
      Api.updateSticker(submission, newSticker, onFailure)
      onStickerChange?.(newSticker)
    }
  }

  const removeSticker = () => changeSticker(null)
  if (editable) {
    return (
      <>
        <ClickableImage
          editable={editable}
          onClick={openModal}
          size={size}
          sticker={submission.sticker}
        />

        <StickerModal
          // @ts-expect-error
          liveRegion={liveRegion}
          open={modalShowing}
          onDismiss={closeModal}
          onRemoveSticker={removeSticker}
          onSelectSticker={changeSticker}
          sticker={submission.sticker}
        />
      </>
    )
  }

  if (submission.sticker == null) {
    return null
  }

  if (confetti) {
    return (
      <span style={{position: 'relative'}}>
        <span style={{position: 'absolute', top: '50%', left: '50%'}}>
          {confettiShowing && <ConfettiExplosion zIndex={10} data-testid="confetti-explosion" />}
        </span>
        <ClickableImage
          editable={editable}
          onClick={triggerConfetti}
          size={size}
          sticker={submission.sticker}
        />
      </span>
    )
  }

  return (
    // @ts-expect-error
    <Sparkles key={submission.sticker} enabled={typeof submission.sticker === 'string' && hovering}>
      <div
        className={stickerContainerClass(size)}
        onMouseEnter={() => setHovering(true)}
        onMouseLeave={() => setHovering(false)}
      >
        <Img
          data-testid="sticker-image"
          src={assetFactory(submission.sticker)}
          alt={stickerDescription(submission.sticker)}
        />
      </div>
    </Sparkles>
  )
}
