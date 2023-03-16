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

/**
 * Injects elements for tests leveraging components that expect external sources to
 * have previously injected into the document. All supported element ids are
 * accounted for here, though not all uses of this function will require that.
 */
export default function injectGlobalAlertContainers() {
  const elementIds: string[] = [
    'flash_screenreader_holder',
    'flashalert_message_holder',
    'flash-messages',
  ]
  beforeEach(() => {
    elementIds.forEach((elementId: string) => {
      const element: HTMLDivElement = document.createElement('div')
      element.setAttribute('id', elementId)
      element.setAttribute('role', 'alert')
      document.body.appendChild(element)
    })
  })

  afterEach(() => {
    elementIds.forEach((elementId: string) => {
      document.getElementById(elementId)?.remove()
    })
  })
}
