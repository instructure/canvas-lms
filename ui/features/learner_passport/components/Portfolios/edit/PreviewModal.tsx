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

import React, {useCallback} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {PortfolioDetailData} from '../../types'
import PortfolioView from '../PortfolioView'

interface PreviewModalProps {
  open: boolean
  portfolio: PortfolioDetailData
  onClose: () => void
}

const PreviewModal = ({open, portfolio, onClose}: PreviewModalProps) => {
  const handleDismiss = useCallback(() => {
    onClose()
  }, [onClose])

  return (
    <Modal
      open={open}
      size="auto"
      label={`Preview Portfolio: ${portfolio.title}`}
      shouldCloseOnDocumentClick={true}
      onDismiss={onClose}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={handleDismiss}
          screenReaderLabel="Close"
        />
        <Heading>{`Preview Portfolio: ${portfolio.title}`}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" maxWidth="986px" margin="0 auto">
          <PortfolioView portfolio={portfolio} />
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={handleDismiss}>
          Close
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default PreviewModal
