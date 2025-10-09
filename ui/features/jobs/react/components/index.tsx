/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
const I18n = createI18nScope('jobs')

function testIdIfy(str: string, suffix: string): string {
  return str.toLowerCase().replace(/\s+/g, '-') + '-' + suffix
}

interface Props {
  label: string
  retrieveValue: () => Promise<string>
}

function JobDialog({label, retrieveValue}: Props): React.JSX.Element {
  const [isOpen, setIsOpen] = useState(false)
  const [text, setText] = useState('')

  async function openModal() {
    setIsOpen(true)
    setText(await retrieveValue())
  }

  return (
    <>
      <Link
        data-testid={testIdIfy(label, 'show')}
        variant="standalone"
        href="#"
        onClick={openModal}
      >
        {I18n.t('show')}
      </Link>
      <Modal open={isOpen} onDismiss={() => setIsOpen(false)} label={label}>
        <Modal.Header>
          <Heading>{label}</Heading>
          <CloseButton
            data-testid={testIdIfy(label, 'close')}
            onClick={() => setIsOpen(false)}
            screenReaderLabel={I18n.t('Close')}
            placement="end"
          />
        </Modal.Header>
        <Modal.Body>
          <textarea
            data-testid={testIdIfy(label, 'textarea')}
            value={text}
            readOnly
            style={{width: '400px'}}
          />
        </Modal.Body>
      </Modal>
    </>
  )
}

export {JobDialog}
