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
import {CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {previewBackgroundImage} from '../../shared/utils'
import type {PortfolioDetailData} from '../../types'
import PortfolioView from './PortfolioView'

interface PortfolioPreviewModalProps {
  open: boolean
  portfolio: PortfolioDetailData
  onClose: () => void
}

const PortfolioPreviewModal = ({open, portfolio, onClose}: PortfolioPreviewModalProps) => {
  return (
    <Modal
      open={open}
      size="fullscreen"
      label={`Preview Portfolio: ${portfolio.title}`}
      shouldCloseOnDocumentClick={true}
      onDismiss={onClose}
    >
      <Modal.Body>
        <div
          style={{
            margin: '-1.5rem',
            position: 'relative',
          }}
        >
          <CloseButton placement="end" screenReaderLabel="Close" size="small" onClick={onClose} />
          <div
            style={{
              padding: '3rem 0 1.5rem 0',
              backgroundColor: '#c7cdd1',
              backgroundRepeat: 'repeat',
              backgroundImage: `url(${previewBackgroundImage})`,
            }}
          >
            <View as="div" maxWidth="986px" margin="0 auto" background="primary" shadow="resting">
              <PortfolioView portfolio={portfolio} />
            </View>
          </div>
        </div>
      </Modal.Body>
    </Modal>
  )
}

export default PortfolioPreviewModal
