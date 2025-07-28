/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {NumberInput} from '@instructure/ui-number-input'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Checkbox} from '@instructure/ui-checkbox'
import type {LatePolicyCamelized, LatePolicyValidationErrors} from '../gradebook.d'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import NumberHelper from '@canvas/i18n/numberHelper'
import {IconWarningSolid} from '@instructure/ui-icons'

import Round from '@canvas/round'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('gradebook')

const MIN_PERCENTAGE_INPUT = 0
const MAX_PERCENTAGE_INPUT = 100

function isNumeric(input: unknown) {
  // @ts-expect-error
  return NumberHelper.validate(input)
}

function validationError(input: unknown) {
  if (!isNumeric(input)) {
    return 'notNumeric'
  }
  return null
}

function bound(decimal: number) {
  if (decimal < MIN_PERCENTAGE_INPUT) return MIN_PERCENTAGE_INPUT
  if (decimal > MAX_PERCENTAGE_INPUT) return MAX_PERCENTAGE_INPUT
  return decimal
}

const errorMessages = {
  missingSubmissionDeduction: {
    notNumeric: I18n.t('Missing submission grade must be numeric'),
  },
  lateSubmissionDeduction: {
    notNumeric: I18n.t('Late submission deduction must be numeric'),
  },
  lateSubmissionMinimumPercent: {
    notNumeric: I18n.t('Lowest possible grade must be numeric'),
  },
}

// @ts-expect-error
function validationErrorMessage(input, validationType) {
  const error = validationError(input)
  // @ts-expect-error
  return errorMessages[validationType][error]
}

// @ts-expect-error
function messages(names, validationErrors) {
  // @ts-expect-error
  const errors = names.map(name => validationErrors[name])
  return errors.reduce(
    // @ts-expect-error
    (acc, error) =>
      error
        ? acc.concat([
            {
              text: (
                <View textAlign="center">
                  <View as="div" display="inline-block" margin="0 xxx-small xx-small 0">
                    <IconWarningSolid />
                  </View>
                  {error}
                </View>
              ),
              type: 'error',
            },
          ])
        : acc,
    [],
  )
}

// @ts-expect-error
function subtractFromMax(decimal) {
  return MAX_PERCENTAGE_INPUT - decimal
}

const numberInputWillUpdateMap = {
  // @ts-expect-error
  missingSubmissionDeduction(decimal) {
    // the missingSubmissionDeductionDisplayValue is the difference of `100% - missingSubmissionDeduction`
    return subtractFromMax(decimal)
  },
  // @ts-expect-error
  lateSubmissionDeduction(decimal) {
    return decimal
  },
  // @ts-expect-error
  lateSubmissionMinimumPercent(decimal) {
    return decimal
  },
}

type Props = {
  changeLatePolicy: (latePolicy: {
    changes: Partial<LatePolicyCamelized>
    validationErrors: LatePolicyValidationErrors
    data?: LatePolicyCamelized
  }) => void
  gradebookIsEditable: boolean
  latePolicy: {
    changes: Partial<LatePolicyCamelized>
    validationErrors: LatePolicyValidationErrors
    data?: LatePolicyCamelized
  }
  locale: string
  showAlert: boolean
}

type State = {
  showAlert: boolean
}

class LatePoliciesTabPanel extends React.Component<Props, State> {
  missingSubmissionDeductionInput: HTMLInputElement | null

  missingSubmissionCheckbox: Checkbox | null

  lateSubmissionMinimumPercentInput: HTMLInputElement | null

  lateSubmissionDeductionInput: HTMLInputElement | null

  // @ts-expect-error
  constructor(props) {
    super(props)
    this.missingSubmissionCheckbox = null
    this.lateSubmissionMinimumPercentInput = null
    this.lateSubmissionDeductionInput = null
    this.missingSubmissionDeductionInput = null
  }

  state = {
    showAlert: this.props.showAlert,
  }

  missingPolicyMessages = messages.bind(this, ['missingSubmissionDeduction'])

  latePolicyMessages = messages.bind(this, ['lateSubmissionDeduction'])

