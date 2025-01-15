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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Button, CondensedButton} from '@instructure/ui-buttons'
import {IconCheckSolid, IconTrashLine} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import assetFactory, {stickerDescription, stickerDescriptions} from '../helpers/assetFactory'
import type {StickerModalProps} from '../types/stickers.d'

const I18n = createI18nScope('submission_sticker')

export default function StickerModal({
  liveRegion,
  onDismiss,
  onRemoveSticker,
  onSelectSticker,
  open,
  sticker,
}: StickerModalProps) {
  const stickerIsSelected = open && !!sticker
  const stickerJustRemovedAndModalClosing = !open && !sticker
  return (
    <>
      <Alert
        liveRegion={liveRegion}
        screenReaderOnly={true}
        isLiveRegionAtomic={true}
        liveRegionPoliteness="assertive"
      >
        {sticker
          ? I18n.t('Selected sticker: %{sticker}', {sticker: stickerDescription(sticker)})
          : I18n.t('Removed sticker')}
      </Alert>
      <Modal
        open={open}
        overflow="scroll"
        size="medium"
        label={I18n.t('Choose a sticker')}
        onDismiss={onDismiss}
      >
        <Modal.Body>
          {(stickerIsSelected || stickerJustRemovedAndModalClosing) && (
            <Flex justifyItems="center">
              <Flex.Item>
                <Button
                  data-testid="sticker-remove"
                  onClick={onRemoveSticker}
                  // @ts-expect-error
                  renderIcon={IconTrashLine}
                >
                  {I18n.t('Remove sticker')}
                </Button>
              </Flex.Item>
            </Flex>
          )}
          <div className="StickerSearch__images" data-testid="sticker-modal">
            {Object.entries(stickerDescriptions()).map(([name, altText]) => (
              <div key={name} className="ModalSticker__Container">
                <CondensedButton onClick={() => onSelectSticker(name)}>
                  <div className="ModalSticker">
                    {name === sticker && (
                      <span className="ModalSticker__Checkmark">
                        <IconCheckSolid size="x-small" />
                      </span>
                    )}
                    <img data-testid="sticker-image" src={assetFactory(name)} alt={altText} />
                  </div>
                </CondensedButton>
              </div>
            ))}
          </div>
        </Modal.Body>
      </Modal>
    </>
  )
}
