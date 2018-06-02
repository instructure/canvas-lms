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
import {string, node, func} from 'prop-types'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import I18n from 'i18n!modal'
import Modal, { ModalHeader } from '@instructure/ui-overlays/lib/components/Modal'

export {ModalBody, ModalFooter, ModalHeader} from '@instructure/ui-overlays/lib/components/Modal'

/*
---
This is just a wrapper around the default instructure-ui Modal that:
 * sets an applicationElement that works with canvas's HTML
 * provides a translated close button label that works with Canvas's I18n
 * sets a title for you if you provide a `label` prop
You should be able to use it exactly like you'd use an instUi Modal by changing:
import Modal, {ModalBody, ModalFooter} from '@instructure/ui-core/lib/components/Modal'
to
import Modal, {ModalBody, ModalFooter} from '../shared/components/InstuiModal'
---
*/
export default function InstuiModal ({label, handleCloseClick, children, ...otherPropsToPassOnToModal}) {
  return (
    <Modal {...otherPropsToPassOnToModal}
      label={label}
    >
      <ModalHeader>
        {label && (
            <Heading level="h3" as="h2">{label}</Heading>
        )}
        <CloseButton
          placement="end"
          offset="medium"
          variant="icon"
          onClick={handleCloseClick}
        >
          {I18n.t('Close')}
        </CloseButton>
      </ModalHeader>
      {children}
    </Modal>
  )
}
InstuiModal.propTypes = {
  label: string,
  handleCloseClick: func.isRequired,
  children: node.isRequired
}
