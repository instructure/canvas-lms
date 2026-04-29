/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {forwardRef, useCallback, useImperativeHandle, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {InstUIModal as Modal} from '@instructure/platform-instui-bindings'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {NumberInput} from '@instructure/ui-number-input'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('turnitinSettingsDialog')

type VisibilityValue = 'immediate' | 'after_grading' | 'after_due_date' | 'never'

type VisibilityOption = {value: VisibilityValue; label: string}

type WordsOrPercent = 'words' | 'percent'

interface TurnitinSettings {
  originality_report_visibility: VisibilityValue
  s_paper_check: boolean
  internet_check: boolean
  journal_check: boolean
  exclude_biblio: boolean
  exclude_quoted: boolean
  exclude_small_matches_type: string | null
  exclude_small_matches_value: number | string
  submit_papers_to: boolean
}

interface VeriCiteSettings {
  originality_report_visibility: VisibilityValue
  exclude_quoted: boolean
  exclude_self_plag: boolean
  store_in_index: boolean
}

export interface TurnitinSettingsModalProps {
  onSettingsChange: (settings: Record<string, unknown>) => void
}

function normalizeBoolean(value: unknown): boolean {
  return ['1', true, 'true', 1].includes(value as string | boolean | number)
}

function getErrorMessage(value: string, showEmptyError: boolean): string | null {
  if (value) {
    const num = Number(value)
    if (!Number.isInteger(num)) {
      return I18n.t('Value must be a whole number')
    } else if (num <= 0) {
      return I18n.t('Value must be greater than 0')
    }
  } else if (showEmptyError) {
    return I18n.t('Value must not be empty')
  }
  return null
}

const visibilityOptions: Array<VisibilityOption> = [
  {value: 'immediate', label: I18n.t('Immediately')},
  {value: 'after_grading', label: I18n.t('After the assignment is graded')},
  {value: 'after_due_date', label: I18n.t('After the Due Date')},
  {value: 'never', label: I18n.t('Never')},
]

/*
 * Inner form component — rendered only when the modal is open so that
 * useState initializers run fresh each time with the latest settings.
 */

type TurnitinSettingsFormProps = {
  onSubmit: (values: Record<string, unknown>) => void
  onCancel: () => void
} & (
  | {type: 'turnitin'; settings: TurnitinSettings}
  | {type: 'vericite'; settings: VeriCiteSettings}
)

function TurnitinSettingsForm({type, settings, onSubmit, onCancel}: TurnitinSettingsFormProps) {
  const [reportVisibility, setReportVisibility] = useState<VisibilityValue>(
    settings.originality_report_visibility || 'immediate',
  )

  // Turnitin-specific state
  const isTurnitin = type === 'turnitin'
  const [sPaperCheck, setSPaperCheck] = useState(
    isTurnitin && normalizeBoolean(settings.s_paper_check),
  )
  const [internetCheck, setInternetCheck] = useState(
    isTurnitin && normalizeBoolean(settings.internet_check),
  )
  const [journalCheck, setJournalCheck] = useState(
    isTurnitin && normalizeBoolean(settings.journal_check),
  )
  const [excludeBiblio, setExcludeBiblio] = useState(
    isTurnitin && normalizeBoolean(settings.exclude_biblio),
  )
  const [excludeQuoted, setExcludeQuoted] = useState(normalizeBoolean(settings.exclude_quoted))
  const [submitPapersTo, setSubmitPapersTo] = useState(
    isTurnitin ? normalizeBoolean(settings.submit_papers_to) : false,
  )

  // Small matches state (Turnitin only)
  const hasExistingSmallMatches = isTurnitin && settings.exclude_small_matches_type != null
  const [excludeSmallMatches, setExcludeSmallMatches] = useState(hasExistingSmallMatches)
  const [smallMatchesType, setSmallMatchesType] = useState<WordsOrPercent>(
    (isTurnitin && (settings.exclude_small_matches_type as WordsOrPercent)) || 'words',
  )
  const [wordsValue, setWordsValue] = useState(
    isTurnitin && settings.exclude_small_matches_type === 'words'
      ? String(settings.exclude_small_matches_value || '')
      : '',
  )
  const [percentValue, setPercentValue] = useState(
    isTurnitin && settings.exclude_small_matches_type === 'percent'
      ? String(settings.exclude_small_matches_value || '')
      : '',
  )
  const [wordsError, setWordsError] = useState<string | null>(null)
  const [percentError, setPercentError] = useState<string | null>(null)

  // VeriCite-specific state
  const [excludeSelfPlag, setExcludeSelfPlag] = useState(
    !isTurnitin && normalizeBoolean(settings.exclude_self_plag),
  )
  const [storeInIndex, setStoreInIndex] = useState(
    !isTurnitin && normalizeBoolean(settings.store_in_index),
  )

  const validateSmallMatches = useCallback((): boolean => {
    if (!excludeSmallMatches) return true

    const value = smallMatchesType === 'words' ? wordsValue : percentValue
    const error = getErrorMessage(value, true)

    if (smallMatchesType === 'words') {
      setWordsError(error)
    } else {
      setPercentError(error)
    }

    return error == null
  }, [excludeSmallMatches, smallMatchesType, wordsValue, percentValue])

  const handleSubmit = useCallback(() => {
    if (!validateSmallMatches()) return

    if (isTurnitin) {
      const excludeType = excludeSmallMatches ? smallMatchesType : null
      const excludeValue = excludeSmallMatches
        ? smallMatchesType === 'words'
          ? wordsValue
          : percentValue
        : null
      onSubmit({
        originality_report_visibility: reportVisibility,
        s_paper_check: sPaperCheck,
        internet_check: internetCheck,
        journal_check: journalCheck,
        exclude_biblio: excludeBiblio,
        exclude_quoted: excludeQuoted,
        exclude_small_matches_type: excludeType,
        exclude_small_matches_value: excludeValue,
        submit_papers_to: submitPapersTo,
      })
    } else {
      onSubmit({
        originality_report_visibility: reportVisibility,
        exclude_quoted: excludeQuoted,
        exclude_self_plag: excludeSelfPlag,
        store_in_index: storeInIndex,
      })
    }
  }, [
    isTurnitin,
    validateSmallMatches,
    reportVisibility,
    sPaperCheck,
    internetCheck,
    journalCheck,
    excludeBiblio,
    excludeQuoted,
    excludeSmallMatches,
    smallMatchesType,
    wordsValue,
    percentValue,
    submitPapersTo,
    excludeSelfPlag,
    storeInIndex,
    onSubmit,
  ])

  const handleWordsBlur = useCallback(() => {
    if (smallMatchesType === 'words' && wordsValue) {
      const error = getErrorMessage(wordsValue, false)
      setWordsError(error)
    }
  }, [smallMatchesType, wordsValue])

  const handlePercentBlur = useCallback(() => {
    if (smallMatchesType === 'percent' && percentValue) {
      const error = getErrorMessage(percentValue, false)
      setPercentError(error)
    }
  }, [smallMatchesType, percentValue])

  return (
    <>
      <Modal.Body>
        <View as="div" margin="0 0 medium 0">
          <View as="div" margin="0 0 small 0">
            <label htmlFor="turnitin_report_visibility_select">
              {I18n.t('Students Can See the Originality Report')}
            </label>
          </View>
          <select
            id="turnitin_report_visibility_select"
            aria-label={I18n.t('Students Can See the Originality Report')}
            value={reportVisibility}
            onChange={e => setReportVisibility(e.target.value as VisibilityValue)}
          >
            {visibilityOptions.map(opt => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </View>

        {isTurnitin && (
          <>
            <View as="fieldset" margin="0 0 medium 0">
              <Heading level="h4" margin="0 0 small 0">
                {I18n.t('Compare Against')}
              </Heading>
              <Checkbox
                label={I18n.t('Other Student Papers')}
                checked={sPaperCheck}
                onChange={() => setSPaperCheck(!sPaperCheck)}
              />
              <Checkbox
                label={I18n.t('Internet Database')}
                checked={internetCheck}
                onChange={() => setInternetCheck(!internetCheck)}
              />
              <Checkbox
                label={I18n.t('Journals, Periodicals, and Publications')}
                checked={journalCheck}
                onChange={() => setJournalCheck(!journalCheck)}
              />
            </View>

            <View as="fieldset" margin="0 0 medium 0">
              <Heading level="h4" margin="0 0 small 0">
                {I18n.t('Do Not Consider')}
              </Heading>
              <Checkbox
                label={I18n.t('Bibliographic Material')}
                checked={excludeBiblio}
                onChange={() => setExcludeBiblio(!excludeBiblio)}
              />
              <Checkbox
                label={I18n.t('Quoted Material')}
                checked={excludeQuoted}
                onChange={() => setExcludeQuoted(!excludeQuoted)}
              />
              <Checkbox
                label={I18n.t('Small Matches')}
                checked={excludeSmallMatches}
                onChange={() => {
                  const newVal = !excludeSmallMatches
                  setExcludeSmallMatches(newVal)
                  if (newVal && !smallMatchesType) {
                    setSmallMatchesType('words')
                  }
                  if (!newVal) {
                    setWordsError(null)
                    setPercentError(null)
                  }
                }}
              />
              {excludeSmallMatches && (
                <View as="div" margin="small 0 0 medium">
                  <RadioInputGroup
                    name="exclude_small_matches_type"
                    description=""
                    value={smallMatchesType}
                    onChange={(_event, value) => {
                      const newType = value as WordsOrPercent
                      setSmallMatchesType(newType)
                      if (newType === 'words') setPercentError(null)
                      else setWordsError(null)
                    }}
                  >
                    <RadioInput
                      label={
                        <Flex alignItems="center" gap="x-small">
                          <Flex.Item>
                            <Text>{I18n.t('Fewer than')}</Text>
                          </Flex.Item>
                          <Flex.Item>
                            <NumberInput
                              renderLabel=""
                              data-testid="words-input"
                              aria-label={I18n.t('Number of words')}
                              width="5rem"
                              value={wordsValue}
                              onChange={(_event, value) => {
                                setWordsValue(value)
                                setWordsError(null)
                              }}
                              onBlur={handleWordsBlur}
                              messages={
                                wordsError ? [{type: 'error' as const, text: wordsError}] : []
                              }
                            />
                          </Flex.Item>
                          <Flex.Item>
                            <Text>{I18n.t('words')}</Text>
                          </Flex.Item>
                        </Flex>
                      }
                      value="words"
                    />
                    <RadioInput
                      label={
                        <Flex alignItems="center" gap="x-small">
                          <Flex.Item>
                            <Text>{I18n.t('Less than')}</Text>
                          </Flex.Item>
                          <Flex.Item>
                            <NumberInput
                              renderLabel=""
                              data-testid="percent-input"
                              aria-label={I18n.t('Percentage of document')}
                              width="5rem"
                              value={percentValue}
                              onChange={(_event, value) => {
                                setPercentValue(value)
                                setPercentError(null)
                              }}
                              onBlur={handlePercentBlur}
                              messages={
                                percentError ? [{type: 'error' as const, text: percentError}] : []
                              }
                            />
                          </Flex.Item>
                          <Flex.Item>
                            <Text>{I18n.t('% of the document')}</Text>
                          </Flex.Item>
                        </Flex>
                      }
                      value="percent"
                    />
                  </RadioInputGroup>
                </View>
              )}
            </View>

            <View as="fieldset" margin="0 0 medium 0">
              <Heading level="h4" margin="0 0 small 0">
                {I18n.t('Turnitin Repository')}
              </Heading>
              <Checkbox
                label={I18n.t('Include in Repository')}
                checked={submitPapersTo}
                onChange={() => setSubmitPapersTo(!submitPapersTo)}
              />
            </View>
          </>
        )}

        {!isTurnitin && (
          <View as="fieldset" margin="0 0 medium 0">
            <Checkbox
              label={I18n.t('Exclude Quoted Material')}
              checked={excludeQuoted}
              onChange={() => setExcludeQuoted(!excludeQuoted)}
            />
            <Checkbox
              label={I18n.t('Exclude Self Plagiarism')}
              checked={excludeSelfPlag}
              onChange={() => setExcludeSelfPlag(!excludeSelfPlag)}
            />
            <Checkbox
              label={I18n.t('Store submissions in Institutional Index')}
              checked={storeInIndex}
              onChange={() => setStoreInIndex(!storeInIndex)}
            />
          </View>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={onCancel} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button color="primary" onClick={handleSubmit}>
          {I18n.t('Update Settings')}
        </Button>
      </Modal.Footer>
    </>
  )
}

/*
 * Outer modal shell — stays mounted, manages open/close state via ref.
 * The inner TurnitinSettingsForm only renders when open, so its useState
 * initializers run fresh each time with the latest settings.
 */

export type DialogState =
  | {type: 'turnitin'; settings: TurnitinSettings}
  | {type: 'vericite'; settings: VeriCiteSettings}

export interface TurnitinSettingsModalHandle {
  open: (dialog: DialogState) => void
  close: () => void
}

const TurnitinSettingsModal = forwardRef<TurnitinSettingsModalHandle, TurnitinSettingsModalProps>(
  function TurnitinSettingsModal({onSettingsChange}, ref) {
    const [isOpen, setIsOpen] = useState(false)
    const [dialog, setDialog] = useState<DialogState>({
      type: 'vericite',
      settings: {
        originality_report_visibility: 'immediate',
        exclude_quoted: false,
        exclude_self_plag: false,
        store_in_index: true,
      },
    })

    useImperativeHandle(
      ref,
      () => ({
        open(dialog: DialogState) {
          setDialog(dialog)
          setIsOpen(true)
        },
        close() {
          setIsOpen(false)
        },
      }),
      [],
    )

    const handleDismiss = useCallback(() => setIsOpen(false), [])

    const handleSubmit = useCallback(
      (values: Record<string, unknown>) => {
        onSettingsChange(values)
        setIsOpen(false)
      },
      [onSettingsChange],
    )

    const title =
      dialog.type === 'turnitin'
        ? I18n.t('Advanced Turnitin Settings')
        : I18n.t('Advanced VeriCite Settings')

    return (
      <Modal
        open={isOpen}
        onDismiss={handleDismiss}
        label={title}
        shouldCloseOnDocumentClick={false}
      >
        {isOpen ? (
          <TurnitinSettingsForm {...dialog} onSubmit={handleSubmit} onCancel={handleDismiss} />
        ) : (
          <Modal.Body />
        )}
      </Modal>
    )
  },
)

export default TurnitinSettingsModal
