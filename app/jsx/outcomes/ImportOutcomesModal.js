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

import React, {Component} from 'react'
import ReactDOM from 'react-dom'
import {instanceOf} from 'prop-types'
import I18n from 'i18n!outcomes'
import Modal, { ModalHeader, ModalBody } from '@instructure/ui-core/lib/components/Modal'
import Heading from '@instructure/ui-core/lib/components/Heading'
import FileDrop from '@instructure/ui-core/lib/components/FileDrop'
import Billboard from '@instructure/ui-core/lib/components/Billboard'
import Text from '@instructure/ui-core/lib/components/Text'
import Link from '@instructure/ui-core/lib/components/Link'
import Container from '@instructure/ui-core/lib/components/Container'
import PresentationContent from '@instructure/ui-core/lib/components/PresentationContent'
import SVGWrapper from '../shared/SVGWrapper'

export function showImportOutcomesModal (props) {
  const parent = document.createElement('div')
  parent.setAttribute('class', 'import-outcomes-modal-container')
  document.body.appendChild(parent)

  function showImportOutcomesRef (modal) {
    if (modal) modal.show()
  }

  ReactDOM.render(<ImportOutcomesModal {...props} parent={parent} ref={showImportOutcomesRef} />, parent)
}

export default class ImportOutcomesModal extends Component {
  static propTypes = {
    parent: instanceOf(Element),
    toolbar: instanceOf(Element).isRequired
  }

  static defaultProps = {
    parent: null
  }

  state = {
    show: false,
    messages: []
  }

  onCancel = () => {
    this.hide()
  }

  onSelection (accepted, rejected) {
    if (accepted.length > 0) {
      this.hide()
      this.props.toolbar.trigger('start_sync', accepted[0])
    } else if (rejected.length > 0) {
      this.setState({ messages: [{ text: I18n.t('Invalid file type'), type: 'error'}] })
    }
  }

  show () {
    this.setState({ show: true })
  }

  hide () {
    this.setState({ show: false },
      () => {
        if (this.props.parent) ReactDOM.unmountComponentAtNode(this.props.parent)
      })
  }

  render () {
    const styles = {
      width: '10rem',
      margin: '0 auto'
    }
    return (
      <Modal
        open={this.state.show}
        onDismiss={this.onCancel}
        size="fullscreen"
        label={I18n.t('Import Outcomes')}
        closeButtonLabel={I18n.t('Close')}
        applicationElement={() => document.getElementById('application')}
      >
        <ModalHeader>
          <Heading>{I18n.t('Import Outcomes')}</Heading>
        </ModalHeader>
        <ModalBody>
          <FileDrop
            accept=".csv, .json"
            onDrop={(acceptedFile, rejectedFile) =>
              this.onSelection(acceptedFile, rejectedFile)
            }
            messages={this.state.messages}
            label={
              <div>
                <Billboard
                  size="medium"
                  heading={I18n.t('Upload your Outcomes!')}
                  headingLevel='h2'
                  message={I18n.t('Drag and drop or click to browse your computer')}
                  hero={<div style={styles}><PresentationContent><SVGWrapper url="/images/upload_rocket.svg"/></PresentationContent></div>}
                />
                <Text fontStyle="italic">{I18n.t('CSV or JSON formats only')}</Text>
              </div>
            }
          />
          <Container as="div" margin="large auto" textAlign='center'>
            <Link href="/doc/api/file.outcomes_csv.html">{I18n.t('Outcomes CSV Format')}</Link>
          </Container>
        </ModalBody>
      </Modal>
    )
  }
}
