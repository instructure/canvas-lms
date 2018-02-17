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

import Modal, {ModalHeader, ModalBody} from '@instructure/ui-core/lib/components/Modal'
import $ from 'jquery'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Link from '@instructure/ui-core/lib/components/Link'
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!terms_of_service_modal'
import RichContentEditor from './rce/RichContentEditor'

const { bool } = PropTypes
const termsOfServiceText = I18n.t('Acceptable Use Policy')

export default class TermsOfServiceModal extends React.Component {
  static propTypes = {
    preview: bool,
  }

  static defaultProps = {
    preview: false
  }


  state = {
    open: false,
  }

  handleCloseModal = () => {
    this.link.focus()
    this.setState({ open: false })
  }

  handleLinkClick = () => {
    const $rce_container = $('#custom_tos_rce_container')
    if ($rce_container.length > 0) {
      const $textarea = $rce_container.find('textarea');
      ENV.TERMS_OF_SERVICE_CUSTOM_CONTENT = RichContentEditor.callOnRCE($textarea, 'get_code')
    }
    this.setState((state) => ({ open: !state.open }))
  }

  render() {
    return (
      <span id="terms_of_service_modal">
       <Link ref={(c) => { this.link = c; }} onClick={this.handleLinkClick}>
         {this.props.preview ? I18n.t('Preview') : termsOfServiceText}
       </Link>
       <Modal
         open={this.state.open}
         onDismiss={this.handleCloseModal}
         size="fullscreen"
         label={termsOfServiceText}
         shouldCloseOnOverlayClick
         closeButtonLabel={I18n.t('Close')}
         applicationElement={() => [document.getElementById('main')] }
       >
         <ModalHeader>
           <Heading>{termsOfServiceText}</Heading>
         </ModalHeader>
         <ModalBody>
           <div dangerouslySetInnerHTML={{__html: ENV.TERMS_OF_SERVICE_CUSTOM_CONTENT}} />
         </ModalBody>
       </Modal>
      </span>
    )
  }
}