  letSubmissionMinimumMessages = messages.bind(this, ['lateSubmissionMinimumPercent'])

  componentDidUpdate(_prevProps: Props, prevState: State) {
    if (!prevState.showAlert || this.state.showAlert) {
      return
    }

    const inputEnabled = this.getLatePolicyAttribute('missingSubmissionDeductionEnabled')
    if (inputEnabled) {
      this.missingSubmissionDeductionInput?.focus()
    } else {
      this.missingSubmissionCheckbox?.focus()
    }
  }

  // @ts-expect-error
  getLatePolicyAttribute = key => {
    const {changes, data} = this.props.latePolicy
    if (key in changes) {
      // @ts-expect-error
      return changes[key]
    }

    // @ts-expect-error
    return data && data[key]
  }

  changeMissingSubmissionDeductionEnabled = ({target: {checked}}: {target: {checked: boolean}}) => {
    const changes = this.calculateChanges({missingSubmissionDeductionEnabled: checked})
    this.props.changeLatePolicy({...this.props.latePolicy, changes})
  }

  changeLateSubmissionDeductionEnabled = ({target: {checked}}: {target: {checked: boolean}}) => {
    const updates: {
      lateSubmissionDeductionEnabled: boolean
      lateSubmissionMinimumPercentEnabled?: boolean
    } = {lateSubmissionDeductionEnabled: checked}
    if (!checked) {
      updates.lateSubmissionMinimumPercentEnabled = false
    } else if (this.getLatePolicyAttribute('lateSubmissionMinimumPercent') > MIN_PERCENTAGE_INPUT) {
      updates.lateSubmissionMinimumPercentEnabled = true
    }
    this.props.changeLatePolicy({
      ...this.props.latePolicy,
      changes: this.calculateChanges(updates),
    })
  }

  // @ts-expect-error
  handleBlur = name => {
    // @ts-expect-error
    if (this.props.latePolicy.changes[name] == null) {
      return
    }

    // @ts-expect-error
    const decimal = bound(NumberHelper.parse(this.props.latePolicy.changes[name]))
    const errorMessage = validationErrorMessage(decimal, name)
    if (errorMessage) {
      const validationErrors = {...this.props.latePolicy.validationErrors, [name]: errorMessage}
      return this.props.changeLatePolicy({...this.props.latePolicy, validationErrors})
    }
    // @ts-expect-error
    const decimalDisplayValue = numberInputWillUpdateMap[name](decimal)

    // @ts-expect-error
    this.setState({[`${name}DisplayValue`]: Round(decimalDisplayValue, 2)}, () => {
      const changesData = {[name]: Round(decimal, 2)}
      if (name === 'lateSubmissionMinimumPercent') {
        // @ts-expect-error
        changesData[`${name}Enabled`] = changesData[name] !== MIN_PERCENTAGE_INPUT
      }
      const updates = {
        changes: this.calculateChanges(changesData),
        validationErrors: {...this.props.latePolicy.validationErrors},
      }
      // @ts-expect-error
      delete updates.validationErrors[name]
      this.props.changeLatePolicy({...this.props.latePolicy, ...updates})
    })
  }

  // @ts-expect-error
  handleChange = (name, inputDisplayValue) => {
    const nameDisplayValue = `${name}DisplayValue`
    // @ts-expect-error
    this.setState({[nameDisplayValue]: inputDisplayValue}, () => {
      let decimal = Round(NumberHelper.parse(inputDisplayValue), 2)
      // @ts-expect-error
      decimal = numberInputWillUpdateMap[name](decimal)

      const changes = this.calculateChanges(
        {[name]: decimal},
        {[nameDisplayValue]: inputDisplayValue},
      )
      this.props.changeLatePolicy({...this.props.latePolicy, changes})
    })
  }

  // @ts-expect-error
  changeLateSubmissionInterval = (_event, selectedOption) => {
    const changes = this.calculateChanges({lateSubmissionInterval: selectedOption})
    this.props.changeLatePolicy({...this.props.latePolicy, changes})
  }

