/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useState, useEffect} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'
import {Button} from '@instructure/ui-buttons'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {NumberInput} from '@instructure/ui-number-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import CalculationMethodContent from '@canvas/grading/CalculationMethodContent'
import ConfirmMasteryModal from '../ConfirmMasteryModal'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const I18n = useI18nScope('MasteryScale')

const defaultCalculationMethod = ENV.OUTCOMES_NEW_DECAYING_AVERAGE_CALCULATION
  ? 'weighted_average'
  : 'decaying_average'

export const defaultProficiencyCalculation = {
  calculationMethod: defaultCalculationMethod,
  calculationInt: 65,
}

const validInt = (method, value) => {
  if (method.validRange) {
    const [min, max] = method.validRange
    return value >= min && value <= max
  } else {
    return !value
  }
}

const CalculationIntInput = ({
  updateCalculationInt,
  calculationMethod,
  calculationInt,
  individualOutcomeDisplay,
  calcIntInputRef,
}) => {
  const handleChange = (_event, data) => {
    if (data === '') {
      updateCalculationInt('')
    } else {
      const parsed = numberHelper.parse(data)
      updateCalculationInt(!Number.isNaN(parsed) ? parsed : '')
    }
  }

  const handleIncrement = () => {
    updateCalculationInt(calculationInt !== '' ? calculationInt + 1 : 1)
  }

  const handleDecrement = () => {
    updateCalculationInt(calculationInt - 1)
  }

  const errorMessages = []
  if (calculationInt === '') {
    errorMessages.push({text: I18n.t('Must be a number'), type: 'error'})
  } else if (!validInt(calculationMethod, calculationInt)) {
    errorMessages.push({
      text: I18n.t('Must be between %{lower} and %{upper}', {
        lower: calculationMethod.validRange[0],
        upper: calculationMethod.validRange[1],
      }),
      type: 'error',
    })
  }

  if (individualOutcomeDisplay) {
    return (
      <View as="div" display="flex">
        <View as="div" padding="0" className="points">
          <TextInput
            isRequired={true}
            messages={errorMessages}
            onChange={handleChange}
            renderLabel={
              <ScreenReaderContent>{I18n.t('Proficiency Calculation')}</ScreenReaderContent>
            }
            value={I18n.n(calculationInt) || ''}
            shouldNotWrap={true}
            textAlign="center"
            width="3rem"
            data-testid="calculation-int-input"
            inputRef={calcIntInputRef}
          />
        </View>
        <View as="div" padding="none none none x-small">
          <View as="div">
            <Text color="primary" size="small" weight="normal">
              {calculationMethod.calculationIntLabel}
            </Text>
          </View>
          <View as="div">
            <Text color="secondary" size="x-small" weight="normal">
              {calculationMethod.calculationIntDescription}
            </Text>
          </View>
        </View>
      </View>
    )
  } else {
    return (
      <NumberInput
        renderLabel={() => I18n.t('Parameter')}
        value={typeof calculationInt === 'number' ? calculationInt : ''}
        messages={errorMessages}
        onIncrement={handleIncrement}
        onDecrement={handleDecrement}
        onChange={handleChange}
      />
    )
  }
}

const Display = ({calculationInt, currentMethod, individualOutcomeDisplay}) => {
  const {isMobileView} = useCanvasContext()

  return (
    <View as="div" padding="small none none">
      <Flex
        wrap="wrap"
        direction={individualOutcomeDisplay ? (isMobileView ? 'column' : 'row') : 'column'}
        padding={individualOutcomeDisplay ? 'none small small none' : 'none small none none'}
      >
        <Flex.Item
          as="div"
          padding="none xx-small none none"
          data-testid="read-only-calculation-method"
        >
          {individualOutcomeDisplay ? (
            <View as="div">
              <Text weight="bold">{I18n.t('Proficiency Calculation:')}</Text>
            </View>
          ) : (
            <Heading level="h4">{I18n.t('Mastery Calculation')}</Heading>
          )}
        </Flex.Item>
        <Flex.Item padding={isMobileView ? 'small none none' : 'none'}>
          <Text color="primary" weight="normal">
            {individualOutcomeDisplay
              ? currentMethod.method
              : currentMethod.friendlyCalculationMethod}
          </Text>
        </Flex.Item>
      </Flex>
      {currentMethod.validRange && !individualOutcomeDisplay && (
        <Flex wrap="wrap" direction="column" padding="none small none none">
          <Flex.Item as="div" padding="none xx-small none none">
            <Heading margin="medium none none" level="h4">
              {I18n.t('Parameter')}
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <Text color="primary" weight="normal">
              {calculationInt}
            </Text>
          </Flex.Item>
        </Flex>
      )}
    </View>
  )
}

