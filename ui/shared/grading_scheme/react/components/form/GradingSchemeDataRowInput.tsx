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

import React, {useEffect, useState, useRef, useCallback} from 'react'

import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import numberHelper from '@canvas/i18n/numberHelper'
import {IconPlusLine, IconTrashLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('GradingSchemeManagement')

interface ComponentProps {
  letterGrade: string
  lowRangeDefaultDisplay: string
  highRangeDefaultDisplay: string
  isFirstRow: boolean
  isLastRow: boolean
  onRowLetterGradeChange: (letterGrade: string) => any
  onLowRangeChange: (lowRangeDisplay: string) => any
  onLowRangeBlur: (lowRangeDisplay: string) => any
  onHighRangeChange: (highRangeDisplay: string) => any
  onHighRangeBlur: (highRangeDisplay: string) => any
  onRowDeleteRequested: () => any
  onRowAddRequested: () => any
  pointsBased: boolean
  displayScalingFactor: number
  editSchemeDataDisabled: boolean
}

export const GradingSchemeDataRowInput = ({
  letterGrade,
  lowRangeDefaultDisplay,
  highRangeDefaultDisplay,
  isFirstRow,
  isLastRow,
  onLowRangeChange,
  onLowRangeBlur,
  onHighRangeChange,
  onHighRangeBlur,
  onRowLetterGradeChange,
  onRowAddRequested,
  onRowDeleteRequested,
  pointsBased,
  displayScalingFactor,
  editSchemeDataDisabled,
}: ComponentProps) => {
  const [lowRangeValid, setLowRangeValid] = useState<boolean>(true)
  const [highRangeValid, setHighRangeValid] = useState<boolean>(true)
  const [letterGradeValid, setLetterGradeValid] = useState<boolean>(true)
  const [addButtonHovering, setAddButtonHovering] = useState<boolean>(false)

  const lowRangeInputRef = useRef<HTMLInputElement>()
  const highRangeInputRef = useRef<HTMLInputElement>()

  const validateLowRange = useCallback(
    (lowRange: number, highRange: number) => {
      if (Number.isNaN(lowRange)) {
        setLowRangeValid(false)
      } else if (lowRange > displayScalingFactor) {
        setLowRangeValid(false)
      } else if (lowRange < 0) {
        setLowRangeValid(false)
      } else if (lowRange >= highRange) {
        setLowRangeValid(false)
      } else {
        setLowRangeValid(true)
      }
    },
    [displayScalingFactor]
  )

  const validateHighRange = useCallback((highRange: number) => {
    if (Number.isNaN(highRange)) {
      setHighRangeValid(false)
    } else if (highRange > 100) {
      setHighRangeValid(false)
    } else if (highRange < 0) {
      setHighRangeValid(false)
    } else {
      setHighRangeValid(true)
    }
  }, [])

  useEffect(() => {
    if (lowRangeInputRef.current) {
      if (lowRangeDefaultDisplay !== lowRangeInputRef.current.value) {
        lowRangeInputRef.current.value = lowRangeDefaultDisplay
        const lowRange = numberHelper._parseNumber(lowRangeDefaultDisplay)
        const highRange = numberHelper._parseNumber(highRangeDefaultDisplay)
        validateLowRange(lowRange, highRange)
      }
    }
  }, [highRangeDefaultDisplay, lowRangeDefaultDisplay, validateLowRange])

  useEffect(() => {
    if (highRangeInputRef.current) {
      if (highRangeDefaultDisplay !== highRangeInputRef.current.value) {
        highRangeInputRef.current.value = highRangeDefaultDisplay
        const highRange = numberHelper._parseNumber(highRangeDefaultDisplay)
        validateHighRange(highRange)
      }
    }
  }, [highRangeDefaultDisplay, validateHighRange])

  const handleLetterGradeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    onRowLetterGradeChange(event.target.value)
    setLetterGradeValid(event.target.value !== '')
  }

  const handleRowLowRangeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const lowRangeInputAsString = event.target.value
    const lowRange = numberHelper._parseNumber(lowRangeInputAsString)
    const highRange = numberHelper._parseNumber(highRangeDefaultDisplay)
    validateLowRange(lowRange, highRange)
    onLowRangeChange(lowRangeInputAsString)
  }

  const handleLowRangeBlur = (event: React.ChangeEvent<HTMLInputElement>) => {
    const lowRangeInputAsString = event.target.value
    const lowRange = numberHelper._parseNumber(lowRangeInputAsString)
    const highRange = numberHelper._parseNumber(highRangeDefaultDisplay)
    validateLowRange(lowRange, highRange)
    onLowRangeBlur(lowRangeInputAsString)
  }

  const handleRowHighRangeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (!isFirstRow) {
      throw Error('Only first row can set the (scheme) high range')
    }
    if (!pointsBased) {
      throw Error('Only points based schemes can set the high range (scaling factor)')
    }
    const highRangeInputAsString = event.target.value
    const highRange = numberHelper._parseNumber(highRangeInputAsString)
    validateHighRange(highRange)
    onHighRangeChange(highRangeInputAsString)
  }

  const handleHighRangeBlur = (event: React.ChangeEvent<HTMLInputElement>) => {
    const highRangeInputAsString = event.target.value
    const highRange = numberHelper._parseNumber(highRangeInputAsString)
    validateHighRange(highRange)
    onHighRangeBlur(highRangeInputAsString)
  }

  return (
    <>
      <tr>
        <td style={{padding: '0px 0px 3px', verticalAlign: 'top'}}>
          <Flex alignItems="start">
            <Flex.Item align="start">
              <TextInput
                isRequired={true}
                renderLabel={<ScreenReaderContent>{I18n.t('Letter Grade')}</ScreenReaderContent>}
                display="inline-block"
                width="6rem"
                onChange={handleLetterGradeChange}
                defaultValue={letterGrade}
                messages={[
                  letterGradeValid
                    ? {text: <></>, type: 'hint'}
                    : {text: I18n.t('Enter a letter grade'), type: 'error'},
                ]}
                style={{margin: '0'}}
                disabled={editSchemeDataDisabled}
                data-testid="grading-scheme-letter-grade-input"
              />
            </Flex.Item>
          </Flex>
        </td>
        <td style={{width: '40%', padding: '0px 0px 3px', verticalAlign: 'top'}}>
          <Flex justifyItems="start" alignItems="start">
            <Flex.Item align="start" padding={isFirstRow && pointsBased ? '0' : 'x-small'}>
              {isFirstRow && pointsBased ? (
                <>
                  <TextInput
                    elementRef={ref => {
                      if (ref instanceof HTMLInputElement) {
                        highRangeInputRef.current = ref
                      }
                    }}
                    isRequired={true}
                    renderLabel={
                      <ScreenReaderContent>{I18n.t('Upper limit of range')}</ScreenReaderContent>
                    }
                    display="inline-block"
                    width="4.5rem"
                    htmlSize={3}
                    onChange={handleRowHighRangeChange}
                    onBlur={handleHighRangeBlur}
                    defaultValue={highRangeDefaultDisplay}
                    messages={[
                      highRangeValid
                        ? {text: <></>, type: 'hint'}
                        : {text: I18n.t('Invalid entry'), type: 'error'},
                    ]}
                    disabled={editSchemeDataDisabled}
                  />
                </>
              ) : (
                <View as="span" aria-label={I18n.t('Upper limit of range')}>
                  {`${isFirstRow ? '' : '< '}${highRangeDefaultDisplay}${pointsBased ? '' : '%'}`}
                </View>
              )}
            </Flex.Item>
            <Flex.Item align="start" padding="x-small">
              <div
                style={{
                  paddingLeft:
                    !isFirstRow && pointsBased
                      ? '46px'
                      : isFirstRow && pointsBased
                      ? '0.5rem'
                      : 'none',
                }}
              >
                {I18n.t('to')}
              </div>
            </Flex.Item>
            {isLastRow ? (
              <Flex.Item align="start" padding="x-small">
                <View aria-label={I18n.t('Lower limit of range')} as="span">
                  0{pointsBased ? <></> : <>%</>}
                </View>
              </Flex.Item>
            ) : (
              <>
                <Flex.Item align="start">
                  <TextInput
                    inputRef={ref => {
                      if (ref instanceof HTMLInputElement) {
                        lowRangeInputRef.current = ref
                      }
                    }}
                    isRequired={true}
                    renderLabel={
                      <ScreenReaderContent>{I18n.t('Lower limit of range')}</ScreenReaderContent>
                    }
                    display="inline-block"
                    width="4.5rem"
                    htmlSize={3}
                    onChange={handleRowLowRangeChange}
                    onBlur={handleLowRangeBlur}
                    defaultValue={lowRangeDefaultDisplay}
                    messages={[
                      lowRangeValid
                        ? {text: <></>, type: 'hint'}
                        : {text: I18n.t('Invalid entry'), type: 'error'},
                    ]}
                    disabled={editSchemeDataDisabled}
                  />
                </Flex.Item>
                <Flex.Item align="start" padding="x-small">
                  {pointsBased ? <></> : <>%</>}
                </Flex.Item>
              </>
            )}
          </Flex>
        </td>

        <td style={{verticalAlign: 'top', width: '100%', padding: '0px 0px 3px'}}>
          <Flex justifyItems="end">
            <Flex.Item align="start">
              <Tooltip renderTip={I18n.t('add a letter grade')}>
                <IconButton
                  screenReaderLabel={I18n.t(
                    'Add new row for a letter grade to grading scheme after this row'
                  )}
                  onClick={onRowAddRequested}
                  elementRef={buttonRef => {
                    if (!buttonRef) return
                    // @ts-expect-error
                    buttonRef.onmouseover = () => setAddButtonHovering(true)
                    // @ts-expect-error
                    buttonRef.onmouseout = () => setAddButtonHovering(false)
                  }}
                  margin="0 small 0 0"
                  disabled={editSchemeDataDisabled}
                >
                  <IconPlusLine />
                </IconButton>
              </Tooltip>
              <IconButton
                screenReaderLabel={I18n.t('Remove letter grade row')}
                onClick={onRowDeleteRequested}
                disabled={editSchemeDataDisabled || (isLastRow && isFirstRow)}
              >
                <IconTrashLine />
              </IconButton>
            </Flex.Item>
          </Flex>
        </td>
      </tr>

      <tr>
        <td colSpan={5}>
          <div style={{height: '5px'}}>
            {addButtonHovering ? (
              <hr style={{margin: 0, border: 'none', borderTop: '1px dashed grey'}} />
            ) : (
              <></>
            )}
          </div>
        </td>
      </tr>
    </>
  )
}
