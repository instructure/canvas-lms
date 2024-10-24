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
import type {ClickableImageProps, IconOverlayProps} from '../types/stickers.d'
import assetFactory, {stickerDescription} from '../helpers/assetFactory'
import {stickerContainerClass} from '../helpers/utils'
import {IconEditSolid, IconAddSolid} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import Sparkles from '@canvas/sparkles'

function IconOverlay({showIcon, sticker}: IconOverlayProps) {
  return (
    <div
      data-testid="edit-icon-overlay"
      className={`Sticker__Overlay${showIcon ? ' showing' : ''}`}
    >
      <div className="Sticker__Icon">
        {sticker ? (
          <IconEditSolid color="primary-inverse" size="x-small" />
        ) : (
          <IconAddSolid color="primary-inverse" size="x-small" />
        )}
      </div>
    </div>
  )
}

export default function ClickableImage({editable, onClick, size, sticker}: ClickableImageProps) {
  const [hovering, setHovering] = useState(false)
  const startHover = () => {
    setHovering(true)
  }
  const stopHover = () => {
    setHovering(false)
  }

  return (
    <Sparkles
      key={sticker}
      size={size === 'small' ? 'small' : 'medium'}
      enabled={typeof sticker === 'string' && hovering}
    >
      <button
        data-testid="sticker-button"
        className={stickerContainerClass(size)}
        onBlur={stopHover}
        onClick={onClick}
        onFocus={startHover}
        onMouseEnter={startHover}
        onMouseLeave={stopHover}
        type="button"
      >
        <div
          className={`StickerOverlay__Container ${size}${
            sticker ? ' Sticker__ShinyContainer' : ''
          }`}
        >
          <Img
            data-testid="sticker-image"
            src={assetFactory(sticker)}
            alt={stickerDescription(sticker)}
          />
          {editable && <IconOverlay sticker={sticker} showIcon={hovering} />}
        </div>
      </button>
    </Sparkles>
  )
}
