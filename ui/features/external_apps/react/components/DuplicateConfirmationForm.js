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
import {func, object, string} from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('external_tools')

export default function DuplicateConfirmationForm(props) {
  const forceSaveTool =
    props.forceSaveTool ||
    (() => {
      const data = props.toolData
      data.verifyUniqueness = undefined
      props.store.save(props.configurationType, data, props.onSuccess, props.onError)
    })

  return (
    <div id="duplicate-confirmation-form">
      <div className="ReactModal__Body">
        <p>
          {I18n.t(
            'This tool has already been installed in this context. Would you like to install it anyway?'
          )}
        </p>
      </div>
      <div className="ReactModal__Footer">
        <div className="ReactModal__Footer-Actions">
          <Button
            id="cancel-install"
            color="primary"
            margin="0 x-small 0 0"
            onClick={props.onCancel}
          >
            {I18n.t('No, Cancel Installation')}
          </Button>
          <Button id="continue-install" onClick={forceSaveTool}>
            {I18n.t('Yes, Install Tool')}
          </Button>
        </div>
      </div>
    </div>
  )
}

DuplicateConfirmationForm.propTypes = {
  onCancel: func.isRequired,
  onSuccess: func.isRequired,
  onError: func.isRequired,
  forceSaveTool: func,
  toolData: object.isRequired,
  configurationType: string.isRequired,
  store: object.isRequired,
}
