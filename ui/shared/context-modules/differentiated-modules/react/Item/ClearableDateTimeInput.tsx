/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useContext, useEffect, useRef, useState} from 'react'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {AccessibleContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {CondensedButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import WithBreakpoints, {Breakpoints} from '@canvas/with-breakpoints'
import type {FormMessage} from '@instructure/ui-form-field'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'

const I18n = createI18nScope('differentiated_modules')

function useElementResize(
  onResize: (element: Element) => void,
): [(element: Element | null) => void] {
  const observer = useRef(
    new ResizeObserver(entries => entries.forEach(entry => onResize(entry.target))),
  )

  const listenElement = (element: Element | null) => {
    if (!element) return
    observer.current.observe(element)
  }

  useEffect(() => {
    // eslint-disable-next-line react-hooks/exhaustive-deps
    return () => observer.current.disconnect()
  }, [])

  return [listenElement]
}

export interface ClearableDateTimeInputProps {
  id?: string
  disabled?: boolean
  description: string
  dateRenderLabel: string
  value: string | null
  messages: Array<FormMessage>
  onChange: (event: React.SyntheticEvent, value: string | undefined) => void
  onBlur?: (event: React.SyntheticEvent) => void
  onClear: () => void
  breakpoints: Breakpoints
  showMessages?: boolean
  locale?: string
  timezone?: string
  dateInputRef?: (el: HTMLInputElement | null) => void
  timeInputRef?: (el: HTMLInputElement | null) => void
  clearButtonAltLabel: string
  setStatusMessage?: (message: string) => void
}

function ClearableDateTimeInput({
  id,
  disabled = false,
  description,
  dateRenderLabel,
  value,
  messages,
  onChange,
  onBlur,
  onClear,
  breakpoints,
  showMessages,
  locale,
  timezone,
  dateInputRef,
  timeInputRef,
  clearButtonAltLabel,
}: ClearableDateTimeInputProps) {
  const elementRef = useRef<Element | null>(null)
  const elementRefCallback = (element: Element | null) => {
    elementRef.current = element
    if (elementRef?.current) {
      // @ts-expect-error
      setHeight(elementRef.current.offsetHeight)
    }
  }

  const {setOnSuccess} = useContext(AlertManagerContext)

  const [height, setHeight] = useState(0)

  const [hasErrorBorder, setHasErrorBorder] = useState(false)
  const clearButtonContainer = useRef<HTMLElement | null>()

  const handleResize = useCallback((element: Element) => {
    // Selector for the date time input that is affected by the red border and padding
    const container = element.querySelector('fieldset > span > span:first-child > span > span')
    if (!container) return
    // If padding is cero means that the error border does not exist
    setHasErrorBorder(getComputedStyle(container).padding !== '0px')
  }, [])

  // We used this instead of checking messages since we can't control internal error messages
  const [listenElement] = useElementResize(handleResize)

  useEffect(() => {
    if (!clearButtonContainer.current) return
    if (height > 0) {
      // labels + labels margins + 0.5rem (padding when the date time input has errors)
      clearButtonContainer.current.style.paddingTop = hasErrorBorder
        ? `${1.5 + height / 16}rem`
        : `${1 + height / 16}rem`
    }
  }, [hasErrorBorder, height])
  const renderDateLabel = <Text elementRef={elementRefCallback}>{dateRenderLabel}</Text>

  const renderTimeLabel = (
    <Flex as="div" height={height - 2} direction="column" justifyItems="end">
      {I18n.t('Time')}
    </Flex>
  )

  const handleClear = () => {
    onClear()
    setTimeout(() => {
      setOnSuccess(I18n.t('Cleared successfully'))
    }, 500)
  }

  return (
    <Flex
      data-testid="clearable-date-time-input"
      as="div"
      display="flex"
      padding="small none"
      alignItems="start"
      elementRef={listenElement}
    >
      <Flex.Item
        direction={breakpoints?.mobileOnly ? 'column' : 'row'}
        data-testid={`${id}_input`}
        shouldShrink={true}
        shouldGrow={true}
      >
        <DateTimeInput
          allowNonStepInput={true}
          colSpacing="small"
          dateFormat="ll"
          description={<ScreenReaderContent>{description}</ScreenReaderContent>}
          dateRenderLabel={renderDateLabel}
          timeRenderLabel={renderTimeLabel}
          invalidDateTimeMessage={I18n.t('Invalid date')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          value={value ?? undefined}
          layout="columns"
          messages={messages}
          showMessages={showMessages}
          locale={locale}
          timezone={timezone}
          onChange={onChange}
          onBlur={onBlur}
          dateInputRef={dateInputRef}
          timeInputRef={timeInputRef}
          interaction={disabled ? 'disabled' : 'enabled'}
        />
      </Flex.Item>

      <Flex.Item
        margin="0 0 0 small"
        elementRef={e => (clearButtonContainer.current = e as HTMLElement)}
      >
        <CondensedButton interaction={disabled ? 'disabled' : 'enabled'} onClick={handleClear}>
          <AccessibleContent alt={clearButtonAltLabel}>{I18n.t('Clear')}</AccessibleContent>
        </CondensedButton>
      </Flex.Item>
    </Flex>
  )
}
export default WithBreakpoints(ClearableDateTimeInput)
