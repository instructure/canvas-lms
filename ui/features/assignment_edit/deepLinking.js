/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

// Handle the deep linking message event for submission_type_selection and assignment_selection placements
export default function handleResponse(messageEvent) {
  if (messageEvent.data?.content_items.length >= 1) {
    process_resource_link_attributes(messageEvent.data?.content_items[0])
    process_tool_dimensions(messageEvent.data?.content_items[0])
  }

  closeModal()
}

// Process the width and height received in a deep linking message
function process_tool_dimensions(content_item) {
  if (!content_item.iframe) return

  const received_width = content_item?.iframe.width
  const received_height = content_item?.iframe.height

  const width = document.querySelector('input#assignment_external_tool_tag_attributes_iframe_width')
  const height = document.querySelector(
    'input#assignment_external_tool_tag_attributes_iframe_height'
  )

  if (received_width) {
    width.setAttribute('value', received_width)
  }

  if (received_height) {
    height.setAttribute('value', received_height)
  }
}

function process_resource_link_attributes(content_item) {
  const received_attributes = {
    id: content_item.id,
    type: content_item.type,
    url: content_item.url,
    new_tab: content_item.new_tab,
    custom_params: content_item.custom
  }

  const existing_elements = {
    id: document.querySelector('input#assignment_external_tool_tag_attributes_content_id'),
    type: document.querySelector('input#assignment_external_tool_tag_attributes_content_type'),
    url: document.querySelector('input#assignment_external_tool_tag_attributes_url'),
    new_tab: document.querySelector('input#assignment_external_tool_tag_attributes_new_tab'),
    custom_params: document.querySelector(
      'input#assignment_external_tool_tag_attributes_custom_params'
    )
  }

  for (const [attribute, value] of Object.entries(received_attributes)) {
    const html_element = existing_elements[`${attribute}`]

    if (typeof value !== 'undefined' && html_element) {
      switch (attribute) {
        case 'new_tab':
          if (value === '1') html_element.setAttribute('checked', 'checked')
          else html_element.removeAttribute('checked')
          break
        case 'custom_params':
          html_element.setAttribute('value', JSON.stringify(value))
          break
        default:
          html_element.setAttribute('value', value)
      }
    }
  }
}

// Close the CanvasModal used for the LTI launched in the submission_type_selection placement
function closeModal() {
  //   see:
  //   1 - renderSubmissionTypeSelectionDialog() from ui/features/assignment_edit/backbone/views/EditView.coffee
  //   2 - render() from ui/shared/external-tools/react/components/ExternalToolModalLauncher.js
  //   3 - CanvasModal component in ui/shared/instui-bindings/react/Modal.tsx
  document
    .querySelector(
      'span[data-cid="Modal"] div[data-cid="ModalHeader"] span[data-cid="CloseButton"] > button'
    )
    ?.click()
}
