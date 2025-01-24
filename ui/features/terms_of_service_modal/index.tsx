/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import TermsOfServiceModal from './react/TermsOfServiceModal'
import ready from '@instructure/ready'
import { createRoot } from 'react-dom/client'

const renderTermsModal = (container: Element | null, opts = { preview: false, footerLink: false }) => {
  if (container instanceof HTMLElement) {
    const root = createRoot(container)
    root.render(<TermsOfServiceModal preview={opts.preview} footerLink={opts.footerLink} />)
  }
}

ready(() => {
  renderTermsModal(document.querySelector('#terms_of_service_preview_link'), {
    preview: true,
    footerLink: false
  })
  document.querySelectorAll('.terms_of_service_link').forEach(container => {
    const footerLink = container.classList.contains('terms_of_service_footer_link')
    renderTermsModal(container, { preview: false, footerLink })
  })
})