const Form = ({
  calculationMethodKey,
  calculationInt,
  calculationMethods,
  currentMethod,
  updateCalculationMethod,
  setCalculationInt,
  individualOutcomeForm,
  calcIntInputRef,
}) => (
  <FormFieldGroup
    description={
      <ScreenReaderContent>{I18n.t('Mastery calculation parameters')}</ScreenReaderContent>
    }
  >
    <ScreenReaderContent>
      {I18n.t(
        'See example below to see how different calculation parameters affect student mastery calculation.'
      )}
    </ScreenReaderContent>
    <SimpleSelect
      renderLabel={
        individualOutcomeForm ? I18n.t('Calculation Method') : I18n.t('Mastery Calculation')
      }
      value={calculationMethodKey}
      onChange={updateCalculationMethod}
      data-testid="calculation-method-input"
    >
      {Object.keys(calculationMethods).map(key => (
        <SimpleSelect.Option key={key} id={key} value={key}>
          {calculationMethods[key].friendlyCalculationMethod}
        </SimpleSelect.Option>
      ))}
    </SimpleSelect>
    {currentMethod.validRange && (
      <CalculationIntInput
        calculationInt={calculationInt}
        calculationMethod={currentMethod}
        updateCalculationInt={setCalculationInt}
        individualOutcomeDisplay={individualOutcomeForm}
        calcIntInputRef={calcIntInputRef}
      />
    )}
  </FormFieldGroup>
)

const Example = ({currentMethod, individualOutcomeExample}) => (
  <View as="div">
    <Text weight="bold">{I18n.t('Example')}</Text>
    <View as="div" padding={individualOutcomeExample ? 'x-small 0 x-small' : 'small 0 x-small'}>
      {currentMethod.exampleText}
    </View>
    {currentMethod?.exampleWarning && (
      <div style={{padding: individualOutcomeExample ? '0.25rem 0 0' : '0.5rem 0 0'}}>
        <Text weight="bold">{I18n.t('Warning')}</Text>
        <View as="div" padding={individualOutcomeExample ? 'x-small 0 x-small' : 'small 0 x-small'}>
          {currentMethod.exampleWarning}
        </View>
      </div>
    )}
    <View as="div" padding="x-small 0">
      {I18n.t('Item Scores:')}&nbsp;
      <Text weight="bold">{currentMethod.exampleScores}</Text>
    </View>
    <View as="div" padding="x-small 0">
      {I18n.t('Final Score:')}&nbsp;
      <Text weight="bold" data-testid="proficiency-calculation-example-final-score">
        {currentMethod.exampleResult}
      </Text>
    </View>
  </View>
)

const getModalText = contextType => {
  if (contextType === 'Course') {
    return I18n.t('This will update all student mastery results within this course.')
  }
  return I18n.t(
    'This will update all student mastery results tied to the account level mastery calculation.'
  )
}

