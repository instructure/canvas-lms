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

import I18n from 'i18n!outcomes'
import React, {Component} from 'react'
import ReactDOM from 'react-dom'
import {func, shape, bool} from 'prop-types'
import Button from '@instructure/ui-buttons/lib/components/Button'

import Modal, { ModalBody, ModalFooter } from '../shared/components/InstuiModal'

const willUpdateRubrics = ({ changed, hasUpdateableRubrics }) => changed && hasUpdateableRubrics

const willUpdateScores = ({assessed, changed, modifiedFields}) => (
  changed && assessed && (
    modifiedFields.masteryPoints ||
    modifiedFields.scoringMethod
  )
)

export function showConfirmOutcomeEdit (props) {
  if (!willUpdateRubrics(props) && !willUpdateScores(props)) {
    setTimeout(props.onConfirm)
    return
  }
  const parent = document.createElement('div')
  parent.setAttribute('class', 'confirm-outcome-edit-modal-container')
  document.body.appendChild(parent)

  function showConfirmOutcomeEditRef (modal) {
    if (modal) modal.show()
  }

  ReactDOM.render(<ConfirmOutcomeEditModal {...props} parent={() => parent} ref={showConfirmOutcomeEditRef} />, parent)
}

export default class ConfirmOutcomeEditModal extends Component {
  static propTypes = {
    assessed: bool.isRequired,
    changed: bool.isRequired,
    hasUpdateableRubrics: bool.isRequired,
    modifiedFields: shape({
      masteryPoints: bool.isRequired,
      scoringMethod: bool.isRequired
    }).isRequired,
    onConfirm: func.isRequired,
    parent: func.isRequired,
  }

  state = {
    show: false,
  }

  onConfirm = () => {
    setTimeout(this.props.onConfirm)
    this.hide()
  }

  onCancel = () => {
    this.hide()
  }

  show () {
    this.setState({ show: true })
  }

  hide () {
    this.setState({ show: false },
      () => {
        const parent = this.props.parent ? this.props.parent() : null
        if (parent) ReactDOM.unmountComponentAtNode(parent)
      })
  }

  render () {
    const { assessed, changed, hasUpdateableRubrics, modifiedFields } = this.props
    return (
      <Modal
        label={I18n.t('Confirm Edit Outcome')}
        open={this.state.show}
        onDismiss={this.onCancel}
        size="small"
      >
        <ModalBody>
          <div>
            <ul>
              {
                willUpdateRubrics({ changed, hasUpdateableRubrics }) && (
                  <li>
                    {
                      I18n.t('This will update all rubrics using this outcome that have not yet been assessed')
                    }
                  </li>
                )
              }
              {
                willUpdateScores({ assessed, changed, modifiedFields }) && (
                  <li>
                    {
                      I18n.t('You’ve updated the scoring criteria; this will affect all students ' +
                             'previously assessed using this outcome')
                    }
                  </li>
                )
              }
            </ul>
          </div>
        </ModalBody>
        <ModalFooter>
          <Button
            onClick={this.onCancel}
            id='cancel-outcome-edit-modal'
          >{I18n.t('Cancel')}</Button>&nbsp;
          <Button
            onClick={this.onConfirm}
            id='confirm-outcome-edit-modal'
            variant="primary">{I18n.t('Save')}</Button>
        </ModalFooter>
      </Modal>
    )
  }
}
