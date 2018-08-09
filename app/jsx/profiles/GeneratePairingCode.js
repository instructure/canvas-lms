/*
 * Copyright (C) 2018 - present Instructure, Inc.
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


import I18n from 'i18n!generate_pairing_code'
import React, { Component } from 'react'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Modal, { ModalHeader, ModalBody, ModalFooter } from '@instructure/ui-overlays/lib/components/Modal'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Text from '@instructure/ui-elements/lib/components/Text'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import IconGroup from '@instructure/ui-icons/lib/Line/IconGroup'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import PresentationContent from '@instructure/ui-a11y/lib/components/PresentationContent'
import {post} from 'axios'
import {string} from 'prop-types'

export default class GeneratePairingCode extends Component {

  state = {
    pairingCode: '',
    showModal: false,
    gettingPairingCode: false,
    pairingCodeError: false
  }

  openModal = () => {
    this.setState({ showModal: true })
    this.generatePairingCode()
  }

  closeModal = () => {
    this.setState({ showModal: false })
  }

  generatePairingCode = () => {
    this.setState({ gettingPairingCode: true, pairingCodeError: false })
    post(`/api/v1/users/${this.props.userId}/observer_pairing_codes`)
      .then(({ data }) => {
        this.setState({
          gettingPairingCode: false,
          pairingCode: data.code
        })
      })
      .catch(() => {
        this.setState({
          gettingPairingCode: false,
          pairingCodeError: true
        })
      })
  }

  renderCloseButton = () => (
    <CloseButton
      placement='end'
      offset='medium'
      variant='icon'
      onClick={this.closeModal}
    >
      Close
    </CloseButton>
  )

  renderPairingCode = () => {
    if (this.state.pairingCodeError) {
      return <Text color='error'>{I18n.t('There was an error generating the pairing code')}</Text>
    } else {
      return <Text>{this.state.pairingCode}</Text>
    }
  }

  render () {
    const messageWithName = I18n.t(`Share the following pairing code with an observer to allow
    them to connect with %{name}. This code will expire in seven days,
    or after one use.`, { name: this.props.name })
    const messageWithoutName = I18n.t(`Share the following pairing code with an observer to allow
    them to connect with you. This code will expire in seven days,
    or after one use.`)
    return (
      <div>
        <Button fluidWidth onClick={this.openModal}>
          <IconGroup />
          {I18n.t('Pair with Observer')}
        </Button>
        <Modal
          open={this.state.showModal}
          onDismiss={this.closeModal}
          shouldCloseOnDocumentClick
          label={I18n.t('Pair with Observer')}
          size='small'
        >
          <ModalHeader>
            {this.renderCloseButton()}
            <Heading>{I18n.t('Pair with Observer')}</Heading>
          </ModalHeader>
          <ModalBody>
            <Text>
              {this.props.name
                ? messageWithName
                : messageWithoutName
              }
            </Text>
            <div className='pairing-code'>
              {this.state.gettingPairingCode
                ? <div>
                    <Spinner margin='0 small 0 0' size='x-small' title={I18n.t('Generating pairing code')} />
                    <PresentationContent>
                      {I18n.t('Generating pairing code...')}
                    </PresentationContent>
                  </div>
                : this.renderPairingCode()
              }
            </div>
          </ModalBody>
          <ModalFooter>
            <Button onClick={this.closeModal} variant="primary" className='pairing-code-ok'>{I18n.t('OK')}</Button>
          </ModalFooter>
        </Modal>
      </div>
    )
  }
}

GeneratePairingCode.propTypes = {
  userId: string.isRequired,
  name: string
}