  // @ts-expect-error
  calculateChanges(changedData, changedDisplayValues = {}) {
    const changes = {...this.props.latePolicy.changes}
    Object.keys(changedData).forEach(key => {
      const keyDisplayValue = `${key}DisplayValue`
      // @ts-expect-error
      const original = this.props.latePolicy.data?.[key]
      const changed = changedData[key]
      const originalAndChangedDiffer = original !== changed
      let hasChanges = originalAndChangedDiffer
      if (changedDisplayValues.hasOwnProperty(keyDisplayValue)) {
        // @ts-expect-error
        hasChanges = originalAndChangedDiffer !== changedDisplayValues[keyDisplayValue]
      }

      if (hasChanges) {
        // @ts-expect-error
        changes[key] = changed
      } else if (key in changes) {
        // @ts-expect-error
        delete changes[key] // don't track matching values
      }
    })

    return changes
  }

  closeAlert = () => {
    this.setState({showAlert: false})
  }
  // @ts-expect-error

  currentInputDisplayValue = (key, defaultValue) => {
    const stateDisplayKey = `${key}DisplayValue`

    // If the user is in the process of entering something, display it.
    // @ts-expect-error
    if (this.state[stateDisplayKey] != null) {
      // @ts-expect-error
      return this.state[stateDisplayKey]
    }

    // If the user updated this value, switched to a different tab, then came
    // back to this tab, the updated value will be in the changes hash.
    // @ts-expect-error
    if (this.props.latePolicy.changes?.[key] != null) {
      // @ts-expect-error
      const value = this.props.latePolicy.changes[key]
      // @ts-expect-error
      return numberInputWillUpdateMap[key](value)
    }

    // If there have been no changes, use the value we were passed in.
    // @ts-expect-error
    if (this.props.latePolicy.data?.[key] != null) {
      // @ts-expect-error
      const value = this.props.latePolicy.data[key]
      // @ts-expect-error
      return numberInputWillUpdateMap[key](value)
    }

    // If we haven't been given a value yet, punt and show a default.
    return defaultValue
  }

