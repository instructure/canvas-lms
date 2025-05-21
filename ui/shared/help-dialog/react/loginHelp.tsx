/**
 * Canvas LMS - The open-source learning management system
 *
 * Copyright (C) 2013 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import {createRoot} from 'react-dom/client'
import HelpDialog from '.'
import {Modal} from '@instructure/ui-modal'
import {Link} from '@instructure/ui-link'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
import type {ViewOwnProps} from '@instructure/ui-view'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'

const I18n = createI18nScope('HelpLinks')

interface LoginHelpProps {
  linkText: string
}

const modalLabel = () => I18n.t('Login Help for %{canvas}', {canvas: 'Canvas LMS'})

const LoginHelp = ({linkText}: LoginHelpProps): JSX.Element => {
  // Initial modal state is open, because this whole thing initially
  // loads in response to the user clicking on the bare "help" link.
  const [open, setOpen] = useState(true)

  function openHelpModal(event: React.MouseEvent<ViewOwnProps>): void {
    event.preventDefault()
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
  const anchorElement = loginLink.closest('a')
  if (!anchorElement) {
    throw new TypeError('Element must be an <a> element or a descendant of an <a> element')
  }
  const wrapper = document.createElement('span')
  anchorElement.replaceWith(wrapper)
  wrapper.appendChild(anchorElement)

  const root = createRoot(wrapper)
  root.render(
    <QueryClientProvider client={queryClient}>
      <LoginHelp linkText={anchorElement.innerText} />
    </QueryClientProvider>,
  )
}

export default LoginHelp
