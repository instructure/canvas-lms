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

import React, {useState, useEffect, useMemo, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconAddLine, IconInfoLine, IconTrashLine} from '@instructure/ui-icons'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Portal} from '@instructure/ui-portal'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {TextInput, type TextInputProps} from '@instructure/ui-text-input'
const I18n = createI18nScope('account_settings')

// Why isn't this utility type a part of TypeScript? It's so useful!
type MakeRequired<T, K extends keyof T> = Omit<T, K> & Required<Pick<T, K>>

// Given an array of elements, sort them by their vertical position
function sortByVerticalPosition(elts: HTMLElement[]): HTMLElement[] {
  return elts
    .filter(elt => typeof elt !== 'undefined')
    .map(elt => ({elt, rect: elt.getBoundingClientRect()}))
    .sort((a, b) => a.rect.top - b.rect.top)
    .map(item => item.elt)
}

// Assign an index to each filter so we can track them. Note that this
// overwrites any index values coming in from the props, but they should
// not be present from the Rails view anyway.
function assignIndexes(filters: IPFilterSpec[]): MakeRequired<IPFilterSpec, 'index'>[] {
  return filters.map((filter, index) => ({...filter, index}))
}

function TipText(): JSX.Element {
  return (
    <View as="div" width="24rem">
      <p>
        {I18n.t(
          'Quiz IP filters are a way to limit access to quizzes to computers in a specified IP range.',
        )}
      </p>
      <p>
        {I18n.t(
          `Specify a set of IP address filters that teachers can use to protect access to quizzes.
            Filters can be a comma-separated list of addresses, or an address followed by a mask
            ("%{example1}" or "%{example2}").`,
          {example1: '192.168.217.1/24', example2: '192.168.217.1/255.255.255.0'},
        )}
      </p>
    </View>
  )
}

function LegendHelpTip(): JSX.Element {
  return (
    <Tooltip renderTip={<TipText />} on={['hover', 'focus', 'click']}>
      <IconButton
        renderIcon={IconInfoLine}
        size="small"
        withBorder={false}
        withBackground={false}
        screenReaderLabel={I18n.t('Toggle IP filter help')}
        data-testid="ip-filter-help-toggle"
      />
    </Tooltip>
  )
}

export type IPFilterSpec = {
  name: string
  filter: string
  index?: number
}
export interface QuizIPFiltersProps {
  parentNodeId: string
  filters: IPFilterSpec[]
}

type ErrorState = 'no' | 'yes' | 'force'
type ErrorMap = Record<string, ErrorState>
type Message = Required<TextInputProps>['messages'][0]

// This is a bit naughty, but we need to add a property to an HTML element
// in order to hang our validating function on it.
export type ElementWithValidator = null | (Element & {__performValidation?: () => boolean})

