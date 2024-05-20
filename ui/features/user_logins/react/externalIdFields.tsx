// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import ReactDOM, {createPortal} from 'react-dom'

interface PseudonymArgs {
  canEditSisUserId: boolean
  integrationId?: string
  sisUserId?: string
}

interface JQInterface {
  onCancel: () => void
  onEdit: (args?: PseudonymArgs) => void
  onAdd: (args?: PseudonymArgs) => void
}

declare global {
  interface Window {
    canvas_pseudonyms: {
      jqInterface: JQInterface
    }
  }
}

window.canvas_pseudonyms = {
  jqInterface: {
    onCancel() {},
    onEdit(_args?: PseudonymArgs) {},
    onAdd(_args?: PseudonymArgs) {},
  },
}

const ExternalIdField = ({currentValue, id, label, portalSelector}) => {
  const [value, setValue] = useState()
  useEffect(() => {
    if (currentValue) {
      setValue(currentValue)
    }
  }, [currentValue])
  function onTextChanged(event) {
    setValue(event.target.value)
  }
  const inputId = `pseudonym_${id}`

  return createPortal(
    <>
      <td>
        <label htmlFor={inputId}>{label}</label>
      </td>
      <td>
        <input
          id={inputId}
          name={`pseudonym[${id}]`}
          type="text"
          value={value || ''}
          onChange={onTextChanged}
        />
      </td>
    </>,
    document.querySelector(portalSelector)
  )
}

interface ExternalIdsProps {
  integrationIdLabel?: string
  sisUserIdLabel?: string
  jqInterface: JQInterface
}
const ExternalIds = ({integrationIdLabel, jqInterface, sisUserIdLabel}: ExternalIdsProps) => {
  const [canEditSisUserId, setCanEditSisUserId] = useState<boolean | undefined>(false)
  const [integrationId, setIntegrationId] = useState<string | undefined>()
  const [sisUserId, setSisUserId] = useState<string | undefined>()

  useEffect(() => {
    jqInterface.onAdd = args => {
      setCanEditSisUserId(args?.canEditSisUserId)
    }
    jqInterface.onEdit = args => {
      setCanEditSisUserId(args?.canEditSisUserId)
      setIntegrationId(args?.integrationId)
      setSisUserId(args?.sisUserId)
    }
    jqInterface.onCancel = () => {
      setIntegrationId(undefined)
      setSisUserId(undefined)
    }

    return () => {
      jqInterface.onAdd = () => {}
      jqInterface.onEdit = () => {}
      jqInterface.onCancel = () => {}
    }
  }, [jqInterface.onAdd, jqInterface.onCancel, jqInterface.onEdit])

  if (!canEditSisUserId) return <></>

  return (
    <>
      <ExternalIdField
        currentValue={sisUserId}
        id="sis_user_id"
        label={sisUserIdLabel}
        portalSelector='[data-external-placeholder="sis-user-id"]'
      />
      <ExternalIdField
        currentValue={integrationId}
        id="integration_id"
        label={integrationIdLabel}
        portalSelector='[data-external-placeholder="integration-id"]'
      />
    </>
  )
}

const sisUserIdEl = document.querySelector(
  '[data-external-placeholder="sis-user-id"]'
) as HTMLElement
const integrationIdEl = document.querySelector(
  '[data-external-placeholder="integration-id"]'
) as HTMLElement

ReactDOM.render(
  <ExternalIds
    jqInterface={window.canvas_pseudonyms.jqInterface}
    sisUserIdLabel={sisUserIdEl?.dataset?.label}
    integrationIdLabel={integrationIdEl?.dataset?.label}
  />,
  document.querySelector('[data-react-component="external-ids"]')
)
