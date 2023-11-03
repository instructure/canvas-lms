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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Button, IconButton, CloseButton} from '@instructure/ui-buttons'
import {IconQuestionLine} from '@instructure/ui-icons'

const I18n = useI18nScope('content_migrations_redesign')

type InfoButtonProps = {
  heading: string
  body: React.ReactNode
  buttonLabel: string
  modalLabel: string
}

export const InfoButton = ({heading, body, buttonLabel, modalLabel}: InfoButtonProps) => {
  const [open, setOpen] = useState(false)

  return (
    <>
      <IconButton
        shape="circle"
        renderIcon={IconQuestionLine}
        withBackground={false}
        withBorder={false}
        screenReaderLabel={buttonLabel}
        onClick={() => setOpen(true)}
      />
      <Modal
        open={open}
        onDismiss={() => setOpen(false)}
        size="small"
        label={modalLabel}
        shouldCloseOnDocumentClick={true}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={() => setOpen(false)}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{heading}</Heading>
        </Modal.Header>
        <Modal.Body>{body}</Modal.Body>
        <Modal.Footer>
          <Button onClick={() => setOpen(false)} color="primary">
            {I18n.t('Close')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}

export default InfoButton
