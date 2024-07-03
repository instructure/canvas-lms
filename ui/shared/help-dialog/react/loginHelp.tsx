/**
 * Canvas LMS - The open-source learning management system
 *
 * Copyright (C) 2024 Instructure, Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.Wh
 */

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import ReactDOM from 'react-dom'
import {QueryProvider} from '@canvas/query'
import HelpDialog from '.'
import {Modal} from '@instructure/ui-modal'
import {Link} from '@instructure/ui-link'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'

const I18n = useI18nScope('HelpLinks')

interface LoginHelpProps {
  linkText: string
}

const modalLabel = () => I18n.t('Login Help for %{canvas}', {canvas: 'Canvas LMS'})

const LoginHelp = ({linkText}: LoginHelpProps): JSX.Element => {
  // Initial modal state is open, because this whole thing initially
  // loads in response to to the user clicking on the bare "help" link.
  const [open, setOpen] = useState(true)

  function openHelpModal(): void {
    setOpen(true)
  }

  function closeHelpModal(): void {
    setOpen(false)
  }

  return (
    <>
      <Link href="#" onClick={openHelpModal}>
        {linkText}
      </Link>
      <Modal size="small" label={modalLabel()} open={open} onDismiss={closeHelpModal}>
        <Modal.Header>
          <CloseButton
            data-testid="login-help-close-button"
            placement="end"
            offset="medium"
            onClick={closeHelpModal}
            screenReaderLabel={I18n.t('Close help dialog')}
          />
          <Heading level="h3" as="h2">
            {modalLabel()}
          </Heading>
        </Modal.Header>
        <Modal.Body>
          <HelpDialog onFormSubmit={closeHelpModal} />
        </Modal.Body>
      </Modal>
    </>
  )
}

export function renderLoginHelp(loginLink: Element): void {
  // wrap the help link in a span we can hang the modal off of.
  // then render the React modal into it. Be sure we're actually
  // getting an anchor element.
  if (loginLink.tagName !== 'A') throw new TypeError('loginLink must be an <a> element')
  const linkText = loginLink.textContent ?? ''
  const wrapper = document.createElement('span')
  loginLink.replaceWith(wrapper)
  wrapper.appendChild(loginLink)
  ReactDOM.render(
    <QueryProvider>
      <LoginHelp linkText={linkText} />
    </QueryProvider>,
    wrapper
  )
}
