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
  archivedGradingSchemesEnabled: boolean
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
  archivedGradingSchemesEnabled,
}: ComponentProps) => {
  const [lowRangeValid, setLowRangeValid] = useState<boolean>(true)
  const [highRangeValid, setHighRangeValid] = useState<boolean>(true)
  const [addButtonHovering, setAddButtonHovering] = useState<boolean>(false)

  const lowRangeInputRef = useRef<HTMLInputElement>()
  const highRangeInputRef = useRef<HTMLInputElement>()

  const validateLowRange = useCallback(
    (lowRange: number) => {
      if (Number.isNaN(lowRange)) {
        setLowRangeValid(false)
      } else if (lowRange > displayScalingFactor) {
        setLowRangeValid(false)
      } else if (lowRange < 0) {
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
        validateLowRange(lowRange)
      }
    }
  }, [lowRangeDefaultDisplay, validateLowRange])

  useEffect(() => {
    if (highRangeInputRef.current) {
      if (highRangeDefaultDisplay !== highRangeInputRef.current.value) {
        highRangeInputRef.current.value = highRangeDefaultDisplay
        const highRange = numberHelper._parseNumber(highRangeDefaultDisplay)
        validateHighRange(highRange)
      }
    }
  }, [highRangeDefaultDisplay, validateHighRange])

  // @ts-expect-error
  const handleLetterGradeChange = event => {
    onRowLetterGradeChange(event.target.value)
  }

  // @ts-expect-error
  const handleRowLowRangeChange = event => {
    const lowRangeInputAsString = event.target.value
    const lowRange = numberHelper._parseNumber(lowRangeInputAsString)
    validateLowRange(lowRange)
    onLowRangeChange(lowRangeInputAsString)
  }

  // @ts-expect-error
  const handleLowRangeBlur = event => {
    const lowRangeInputAsString = event.target.value
    const lowRange = numberHelper._parseNumber(lowRangeInputAsString)
    validateLowRange(lowRange)
    onLowRangeBlur(lowRangeInputAsString)
  }

  // @ts-expect-error
  const handleRowHighRangeChange = event => {
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

  // @ts-expect-error
  const handleHighRangeBlur = event => {
    const highRangeInputAsString = event.target.value
    const highRange = numberHelper._parseNumber(highRangeInputAsString)
    validateHighRange(highRange)
    onHighRangeBlur(highRangeInputAsString)
  }

  return (
    <>
      <tr>
        <td>
          <Flex>
            <Flex.Item margin="xxx-small 0 0 0">
              <TextInput
                isRequired={true}
                renderLabel={<ScreenReaderContent>{I18n.t('Letter Grade')}</ScreenReaderContent>}
                display="inline-block"
                width="6rem"
                onChange={handleLetterGradeChange}
                defaultValue={letterGrade}
                messages={[{text: <></>, type: 'hint'}]}
              />
            </Flex.Item>
          </Flex>
        </td>
        <td style={{width: '40%'}}>
          <Flex justifyItems={archivedGradingSchemesEnabled ? 'end' : 'start'}>
            <span aria-label={I18n.t('Upper limit of range')}>
              <Flex.Item margin="xxx-small 0 0 0">
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
                      messages={[{text: <></>, type: highRangeValid ? 'hint' : 'error'}]}
                    />
                  </>
                ) : (
                  <>
                    {isFirstRow ? '' : '< '}
                    {highRangeDefaultDisplay}
                  </>
                )}
                {pointsBased ? <></> : <>%</>}
              </Flex.Item>
            </span>
            <Flex.Item padding="x-small">{I18n.t('to')} </Flex.Item>
            <Flex.Item>
              <span aria-label={I18n.t('Lower limit of range')}>
                {isLastRow ? (
                  <>0{pointsBased ? <></> : <>%</>}</>
                ) : (
                  <>
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
                      messages={[{text: <></>, type: lowRangeValid ? 'hint' : 'error'}]}
                    />
                    <View padding="0 0 0 x-small">{pointsBased ? <></> : <>%</>}</View>
                  </>
                )}
              </span>
            </Flex.Item>
          </Flex>
        </td>

        <td style={{verticalAlign: 'top', width: '100%'}}>
          <Flex justifyItems="end">
            <Flex.Item>
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
                >
                  <IconPlusLine />
                </IconButton>
              </Tooltip>
              <IconButton
                screenReaderLabel={I18n.t('Remove letter grade row')}
                onClick={onRowDeleteRequested}
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
