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

import {AccountChangeModal} from './HorizonAccountModal'
import {createRoot} from 'react-dom/client'

export const initAccountSelectModal = () => {
  const selectElement = document.getElementById('course_account_id') as HTMLSelectElement

  if (!selectElement) {
    return
  }

  const modalContainer = document.createElement('div')
  modalContainer.id = 'account-change-modal-container'
  document.body.appendChild(modalContainer)
  const modalRoot = createRoot(modalContainer)

  const previousValue = selectElement.value

  selectElement.onchange = event => {
    const currentValue = selectElement.value

    if (currentValue !== previousValue) {
      // only pop the modal if the selected account is horizon account
      const isHorizonAccount =
        (event.target as HTMLSelectElement).options[
          (event.target as HTMLSelectElement).selectedIndex
        ].getAttribute('data-is-horizon') === 'true'
      const isHorizonCourse = window.ENV?.horizon_course
      if (isHorizonAccount && !isHorizonCourse) {
        renderModal(true, currentValue, previousValue)
        event.preventDefault()
      }
    }
  }

  const renderModal = (isOpen: boolean, newValue?: string, oldValue?: string) => {
    modalRoot.render(
      <AccountChangeModal
        isOpen={isOpen}
        onClose={() => {
          if (oldValue) {
            selectElement.value = oldValue
          }
          renderModal(false)
        }}
        onConfirm={() => {
          if (newValue) {
            selectElement.value = newValue
          }
          renderModal(false)
        }}
      />,
    )
  }

  renderModal(false)
}
