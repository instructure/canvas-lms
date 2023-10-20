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
import {array, func, instanceOf} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {FileDrop} from '@instructure/ui-file-drop'
import {Billboard} from '@instructure/ui-billboard'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {PresentationContent} from '@instructure/ui-a11y-content'
import SVGWrapper from '@canvas/svg-wrapper'

const I18n = useI18nScope('ImportOutcomesModal')

export function showImportOutcomesModal(props) {
  const parent = document.createElement('div')
  parent.setAttribute('class', 'import-outcomes-modal-container')
  document.body.appendChild(parent)

  function showImportOutcomesRef(modal) {
    if (modal) modal.show()
  }

  ReactDOM.render(
    <ImportOutcomesModal {...props} parent={parent} ref={showImportOutcomesRef} />,
    parent
  )
}

export default class ImportOutcomesModal extends Component {
  static propTypes = {
    parent: instanceOf(Element),
    toolbar: instanceOf(Element),
    onFileDrop: func,
    learningOutcomeGroup: instanceOf(Object),
    learningOutcomeGroupAncestorIds: array,
  }

  static defaultProps = {
    parent: null,
  }

  state = {
    show: false,
    messages: [],
  }

  onCancel = () => {
    this.hide()
  }

  onSelection(accepted, rejected) {
    const {toolbar, onFileDrop, learningOutcomeGroup, learningOutcomeGroupAncestorIds} = this.props

    if (accepted.length > 0) {
      this.hide()
      if (toolbar) {
        toolbar.trigger('start_sync', accepted[0])
      } else if (onFileDrop) {
        // Warning! The 'id' was aliased as '_id', some layers
        // above, in useGroupDetail.js
        onFileDrop(accepted[0], learningOutcomeGroup?._id, learningOutcomeGroupAncestorIds)
      }
    } else if (rejected.length > 0) {
      this.setState({messages: [{text: I18n.t('Invalid file type'), type: 'error'}]})
    }
  }

  show() {
    this.setState({show: true})
  }

  hide() {
    this.setState({show: false}, () => {
      if (this.props.parent) ReactDOM.unmountComponentAtNode(this.props.parent)
    })
  }

  render() {
    const styles = {
      width: '10rem',
      margin: '0 auto',
    }
    return (
      <Modal
        open={this.state.show}
        onDismiss={this.onCancel}
        size="fullscreen"
        label={
          this.props.learningOutcomeGroup
            ? I18n.t('Import Outcomes to "%{groupName}"', {
                groupName: this.props.learningOutcomeGroup.title,
              })
            : I18n.t('Import Outcomes')
        }
      >
        <Modal.Body>
          <FileDrop
            accept=".csv, .json"
            onDrop={(acceptedFile, rejectedFile) => this.onSelection(acceptedFile, rejectedFile)}
            messages={this.state.messages}
            renderLabel={
              <div>
                <Billboard
                  size="medium"
                  heading={I18n.t('Upload your Outcomes!')}
                  headingLevel="h2"
                  message={I18n.t('Choose a file to upload from your device')}
                  hero={
                    <div style={styles}>
                      <PresentationContent>
                        <SVGWrapper url="/images/upload_rocket.svg" />
                      </PresentationContent>
                    </div>
                  }
                />
                <Text fontStyle="italic">{I18n.t('CSV or JSON formats only')}</Text>
              </div>
            }
          />
          <View as="div" margin="large auto" textAlign="center">
            <Link href="/doc/api/file.outcomes_csv.html">{I18n.t('Outcomes CSV Format')}</Link>
          </View>
        </Modal.Body>
      </Modal>
    )
  }
}