const ProficiencyCalculation = ({
  method,
  update,
  updateError,
  canManage,
  onNotifyPendingChanges,
  masteryPoints,
  individualOutcome,
  setError,
  calcIntInputRef,
}) => {
  const newDecayingAverageFF = ENV.OUTCOMES_NEW_DECAYING_AVERAGE_CALCULATION

  if (newDecayingAverageFF) {
    method.calculationMethod =
      method.calculationMethod === 'decaying_average'
        ? 'weighted_average'
        : method.calculationMethod
  } else {
    method.calculationMethod =
      method.calculationMethod === 'standard_decaying_average'
        ? 'decaying_average'
        : method.calculationMethod
  }

  const {contextType, outcomeAllowAverageCalculationFF} = useCanvasContext()
  const {calculationMethod: initialMethodKey, calculationInt: initialInt} = method

  const [calculationMethodKey, setCalculationMethodKey] = useState(initialMethodKey)
  const [calculationInt, setCalculationInt] = useState(initialInt)

  const [allowSave, realSetAllowSave] = useState(false)
  const [showConfirmation, setShowConfirmationModal] = useState(false)

  const individualOutcomeDisplay = individualOutcome === 'display'
  const individualOutcomeEdit = individualOutcome === 'edit'
  const displayInvalidCalculationMethod =
    method.calculationMethod === 'average' && !outcomeAllowAverageCalculationFF

  const setAllowSave = newAllowSave => {
    realSetAllowSave(newAllowSave)
    if (onNotifyPendingChanges) {
      onNotifyPendingChanges(newAllowSave)
    }
  }

  useEffect(() => {
    if (updateError) {
      showFlashAlert({
        message: I18n.t('An error occurred updating the calculation method'),
        type: 'error',
      })
    }
  }, [updateError])

  // Updates state if component is in individual outcome display mode and
  // calculation method or int was changed externally (e.g. via outcome edit)
  useEffect(() => {
    if (individualOutcomeDisplay && !displayInvalidCalculationMethod) {
      updateCalculationMethod(null, {id: method.calculationMethod})
      updateCalculationInt(method.calculationInt)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [method])

  const [showAlert, setShowAlert] = useState(true)

  useEffect(() => {
    if (displayInvalidCalculationMethod && showAlert) {
      showFlashAlert({
        message: I18n.t('The selected calculation method is no longer available'),
        type: 'error',
      })
      setShowAlert(false)
    }
  }, [displayInvalidCalculationMethod, method, showAlert])

  const calculationMethods = new CalculationMethodContent({
    calculation_method: calculationMethodKey,
    calculation_int: calculationInt,
    is_individual_outcome: true,
    mastery_points: masteryPoints,
  }).toJSON()
  const currentMethod =
    calculationMethods[calculationMethodKey] ||
    calculationMethods[defaultProficiencyCalculation.calculationMethod]

  // Sync data/errors between internal/component and external/parent state
  const syncInternalWithExternalState = (calcMethodKey, calcInt) => {
    if (individualOutcomeEdit) {
      update(calcMethodKey, calcInt)
      typeof setError === 'function' &&
        setError(!validInt(calculationMethods[calcMethodKey], calcInt))
    }
  }

  const updateCalculationMethod = (_event, data) => {
    const newMethod = data.id
    const newCalculationInt = calculationMethods[newMethod].defaultInt || null
    if (newMethod !== calculationMethodKey) {
      setCalculationMethodKey(newMethod)
      setCalculationInt(newCalculationInt)
      if (initialMethodKey === newMethod && initialInt === newCalculationInt) {
        setAllowSave(false)
      } else {
        setAllowSave(true)
      }
      syncInternalWithExternalState(newMethod, newCalculationInt)
    }
  }

  const updateCalculationInt = newCalculationInt => {
    setCalculationInt(newCalculationInt)
    if (initialMethodKey === calculationMethodKey && initialInt === newCalculationInt) {
      setAllowSave(false)
    } else {
      setAllowSave(true)
    }
    syncInternalWithExternalState(calculationMethodKey, newCalculationInt)
  }

  const saveCalculationMethod = () => {
    update(calculationMethodKey, calculationInt)
    setShowConfirmationModal(false)
    setAllowSave(false)
  }

  return (
    <View as="div">
      <Flex
        alignItems="start"
        direction={individualOutcomeEdit ? 'row' : 'column'}
        wrap={individualOutcomeEdit ? 'wrap' : 'no-wrap'}
      >
        <Flex.Item
          padding={
            individualOutcomeDisplay
              ? 'none'
              : individualOutcomeEdit
              ? 'none medium none none'
              : 'small'
          }
        >
          {canManage ? (
            <Form
              calculationMethodKey={calculationMethodKey}
              calculationInt={calculationInt}
              calculationMethods={calculationMethods}
              currentMethod={currentMethod}
              updateCalculationMethod={updateCalculationMethod}
              setCalculationInt={updateCalculationInt}
              individualOutcomeForm={individualOutcomeEdit}
              calcIntInputRef={calcIntInputRef}
            />
          ) : (
            <Display
              currentMethod={currentMethod}
              calculationInt={calculationInt}
              individualOutcomeDisplay={individualOutcomeDisplay}
            />
          )}
        </Flex.Item>
        {!individualOutcomeDisplay && (
          <Flex.Item
            padding={individualOutcomeEdit ? 'none small small none' : 'small'}
            size={individualOutcomeEdit ? '50%' : '100%'}
            shouldGrow={individualOutcomeEdit}
          >
            <div style={{paddingTop: individualOutcomeEdit ? '1.35rem' : '0'}}>
              <Example
                currentMethod={currentMethod}
                individualOutcomeExample={individualOutcomeEdit}
              />
            </div>
          </Flex.Item>
        )}
      </Flex>
      {canManage && !individualOutcome && (
        <div className="save">
          <Button
            color="primary"
            interaction={allowSave ? 'enabled' : 'disabled'}
            onClick={() => {
              if (validInt(currentMethod, calculationInt)) {
                setShowConfirmationModal(true)
              }
            }}
          >
            {I18n.t('Save Mastery Calculation')}
          </Button>
          <ConfirmMasteryModal
            isOpen={showConfirmation}
            onConfirm={saveCalculationMethod}
            modalText={getModalText(contextType)}
            title={I18n.t('Confirm Mastery Calculation')}
            onClose={() => setShowConfirmationModal(false)}
          />
        </div>
      )}
    </View>
  )
}

ProficiencyCalculation.propTypes = {
  method: PropTypes.shape({
    calculationMethod: PropTypes.string.isRequired,
    calculationInt: PropTypes.number,
  }),
  canManage: PropTypes.bool,
  update: PropTypes.func,
  onNotifyPendingChanges: PropTypes.func,
  updateError: PropTypes.string,
  masteryPoints: PropTypes.number,
  individualOutcome: PropTypes.oneOf(['display', 'edit']),
  setError: PropTypes.func,
  calcIntInputRef: PropTypes.func,
}

ProficiencyCalculation.defaultProps = {
  method: defaultProficiencyCalculation,
  updateError: null,
  update: () => {},
  calcIntInputRef: () => {},
}

export default ProficiencyCalculation
