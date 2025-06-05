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
import {View} from '@instructure/ui-view'
import {Checkbox} from '@instructure/ui-checkbox'
import {Alert} from '@instructure/ui-alerts'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useInfiniteQuery, type QueryFunctionContext} from '@tanstack/react-query'
import {EnrollmentTerms, SisImport, Term} from 'api'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {ConfirmationModal} from './ConfirmationModal'
import {Select} from '@instructure/ui-select'

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

  const fullBatchWarning = I18n.t(
    'If selected, this will delete everything for this term, which includes all courses and enrollments that are not in the selected import file above. See the documentation for details.',
  )
  const overrideSisText = I18n.t(
    "By default, UI changes have priority over SIS import changes; for a number of fields, the SIS import will not change that field's data if an admin has changed that field through the UI. If you select this option, this SIS import will override UI changes. See the documentation for details.",
  )
  const addSisText = I18n.t(
    'With this option selected, changes made through this SIS import will be processed as if they are UI changes, preventing subsequent non-overriding SIS imports from changing the fields changed here.',
  )
  const clearSisText = I18n.t(
    'With this option selected, all fields in all records touched by this SIS import will be able to be changed in future non-overriding SIS imports.',
  )

  const observerRef = useRef<IntersectionObserver | null>(null)

  const accountId = ENV.ACCOUNT_ID

  const fetchTerms = async ({
    pageParam = '1',
  }: QueryFunctionContext): Promise<{json: EnrollmentTerms; nextPage: string | null}> => {
    const params = {
      per_page: 100,
      page: String(pageParam),
    }
    const {json, link} = await doFetchApi<EnrollmentTerms>({
      path: `/api/v1/accounts/${accountId}/terms`,
      params,
    })
    const nextPage = link?.next ? link.next.page : null
    return {json: json || {enrollment_terms: []}, nextPage: nextPage}
  }

  const {data, fetchNextPage, isFetching, hasNextPage, error} = useInfiniteQuery({
    queryKey: ['terms_list', accountId],
    queryFn: fetchTerms,
    getNextPageParam: lastPage => lastPage.nextPage,
    initialPageParam: '1',
  })

  useEffect(() => {
    if (submitting && confirmed) {
      handleSubmit()
    }
  }, [submitting, confirmed])

  useEffect(() => {
    if (data && data.pages.length === 1 && termId === '') {
      // set first term as default
      setTermId(data.pages[0].json.enrollment_terms[0].id as string)
    }
  }, [data])

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

  const renderObserver = () => {
    return isFetching ? (
      // (Simple)Select.Option's ref property has a parameter type of
      // Option | null, so we cannot use a ref callback directly here.
      // Instead, we use a span with a ref to trigger the IntersectionObserver.
      // Additionally, we are using Select.Option instead of SimpleSelect.Option here
      // because SimpleSelect.Option does not support ReactNode children.
      <Select.Option id="loading" disabled={true} value="loading">
        <Spinner size="small" renderTitle={I18n.t('Loading more terms')} />
      </Select.Option>
    ) : (
      <Select.Option id="observer" disabled={true} value="observer">
        <span ref={ref => setPageLoadTrigger(ref)} />
      </Select.Option>
    )
  }

  const renderSelect = (terms: Term[]) => {
    if (error) {
      return <Alert variant="error">{I18n.t('Error loading terms')}</Alert>
    } else if (isFetching && !terms) {
      return <Spinner renderTitle={I18n.t('Loading terms')} />
    } else {
      return (
        <View margin="0 0 0 medium">
          <Alert variant="warning" margin="small">
            {fullBatchWarning}
          </Alert>
          <SimpleSelect
            data-testid="term_select"
            width="30rem"
            renderLabel={I18n.t('Term')}
            onChange={(_, {value}) => setTermId(value as string)}
          >
            {terms.map(term => (
              <SimpleSelect.Option key={term.id} id={term.id} value={term.id}>
                {term.name}
              </SimpleSelect.Option>
            ))}
            {hasNextPage ? renderObserver() : null}
          </SimpleSelect>
        </View>
      )
    }
  }

  function clearPageLoadTrigger() {
    if (observerRef.current === null) return
    observerRef.current.disconnect()
    observerRef.current = null
  }

  function setPageLoadTrigger(ref: Element | null) {
    if (ref === null || !hasNextPage) return
    clearPageLoadTrigger()
    observerRef.current = new IntersectionObserver(function (entries) {
      if (entries[0].isIntersecting) {
        fetchNextPage()
        clearPageLoadTrigger()
      }
    })
    observerRef.current.observe(ref)
  }

  if (submitting && confirmed) {
    return <Spinner renderTitle={I18n.t('Starting SIS import')} />
  }
  const terms = data?.pages.reduce((acc: Term[], page) => {
    return acc.concat(page.json.enrollment_terms)
  }, [] as Term[])

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
        {fullChecked && terms ? renderSelect(terms) : null}
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
