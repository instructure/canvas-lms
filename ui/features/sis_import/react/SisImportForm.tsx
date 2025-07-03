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

import {Button} from '@instructure/ui-buttons'
import {FileDrop} from '@instructure/ui-file-drop'
import React, {useState, useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {IconUploadSolid} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Checkbox} from '@instructure/ui-checkbox'
import {SisImport} from 'api'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {ConfirmationModal} from './ConfirmationModal'
import FullBatchDropdown from './FullBatchDropdown'

const I18n = createI18nScope('sis_import')

interface Props {
  onSuccess: (data: SisImport) => void
}

export default function SisImportForm(props: Props) {
  const [message, setMessage] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [confirmed, setConfirmed] = useState(true)
  // form fields
  const [file, setFile] = useState<File | null>(null)
  const [fullChecked, setFullChecked] = useState(false)
  const [overrideChecked, setOverrideChecked] = useState(false)
  const [processChecked, setProcessChecked] = useState(false)
  const [clearChecked, setClearChecked] = useState(false)
  const [termId, setTermId] = useState('')

  const fileRef = useRef<HTMLInputElement | null>(null)

  const overrideSisText = I18n.t(
    "By default, UI changes have priority over SIS import changes; for a number of fields, the SIS import will not change that field's data if an admin has changed that field through the UI. If you select this option, this SIS import will override UI changes. See the documentation for details.",
  )
  const addSisText = I18n.t(
    'With this option selected, changes made through this SIS import will be processed as if they are UI changes, preventing subsequent non-overriding SIS imports from changing the fields changed here.',
  )
  const clearSisText = I18n.t(
    'With this option selected, all fields in all records touched by this SIS import will be able to be changed in future non-overriding SIS imports.',
  )

  useEffect(() => {
    if (submitting && confirmed) {
      handleSubmit()
    }
  }, [submitting, confirmed])

  const createFormData = () => {
    const formData = new FormData()
    formData.append('attachment', file as Blob)
    formData.append('batch_mode', fullChecked.toString())
    formData.append('override_sis_stickiness', overrideChecked.toString())
    if (overrideChecked) {
      formData.append('add_sis_stickiness', processChecked.toString())
      formData.append('clear_sis_stickiness', clearChecked.toString())
    }
    if (fullChecked) {
      formData.append('batch_mode_term_id', termId)
    }
    return formData
  }

  const startSisImport = async () => {
    const formData = createFormData()
    try {
      const {json} = await doFetchApi<SisImport>({
        path: `sis_imports`,
        method: 'POST',
        body: formData,
      })
      props.onSuccess(json as SisImport)
    } catch (e) {
      setSubmitting(false)
      showFlashError(I18n.t('Error starting SIS import'))(e as Error)
    }
  }

  const handleSubmit = async () => {
    if (validateFile()) {
      await startSisImport()
    }
    setSubmitting(false)
  }

  const validateFile = () => {
    if (file && message === '') {
      return true
    } else {
      setMessage(I18n.t('Please upload a CSV or ZIP file.'))
      fileRef.current?.focus()
      return false
    }
  }

  if (submitting && confirmed) {
    return <Spinner renderTitle={I18n.t('Starting SIS import')} />
  }

  return (
    <>
      <Flex id="sis_import_form" as="form" gap="medium" direction="column">
        <FileDrop
          inputRef={(ref: HTMLInputElement | null) => {
            fileRef.current = ref
          }}
          id="choose_a_file_to_import"
          data-testid="file_drop"
          name="attachment"
          onDropAccepted={(file: ArrayLike<File | DataTransferItem>) => {
            setMessage('')
            setFile(file[0] as File)
          }}
          onDropRejected={() => {
            setMessage(I18n.t('Invalid file type. Please upload a CSV or ZIP file.'))
            setFile(null)
          }}
          accept=".csv, .zip"
          renderLabel={
            <Flex padding="medium" direction="column" gap="x-small" alignItems="center">
              <IconUploadSolid size="medium" />
              <Flex gap="xx-small">
                <Text>{I18n.t('Choose a file to import')}</Text>
                <Text weight="bold" color={message === '' ? 'primary' : 'danger'}>
                  *
                </Text>
              </Flex>
              <Text size="small" fontStyle="italic">
                {file && !(file instanceof DataTransferItem) ? file.name : ''}
              </Text>
            </Flex>
          }
          messages={message === '' ? [] : [{text: message, type: 'newError'}]}
          width="24rem"
        />
        <Checkbox
          data-testid="batch_mode"
          id="batch_mode"
          checked={fullChecked}
          onChange={e => {
            setConfirmed(!e.target.checked)
            setFullChecked(e.target.checked)
          }}
          label={I18n.t('This is a full batch update')}
        />
        <FullBatchDropdown
          isVisible={fullChecked}
          onSelect={(termId: string) => setTermId(termId)}
          accountId={ENV.ACCOUNT_ID}
        />
        <Checkbox
          id="override_sis_stickiness"
          data-testid="override_sis_stickiness"
          checked={overrideChecked}
          onChange={e => setOverrideChecked(e.target.checked)}
          label={I18n.t('Override UI changes')}
        />
        <Text>{overrideSisText}</Text>
        {overrideChecked && (
          <Flex gap="medium" direction="column" margin="0 0 0 large">
            <Checkbox
              id="add_sis_stickiness"
              data-testid="add_sis_stickiness"
              onChange={e => {
                setProcessChecked(e.target.checked)
              }}
              disabled={clearChecked}
              checked={processChecked}
              label={I18n.t('Process as UI changes')}
            />
            <Text>{addSisText}</Text>
            <Checkbox
              id="clear_sis_stickiness"
              data-testid="clear_sis_stickiness"
              onChange={e => {
                setClearChecked(e.target.checked)
              }}
              disabled={processChecked}
              checked={clearChecked}
              label={I18n.t('Clear UI-changed state')}
            />
            <Text>{clearSisText}</Text>
          </Flex>
        )}
        <Flex.Item>
          <Button
            margin="x-small"
            type="submit"
            data-testid="submit_button"
            onClick={e => {
              e.preventDefault()
              if (validateFile()) {
                setSubmitting(true)
              }
            }}
            color="primary"
          >
            {I18n.t('Process Data')}
          </Button>
        </Flex.Item>
      </Flex>
      <ConfirmationModal
        isOpen={!confirmed && submitting}
        onSubmit={() => {
          setConfirmed(true)
        }}
        onRequestClose={() => {
          setSubmitting(false)
        }}
      />
    </>
  )
}