export default function QuizIPFilters({
  parentNodeId,
  filters: initialFilters,
}: QuizIPFiltersProps): JSX.Element {
  const [filters, setFilters] = useState(assignIndexes(initialFilters))
  const filterElements = useRef<Record<string, HTMLInputElement>>({})
  const [idsWithErrors, setIdsWithErrors] = useState<ErrorMap>({})
  const [isSubmitting, setIsSubmitting] = useState(false)

  const explainerMountPoint = useMemo(
    () => document.getElementById('ip_filter_explainer_portal'),
    [],
  )

  // Must look at the value of DOM element itself and not the filters
  // state variable, because it will need to be accessed from outside
  // the component (see formValidator() below).
  function validateElement(elt: HTMLInputElement, force: boolean = false): ErrorState {
    const errValue = force ? 'force' : 'yes'
    if (elt === null) return errValue
    return elt.value.length > 0 ? 'no' : errValue
  }

  function elementsWithErrors(elements: Record<string, HTMLInputElement>): HTMLElement[] {
    const curErrors: ErrorMap = {}
    const erroredElements: HTMLElement[] = []
    Object.entries(elements).forEach(([key, elt]) => {
      curErrors[key] = validateElement(elt)
      if (curErrors[key] !== 'no') erroredElements.push(elt as HTMLElement)
    })
    setIdsWithErrors(curErrors)
    return erroredElements
  }

  // This is an external trigger that the outer form's submit action
  // will call to validate the filters we're managing here. If there
  // are any errored elements, focus on the first one.
  // NOTE WELL!!  Since this function is a closure called from outside
  // our component, it will not have access to the current state! So we
  // have to be careful here to operate only on ref contents (since they
  // are mutable) and on DOM elements that we can look up. Trying to
  // access component state would just return the initial states forever.
  //
  // If the inputs all validate okay, this also adds the hidden form fields
  // that will be submitted. The "real" ones in this UI don't have name
  // attributes so will not be a part of the FormData.
  function formValidator(): boolean {
    const filters = filterElements.current
    const errors = elementsWithErrors(filters)
    setIsSubmitting(true)
    if (errors.length > 0) {
      sortByVerticalPosition(errors)[0].focus()
      return false
    }

    // build the hidden named form fields that we actually submit with
    // the form. These are the actual filters that will be saved.
    const hiddenFields = document.getElementById('account_settings_quiz_ip_filters_data')
    if (hiddenFields === null) throw new Error('No hidden fields for filter submission')
    hiddenFields.replaceChildren()

    // if there are no filters, we need to add a hidden field to tell Rails to
    // remove any existing ones. Otherwise the lack of any filters in the form
    // will act like a no-op.
    const fieldNames = Object.keys(filters)
    if (fieldNames.length === 0) {
      const removeFilters = document.createElement('input')
      removeFilters.type = 'hidden'
      removeFilters.name = 'account[remove_ip_filters]'
      removeFilters.value = '1'
      hiddenFields.appendChild(removeFilters)
      return true
    }

    // Otherwise, we need to add the hidden filter fields to the form
    const fieldIndexes = fieldNames
      .map(key => key.match(/^name_(\d+)$/))
      .filter(match => match)
      .map(match => match![1])
    fieldIndexes.forEach(i => {
      const name = filters[`name_${i}`].value.trim().replace(/\[|\]+/g, '_')
      const value = filters[`filter_${i}`].value.trim()

      const nameField = document.createElement('input')
      nameField.type = 'hidden'
      nameField.name = `account[ip_filters][${name}]`
      nameField.value = value
      hiddenFields.appendChild(nameField)
    })
    return true
  }

  function fieldMessages(fieldName: string): Message[] | undefined {
    const fieldError: Message = {text: I18n.t('This field is required'), type: 'newError'}
    if (idsWithErrors[fieldName] === 'force') return [fieldError]
    if (isSubmitting && idsWithErrors[fieldName] === 'yes') return [fieldError]
    return undefined
  }

  function handleFieldChange(value: string, filter: ['name' | 'filter', number]): void {
    const [key, index] = filter
    setFilters(f => {
      const newFilters = [...f]
      newFilters.find(f => f.index === index)![key] = value
      return newFilters
    })
  }

  function handleBlur(target: HTMLInputElement, filter: ['name' | 'filter', number]): void {
    const error = validateElement(target, true)
    setIdsWithErrors(ids => ({...ids, [`${filter[0]}_${filter[1]}`]: error}))
  }

  function deleteFilter(index: number): void {
    setFilters(filters => {
      return filters.filter(f => f.index !== index)
    })
    delete filterElements.current[`name_${index}`]
    delete filterElements.current[`filter_${index}`]
  }

  function newFilter(): void {
    setFilters(f => {
      const index = f.length === 0 ? 0 : 1 + Math.max(...f.map(f => f.index))
      const newEntry = {name: '', filter: '', index}
      return [...f, newEntry]
    })
  }

  // We'll need a way for the parent node to trigger validation of the filters
  // as a part of validating the entire form. It's a bit gross but adding a
  // property to our parent div which the outer code can then call will do the trick.
  useEffect(() => {
    const node: ElementWithValidator = document.getElementById(parentNodeId)
    if (node) node.__performValidation = formValidator
  }, [parentNodeId])

  // If the filters change, we need to check each field for errors. They
  // may or not be displayed immediately.
  useEffect(() => {
    const errors = elementsWithErrors(filterElements.current)
    if (isSubmitting && errors.length === 0) setIsSubmitting(false)
  }, [filters])

  return (
    <>
      {filters.length === 0 && <Text as="p">{I18n.t('No Quiz IP filters have been set')}</Text>}
      {filters.map(filter => (
        <Flex key={filter.index} alignItems="start" margin="0 0 small 0" data-testid="ip-filter">
          <Flex.Item padding="xx-small small xx-small 0">
            <TextInput
              elementRef={elt => {
                if (elt)
                  filterElements.current[`name_${filter.index}`] = elt.querySelector('input')!
              }}
              messages={fieldMessages(`name_${filter.index}`)}
              display="inline-block"
              maxLength={255}
              renderLabel={I18n.t('Name')}
              isRequired={true}
              value={filter.name}
              onChange={(_e, value) => {
                handleFieldChange(value, ['name', filter.index])
              }}
              onBlur={e => handleBlur(e.target, ['name', filter.index])}
              data-testid="ip-filter-name"
            />
          </Flex.Item>
          <Flex.Item padding="xx-small 0">
            <TextInput
              elementRef={elt => {
                if (elt)
                  filterElements.current[`filter_${filter.index}`] = elt.querySelector('input')!
              }}
              messages={fieldMessages(`filter_${filter.index}`)}
              display="inline-block"
              maxLength={255}
              renderLabel={I18n.t('Filter')}
              isRequired={true}
              width="16rem"
              value={filter.filter}
              onChange={(_e, value) => {
                handleFieldChange(value, ['filter', filter.index])
              }}
              onBlur={e => handleBlur(e.target, ['filter', filter.index])}
              data-testid="ip-filter-filter"
            />
          </Flex.Item>
          <Flex.Item padding="x-small 0 0 0">
            <IconButton
              onClick={() => deleteFilter(filter.index)}
              withBackground={false}
              withBorder={false}
              margin="medium 0 0 small"
              screenReaderLabel={I18n.t('Remove filter')}
              data-testid="delete-ip-filter"
            >
              <IconTrashLine size="x-small" />
            </IconButton>
          </Flex.Item>
        </Flex>
      ))}
      <Button
        renderIcon={<IconAddLine />}
        elementRef={elt => elt?.setAttribute('aria-label', I18n.t('Add a quiz IP filter'))}
        margin="small 0"
        onClick={newFilter}
        data-testid="add-ip-filter"
      >
        {I18n.t('Filter')}
      </Button>
      {explainerMountPoint && (
        <Portal open={true} mountNode={explainerMountPoint}>
          <LegendHelpTip />
        </Portal>
      )}
    </>
  )
}
