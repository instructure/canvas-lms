/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'

const I18n = useI18nScope('quiz_statistics')

const UserListDialog = ({answer_id, user_names}) => {
  const [displayingDialog, displayDialog] = useState(false)

  return (
    <div>
      <button className="btn-link" type="button" onClick={() => displayDialog(true)}>
        {I18n.t(
          {
            one: '1 respondent',
            other: '%{count} respondents',
          },
          {count: user_names.length}
        )}
      </button>

      <CanvasModal
        open={displayingDialog}
        onDismiss={() => displayDialog(false)}
        label={I18n.t('user_names', 'User Names')}
      >
        <div key={'answer-users-' + answer_id} style={{width: 500}}>
          <ul className="answer-response-list">
            {user_names.map(x => (
              <li key={x}>{x}</li>
            ))}
          </ul>
        </div>
      </CanvasModal>
    </div>
  )
}

export default UserListDialog
