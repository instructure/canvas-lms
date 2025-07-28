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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {IconCompleteLine, IconEmptyLine} from '@instructure/ui-icons'
import React, {useState} from 'react'
import {SET_MODULE_ITEM_COMPLETION} from '@canvas/assignments/graphql/student/Mutations'
import {useMutation} from '@apollo/client'

const I18n = createI18nScope('assignments_2_file_upload')

interface MarkAsDoneButtonProps {
  done: boolean
  itemId: string
  moduleId: string
  onError?: () => void
  onToggle?: () => void
}

function MarkAsDoneButton({
  done: initialDone,
  itemId,
  moduleId,
  onError = () => {},
  onToggle = () => {},
}: MarkAsDoneButtonProps) {
  const [done, setDone] = useState(initialDone)
  const [setItemCompletion] = useMutation(SET_MODULE_ITEM_COMPLETION, {
    onCompleted: () => {
      setDone(!done)
      onToggle()
    },
    onError: () => {
      onError()
    },
    variables: {
      done: !done,
      itemId,
      moduleId,
    },
  })

  return (
    <Button
      color={done ? 'success' : 'secondary'}
      data-testid="set-module-item-completion-button"
      id="set-module-item-completion-button"
      onClick={() => setItemCompletion()}
      renderIcon={done ? <IconCompleteLine /> : <IconEmptyLine />}
    >
      {done ? I18n.t('Done') : I18n.t('Mark as done')}
    </Button>
  )
}

export default MarkAsDoneButton