  render() {
    if (!this.props.latePolicy.data) {
      return (
        <div id="LatePoliciesTabPanel__Container-noContent">
          <Spinner renderTitle={I18n.t('Loading')} size="large" margin="small" />
        </div>
      )
    }

    const {validationErrors} = this.props.latePolicy
    const data = {...this.props.latePolicy.data, ...this.props.latePolicy.changes}

    return (
      <div id="LatePoliciesTabPanel__Container">
        <View as="div" margin="small">
          <Checkbox
            label={I18n.t('Automatically apply grade for missing submissions')}
            checked={data.missingSubmissionDeductionEnabled}
            onChange={this.changeMissingSubmissionDeductionEnabled}
            ref={c => {
              this.missingSubmissionCheckbox = c
            }}
            disabled={!this.props.gradebookIsEditable}
          />
        </View>

        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Missing policies')}</ScreenReaderContent>}
        >
          <View as="div" margin="small small small large">
            <div className="NumberInput__Container">
              <Grid vAlign="top" colSpacing="small">
                <Grid.Row>
                  <Grid.Col width="auto">
                    <NumberInput
                      messages={this.missingPolicyMessages(validationErrors)}
                      allowStringValue={true}
                      data-testid="missing-submission-grade"
                      id="missing-submission-grade"
                      // @ts-expect-error
                      locale={this.props.locale}
                      inputRef={m => {
                        this.missingSubmissionDeductionInput = m
                      }}
                      renderLabel={I18n.t('Grade for missing submissions %')}
                      disabled={
                        !this.getLatePolicyAttribute('missingSubmissionDeductionEnabled') ||
                        !this.props.gradebookIsEditable
                      }
                      value={this.currentInputDisplayValue(
                        'missingSubmissionDeduction',
                        MAX_PERCENTAGE_INPUT,
                      )}
                      onBlur={_event => this.handleBlur('missingSubmissionDeduction')}
                      onChange={(_event, val) =>
                        this.handleChange('missingSubmissionDeduction', val)
                      }
                      placeholder="100"
                      showArrows={false}
                    />
                  </Grid.Col>
                </Grid.Row>
              </Grid>
            </div>
          </View>
        </FormFieldGroup>

        <PresentationContent>
          <hr />
        </PresentationContent>

        {this.state.showAlert && (
          <Alert
            variant="warning"
            renderCloseButtonLabel={I18n.t('Close')}
            onDismiss={this.closeAlert}
            margin="small"
          >
            {I18n.t('Changing the late policy will affect previously graded submissions.')}
          </Alert>
        )}

        <View as="div" margin="small">
          <Checkbox
            label={I18n.t('Automatically apply deduction to late submissions')}
            defaultChecked={data.lateSubmissionDeductionEnabled}
            onChange={this.changeLateSubmissionDeductionEnabled}
            disabled={!this.props.gradebookIsEditable}
          />
        </View>

        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Late policies')}</ScreenReaderContent>}
        >
          <View as="div" margin="small small small large">
            <div style={{display: 'flex', alignItems: 'center'}}>
              <Grid vAlign="top" colSpacing="small">
                <Grid.Row>
                  <Grid.Col width="auto">
                    <NumberInput
                      messages={this.latePolicyMessages(validationErrors)}
                      allowStringValue={true}
                      id="late-submission-deduction"
                      // @ts-expect-error
                      locale={this.props.locale}
                      inputRef={l => {
                        this.lateSubmissionDeductionInput = l
                      }}
                      renderLabel={I18n.t('Late submission deduction %')}
                      disabled={
                        !this.getLatePolicyAttribute('lateSubmissionDeductionEnabled') ||
                        !this.props.gradebookIsEditable
                      }
                      value={this.currentInputDisplayValue(
                        'lateSubmissionDeduction',
                        MIN_PERCENTAGE_INPUT,
                      )}
                      onBlur={_event => this.handleBlur('lateSubmissionDeduction')}
                      onChange={(_event, val) => this.handleChange('lateSubmissionDeduction', val)}
                      placeholder="0"
                      showArrows={false}
                      data-testid="late-submission-deduction"
                    />
                  </Grid.Col>
                  <Grid.Col width="auto">
                    <CanvasSelect
                      disabled={
                        !this.getLatePolicyAttribute('lateSubmissionDeductionEnabled') ||
                        !this.props.gradebookIsEditable
                      }
                      id="late-submission-interval"
                      label={I18n.t('Deduction interval')}
                      onChange={this.changeLateSubmissionInterval}
                      value={data.lateSubmissionInterval}
                      data-testid="late-submission-interval"
                    >
                      <CanvasSelect.Option key="day" id="day" value="day">
                        {I18n.t('Day')}
                      </CanvasSelect.Option>
                      <CanvasSelect.Option key="hour" id="hour" value="hour">
                        {I18n.t('Hour')}
                      </CanvasSelect.Option>
                    </CanvasSelect>
                  </Grid.Col>
                </Grid.Row>
                <Grid.Row>
                  <Grid.Col width="auto">
                    <NumberInput
                      messages={this.letSubmissionMinimumMessages(validationErrors)}
                      allowStringValue={true}
                      id="late-submission-minimum-percent"
                      // @ts-expect-error
                      locale={this.props.locale}
                      inputRef={l => {
                        this.lateSubmissionMinimumPercentInput = l
                      }}
                      renderLabel={I18n.t('Lowest possible grade %')}
                      value={this.currentInputDisplayValue(
                        'lateSubmissionMinimumPercent',
                        MIN_PERCENTAGE_INPUT,
                      )}
                      disabled={
                        !this.getLatePolicyAttribute('lateSubmissionDeductionEnabled') ||
                        !this.props.gradebookIsEditable
                      }
                      onBlur={_event => this.handleBlur('lateSubmissionMinimumPercent')}
                      onChange={(_event, val) =>
                        this.handleChange('lateSubmissionMinimumPercent', val)
                      }
                      placeholder="0"
                      display="inline-block"
                      showArrows={false}
                      data-testid="late-submission-minimum-percent"
                    />
                  </Grid.Col>
                </Grid.Row>
              </Grid>
            </div>
          </View>
        </FormFieldGroup>
      </div>
    )
  }
}

export default LatePoliciesTabPanel
