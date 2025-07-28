/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {TextInput} from '@instructure/ui-text-input'
import React, {useState, useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import type {AccountWithCounts} from './types'
import {calculateIndent} from './util'
import {Account} from 'api'

const I18n = createI18nScope('sub_accounts')

interface Props {
  accountName: string
  accountId: string
  depth?: number
  onSuccess: (json: AccountWithCounts) => void
  onCancel: () => void
}

export default function SubaccountNameForm(props: Props) {
  const isNew = props.accountName === ''
  const [name, setName] = useState(isNew ? '' : props.accountName)
  const [validation, setValidation] = useState('')
  const [isSaving, setIsSaving] = useState(false)
  const textRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (textRef.current) {
      textRef.current.focus()
    }
  }, [textRef])

  const handleChange = (value: string) => {
    setName(value)
    if (value === '') {
      setValidation(I18n.t('Name is required'))
    } else {
      setValidation('')
    }
  }

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSaving(true)
    try {
      if (name === '') {
        setValidation(I18n.t('Name is required'))
        textRef.current?.focus()
      } else {
        let json = null
        if (props.accountName != '') {
          json = await updateName()
        } else {
          json = await createSubaccount()
        }
        props.onSuccess(json)
      }
    } catch (_e) {
      showFlashError(I18n.t('There was an error saving the account.'))()
    }
    setIsSaving(false)
  }

  const updateName = async (): Promise<AccountWithCounts> => {
    const {json} = await doFetchApi<{account: Account}>({
      path: `/accounts/${props.accountId}`,
      body: {
        account: {
          name: name,
        },
      },
      method: 'PUT',
    })
    return {...json!.account, sub_account_count: 0, course_count: 0}
  }

  const createSubaccount = async (): Promise<AccountWithCounts> => {
    const {json} = await doFetchApi<AccountWithCounts>({
      path: `/accounts/${props.accountId}/sub_accounts`,
      method: 'POST',
      body: {
        account: {
          name: name,
        },
      },
    })
    return {...json!, sub_account_count: 0, course_count: 0}
  }

  const indent = props.depth ? calculateIndent(props.depth) : undefined
  if (isSaving) {
    return (
      <Flex margin="small 0">
        {indent ? <Flex.Item width={`${indent}%`} /> : null}
        <Spinner size="small" renderTitle={I18n.t('Saving account')} />
      </Flex>
    )
  }
  return (
    <Flex
      as="form"
      alignItems="start"
      onSubmit={e => handleSave(e)}
      noValidate={true}
      gap="small"
      margin="small 0"
    >
      {indent ? <Flex.Item width={`${indent}%`} /> : null}
      <TextInput
        placeholder={I18n.t('Enter a name')}
        elementRef={(ref: Element | null) => {
          if (ref) {
            textRef.current = ref as HTMLInputElement
          }
        }}
        isRequired={true}
        renderLabel={
          props.accountName === '' ? I18n.t('Add a Sub-Account') : I18n.t('Edit Sub-Account')
        }
        onChange={(_e, value) => handleChange(value)}
        width={indent ? `${80 - indent}%` : ''}
        value={name}
        messages={validation === '' ? [] : [{text: validation, type: 'newError'}]}
        data-testid="account-name-input"
      />
      <Flex gap="small" width="20%" margin="medium 0 0 0" padding="xx-small 0 0 0">
        <Button onClick={props.onCancel} data-testid="cancel-button">
          {I18n.t('Cancel')}
        </Button>
        <Button type="submit" color="primary" data-testid="save-button">
          {props.accountName === '' ? I18n.t('Save') : I18n.t('Update')}
        </Button>
      </Flex>
    </Flex>
  )
}
