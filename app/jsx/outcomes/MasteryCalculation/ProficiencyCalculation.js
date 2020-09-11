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

import React, {useState, useEffect, useRef, useCallback} from 'react'
import PropTypes from 'prop-types'
import _ from 'lodash'
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'
import I18n from 'i18n!MasteryScale'
import numberHelper from 'jsx/shared/helpers/numberHelper'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {View} from '@instructure/ui-view'
import {NumberInput} from '@instructure/ui-number-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import CalculationMethodContent from 'compiled/models/grade_summary/CalculationMethodContent'

const validInt = (method, value) => {
  if (method.validRange) {
    const [min, max] = method.validRange
    return value >= min && value <= max
  } else {
    return !value
  }
}

const CalculationIntInput = ({updateCalculationInt, calculationMethod, calculationInt}) => {
  const [currentValue, setCurrentValue] = useState(calculationInt)

  useEffect(() => {
    setCurrentValue(calculationInt)
  }, [calculationInt])

  const handleChange = (_event, data) => {
    if (data === '') {
      setCurrentValue(null)
    } else {
      const parsed = numberHelper.parse(data)
      if (!Number.isNaN(parsed)) {
        setCurrentValue(parsed)
        if (validInt(calculationMethod, parsed)) {
          updateCalculationInt(parsed)
        }
      }
    }
  }

  const handleIncrement = () => {
    if (validInt(calculationMethod, calculationInt + 1)) {
      updateCalculationInt(calculationInt + 1)
    }
  }

  const handleDecrement = () => {
    if (validInt(calculationMethod, calculationInt - 1)) {
      updateCalculationInt(calculationInt - 1)
    }
  }

  const errorMessages = []
  if (currentValue === null) {
    errorMessages.push({text: I18n.t('Must be a number'), type: 'error'})
  } else if (!validInt(calculationMethod, currentValue)) {
    errorMessages.push({
      text: I18n.t('Must be between %{lower} and %{upper}', {
        lower: calculationMethod.validRange[0],
        upper: calculationMethod.validRange[1]
      }),
      type: 'error'
    })
  }

  return (
    <NumberInput
      renderLabel={I18n.t('Parameter')}
      value={currentValue || ''}
      messages={errorMessages}
      onIncrement={handleIncrement}
      onDecrement={handleDecrement}
      onChange={handleChange}
    />
  )
}

const Display = ({calculationInt, currentMethod}) => {
  return (
    <>
      <Heading level="h4">{I18n.t('Proficiency Calculation')}</Heading>
      <Text color="primary" weight="normal">
        {currentMethod.friendlyCalculationMethod}
      </Text>
      {currentMethod.validRange && (
        <>
          <Heading level="h4">{I18n.t('Parameter')}</Heading>
          <Text color="primary" weight="normal">
            {calculationInt}
          </Text>
        </>
      )}
    </>
  )
}

const Form = ({
  calculationMethodKey,
  calculationInt,
  calculationMethods,
  currentMethod,
  updateCalculationMethod,
  setCalculationInt
}) => {
  return (
    <FormFieldGroup
      description={
        <ScreenReaderContent>{I18n.t('Proficiency calculation parameters')}</ScreenReaderContent>
      }
    >
      <SimpleSelect
        renderLabel={I18n.t('Proficiency Calculation')}
        value={calculationMethodKey}
        onChange={updateCalculationMethod}
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
        />
      )}
    </FormFieldGroup>
  )
}

const Example = ({currentMethod}) => {
  return (
    <div>
      <Text weight="bold">{I18n.t('Example')}</Text>
      <Text>
        <View as="div" padding="small 0 x-small">
          {currentMethod.exampleText}
        </View>
        <View as="div" padding="x-small 0">
          {I18n.t('Item Scores:')}&nbsp;
          <Text weight="bold"> {currentMethod.exampleScores}</Text>
        </View>
        <View as="div" padding="x-small 0">
          {I18n.t('Final Score:')}&nbsp;
          <Text weight="bold">{currentMethod.exampleResult}</Text>
        </View>
      </Text>
    </div>
  )
}

const ProficiencyCalculation = ({method, update: rawUpdate, updateError}) => {
  const {calculationMethod: initialMethodKey, calculationInt: initialInt, locked} = method

  const [calculationMethodKey, setCalculationMethodKey] = useState(initialMethodKey)
  const [calculationInt, setCalculationInt] = useState(initialInt)
  const firstRender = useRef(true)

  const update = useCallback(_.debounce(rawUpdate, 500), [rawUpdate])

  useEffect(() => () => update.cancel(), [update]) // cancel on unmount

  useEffect(() => {
    if (!firstRender.current) {
      update(calculationMethodKey, calculationInt)
    }
    firstRender.current = false
  }, [calculationMethodKey, calculationInt, update])

  useEffect(() => {
    if (updateError) {
      $.flashError(I18n.t('An error occurred updating the calculation method'))
    }
  }, [updateError])

  const calculationMethods = new CalculationMethodContent({
    calculation_method: calculationMethodKey,
    calculation_int: calculationInt
  }).toJSON()
  const currentMethod = calculationMethods[calculationMethodKey]

  const updateCalculationMethod = (_event, data) => {
    const newMethod = data.id
    if (newMethod !== calculationMethodKey) {
      setCalculationMethodKey(newMethod)
      setCalculationInt(calculationMethods[newMethod].defaultInt || null)
    }
  }

  return (
    <View as="div">
      {locked && (
        <Heading level="h5" margin="medium 0">
          {I18n.t(
            'The proficiency calculation was set by your admin and applies to all courses in this account.'
          )}
        </Heading>
      )}
      <Flex alignItems="start" wrap="wrap">
        <Flex.Item size="240px" padding="small">
          {locked ? (
            <Display currentMethod={currentMethod} calculationInt={calculationInt} />
          ) : (
            <Form
              calculationMethodKey={calculationMethodKey}
              calculationInt={calculationInt}
              calculationMethods={calculationMethods}
              currentMethod={currentMethod}
              updateCalculationMethod={updateCalculationMethod}
              setCalculationInt={setCalculationInt}
            />
          )}
        </Flex.Item>
        <Flex.Item size="240px" shouldGrow padding="small">
          <Example currentMethod={currentMethod} />
        </Flex.Item>
      </Flex>
    </View>
  )
}

ProficiencyCalculation.propTypes = {
  method: PropTypes.shape({
    calculationMethod: PropTypes.string.isRequired,
    calculationInt: PropTypes.number,
    locked: PropTypes.bool
  }),
  update: PropTypes.func.isRequired,
  updateError: PropTypes.string
}

ProficiencyCalculation.defaultProps = {
  method: {
    calculationMethod: 'decaying_average',
    calculationInt: 65,
    locked: false
  },
  updateError: null
}

export default ProficiencyCalculation
