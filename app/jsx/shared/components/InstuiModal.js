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
import {string, node} from 'prop-types'
import Heading from '@instructure/ui-core/lib/components/Heading'
import I18n from 'i18n!modal'
import Modal, {ModalHeader} from '@instructure/ui-core/lib/components/Modal'

export {ModalBody, ModalFooter, ModalHeader} from '@instructure/ui-core/lib/components/Modal'

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
export default function InstuiModal ({label, children, ...otherPropsToPassOnToModal}) {
  return (
    <Modal {...otherPropsToPassOnToModal}
      label={label}
      closeButtonLabel={I18n.t('Close')}
      applicationElement={() => document.getElementById('application')}
    >
      {label && (
        <ModalHeader>
          <Heading>{label}</Heading>
        </ModalHeader>
      )}
      {children}
    </Modal>
  )
}
InstuiModal.propTypes = {
  label: string,
  children: node.isRequired
}
