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

import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useEffect, useRef, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Portal} from '@instructure/ui-portal'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import $ from 'jquery'

const I18n = createI18nScope('account_reports')

interface Props {
  formHTML: string
  path: string
  reportName: string
  closeModal: () => void
  onSuccess: (reportName: string) => void
}

const getParameterName = (name: string) => {
  const match = name.match(/parameters\[(.*)\]/)
  if (match) {
    return match[1]
  }
  return name
}

const wrapParameterName = (name: string) => {
  return `parameters[${name}]`
}

const getElementValue = (element: Element) => {
  let value
  const type = element.getAttribute('type')
  if (type === 'checkbox') {
    value = (element as HTMLInputElement).checked ? '1' : null
  } else if (type === 'radio') {
    if ((element as HTMLInputElement).checked) {
      value = (element as HTMLInputElement).value
    } else {
      value = null
    }
  } else {
    value = (element as HTMLInputElement).value
  }
  return value
}

const getFormData = (form: HTMLDivElement) => {
  // get all the form elements
  const formElements = form.querySelectorAll<HTMLInputElement>('input, select, textarea')
  const formArray = Array.from(formElements)
  const formData = new FormData()
  formArray.forEach(element => {
    const name = element.getAttribute('name')
      ? element.getAttribute('name')
      : element.dataset.testid
    const value = getElementValue(element)
    if (name && value !== null) {
      formData.append(name, value)
    }
  }, {})
  return formData
}

export default function ConfigureReportForm(props: Props) {
  const formRef = useRef<HTMLDivElement | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [dateRefs, setDateRefs] = useState<Record<string, [string, HTMLElement]>>({})
  const [dateValues, setDateValues] = useState<Record<string, string>>({})

  useEffect(() => {
    if (formRef.current) {
      const $form = $(formRef.current)
      const record = dateRefs

      // Find all datetime inputs and remove the closest <tr>
      $form.find('input.datetime_field').each(function () {
        const closestTd = $(this).closest('td')[0]
        // delete html content but store label
        const inputLabel = closestTd.innerText
        closestTd.innerHTML = ''

        const name = getParameterName($(this).attr('name') ?? '')
        record[name] = [inputLabel, closestTd]
      })
      setDateRefs({...record})

      const script = $form.find('script')
      if (script) {
        // there's only one script tag in each form
        const scriptElem = script.get(0)
        const newScript = document.createElement('script')
        if (scriptElem?.src) {
          newScript.src = scriptElem.src
        } else {
          newScript.textContent = script.text()
        }
        if (scriptElem) {
          Array.from(scriptElem.attributes).forEach(attr =>
            newScript.setAttribute(attr.name, attr.value),
          )
        }
        // replacing the script with a "new" script makes the script run
        script.replaceWith(newScript)
      }
    }
    // don't run this effect when dateRefs change; causes looping
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props])

  const onSubmit = async () => {
    setIsLoading(true)
    if (formRef.current) {
      const formData = getFormData(formRef.current)
      if (dateRefs != null) {
        Object.entries(dateRefs).forEach(pair => {
          const dateKey = wrapParameterName(pair[0])
          if (pair[0]) {
            formData.set(dateKey, dateValues[pair[0]] ?? '')
          }
        })
      }
      try {
        await doFetchApi({
          path: props.path,
          body: formData,
          method: 'POST',
        })
        props.onSuccess(props.reportName)
        props.closeModal()
      } catch (e) {
        showFlashError(I18n.t('Failed to start report.'))(e as Error)
        setIsLoading(false)
      }
    }
  }

  const renderContent = () => {
    if (isLoading) {
      return (
        <Modal.Body>
          <View margin="small auto" as="div" textAlign="center">
            <Spinner renderTitle={I18n.t('Starting report')} />
          </View>
        </Modal.Body>
      )
    }
    return (
      <Modal.Body padding="medium">
        <div
          id="configure_modal_body"
          ref={formRef}
          dangerouslySetInnerHTML={{__html: props.formHTML}}
        ></div>

        {Object.entries(dateRefs).map(pair => {
          const dateKey = pair[0]
          const dateLabel = pair[1][0]
          const dateNode = pair[1][1]
          return (
            <Portal open mountNode={dateNode} key={dateKey}>
              <DateTimeInput
                layout="columns"
                dateInputRef={dateInputRef => {
                  dateInputRef?.setAttribute('data-testid', wrapParameterName(dateKey))
                }}
                onChange={(_, isoValue) => {
                  const record = dateValues
                  if (isoValue) {
                    record[dateKey] = isoValue
                    setDateValues({...record})
                  }
                }}
                description={<ScreenReaderContent>{dateLabel}</ScreenReaderContent>}
                dateRenderLabel={dateLabel}
                prevMonthLabel={I18n.t('Previous month')}
                nextMonthLabel={I18n.t('Next month')}
                timeRenderLabel={I18n.t('Time')}
                invalidDateTimeMessage={I18n.t('Invalid date and time.')}
                timezone={ENV.TIMEZONE}
                locale={ENV.LOCALE}
              />
              <br />
            </Portal>
          )
        })}
      </Modal.Body>
    )
  }
  return (
    <Modal label={I18n.t('Configure Report')} open>
      <Modal.Header>
        <Heading>{I18n.t('Configure Report')}</Heading>
        <CloseButton
          data-testid="close-button"
          placement="end"
          size="medium"
          onClick={() => {
            if (formRef.current) {
              props.closeModal()
            }
          }}
          screenReaderLabel={I18n.t('Close')}
        />
      </Modal.Header>
      {renderContent()}
      <Modal.Footer>
        <Button data-testid="run-report" disabled={isLoading} color="primary" onClick={onSubmit}>
          {I18n.t('Run Report')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
