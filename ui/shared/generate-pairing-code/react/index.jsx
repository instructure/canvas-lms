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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {IconGroupLine} from '@instructure/ui-icons'
import {PresentationContent} from '@instructure/ui-a11y-content'
import axios from '@canvas/axios'
import {string} from 'prop-types'

const I18n = useI18nScope('generate_pairing_code')

export default class GeneratePairingCode extends Component {
  state = {
    pairingCode: '',
    showModal: false,
    gettingPairingCode: false,
    pairingCodeError: false,
  }

  openModal = () => {
    this.setState({showModal: true})
    this.generatePairingCode()
  }

  closeModal = () => {
    this.setState({showModal: false})
  }

  generatePairingCode = () => {
    this.setState({gettingPairingCode: true, pairingCodeError: false})
    axios
      .post(`/api/v1/users/${this.props.userId}/observer_pairing_codes`)
      .then(({data}) => {
        this.setState({
          gettingPairingCode: false,
          pairingCode: data.code,
        })
      })
      .catch(() => {
        this.setState({
          gettingPairingCode: false,
          pairingCodeError: true,
        })
      })
  }

  renderCloseButton = () => (
    <CloseButton
      placement="end"
      offset="medium"
      onClick={this.closeModal}
      screenReaderLabel="\n      Close\n    "
    />
  )

  renderPairingCode = () => {
    if (this.state.pairingCodeError) {
      return <Text color="danger">{I18n.t('There was an error generating the pairing code')}</Text>
    } else {
      return <Text>{this.state.pairingCode}</Text>
    }
  }

  render() {
    const messageWithName = I18n.t(
      `Share the following pairing code with an observer to allow
    them to connect with %{name}. This code will expire in seven days,
    or after one use.`,
      {name: this.props.name}
    )
    const messageWithoutName = I18n.t(`Share the following pairing code with an observer to allow
    them to connect with you. This code will expire in seven days,
    or after one use.`)
    return (
      <div>
        <Button onClick={this.openModal} display="block" textAlign="start">
          <IconGroupLine />
          {I18n.t('Pair with Observer')}
        </Button>
        <Modal
          open={this.state.showModal}
          onDismiss={this.closeModal}
          shouldCloseOnDocumentClick={true}
          label={I18n.t('Pair with Observer')}
          size="small"
        >
          <Modal.Header>
            {this.renderCloseButton()}
            <Heading>{I18n.t('Pair with Observer')}</Heading>
          </Modal.Header>
          <Modal.Body>
            <Text>{this.props.name ? messageWithName : messageWithoutName}</Text>
            <div className="pairing-code">
              {this.state.gettingPairingCode ? (
                <div>
                  <Spinner
                    margin="0 small 0 0"
                    size="x-small"
                    renderTitle={I18n.t('Generating pairing code')}
                  />
                  <PresentationContent>{I18n.t('Generating pairing code...')}</PresentationContent>
                </div>
              ) : (
                this.renderPairingCode()
              )}
            </div>
          </Modal.Body>
          <Modal.Footer>
            <Button onClick={this.closeModal} color="primary" className="pairing-code-ok">
              {I18n.t('OK')}
            </Button>
          </Modal.Footer>
        </Modal>
      </div>
    )
  }
}

GeneratePairingCode.propTypes = {
  userId: string.isRequired,
  name: string,
}
