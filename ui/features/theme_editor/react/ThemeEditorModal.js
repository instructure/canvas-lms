/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import React from 'react'
import PropTypes from 'prop-types'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import ProgressBar from '@canvas/progress/react/components/ProgressBar'

const I18n = useI18nScope('theme_editor')

const messageToName = message =>
  message.includes('Syncing for') ? message.replace('Syncing for ', '') : message

function SubAccountProgressBar({message, completion}) {
  return (
    <li className="Theme-editor-progress-list-item">
      <div className="Theme-editor-progress-list-item__title">{messageToName(message)}</div>
      <div className="Theme-editor-progress-list-item__bar">
        <ProgressBar
          progress={completion}
          title={I18n.t('Progress for %{account_name}', {
            account_name: messageToName(message),
          })}
        />
      </div>
    </li>
  )
}
SubAccountProgressBar.propTypes = {
  message: PropTypes.string,
  completion: ProgressBar.propTypes.completion,
}

export default function ThemeEditorModal(props) {
  const modalIsOpen = props.showProgressModal || props.showSubAccountProgress

  return (
    <Modal open={modalIsOpen} size={props.showProgressModal ? 'small' : 'medium'}>
      <Modal.Header>
        <Heading>
          {props.showProgressModal
            ? I18n.t('Generating preview...')
            : I18n.t('Applying new styles to subaccounts')}{' '}
        </Heading>
      </Modal.Header>
      <Modal.Body>
        {props.showProgressModal ? (
          <ProgressBar
            progress={props.progress}
            title={I18n.t('%{percent} complete', {
              percent: I18n.toPercentage(props.progress, {
                precision: 0,
              }),
            })}
          />
        ) : (
          <div>
            <p>{I18n.t('Changes will still apply if you leave this page.')}</p>
            <ul className="unstyled_list">
              {props.activeSubAccountProgresses.map(progressData => (
                <SubAccountProgressBar {...progressData} />
              ))}
            </ul>
          </div>
        )}
      </Modal.Body>
    </Modal>
  )
}

ThemeEditorModal.propTypes = {
  showProgressModal: PropTypes.bool,
  showSubAccountProgress: PropTypes.bool,
  progress: PropTypes.number,
  activeSubAccountProgresses: PropTypes.arrayOf(PropTypes.shape(SubAccountProgressBar.propTypes)),
}
