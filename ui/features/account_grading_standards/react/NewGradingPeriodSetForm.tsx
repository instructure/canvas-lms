/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {useScope as createI18nScope} from '@canvas/i18n'
import setsApi from '@canvas/grading/jquery/gradingPeriodSetsApi'
import type {GradingPeriodSetCreateParams} from '@canvas/grading/jquery/gradingPeriodSetsApi'
import type {CamelizedGradingPeriodSet} from '@canvas/grading/grading.d'
import EnrollmentTermInput from './EnrollmentTermInput'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import type {EnrollmentTerm, GradingPeriodSet, Permissions} from './types'

const I18n = createI18nScope('NewGradingPeriodSetForm')

const normalizePermissions = (value: unknown): Permissions => {
  const source =
    typeof value === 'object' && value !== null ? (value as Record<string, unknown>) : {}
  return {
    read: !!source.read,
    create: !!source.create,
    update: !!source.update,
    delete: !!source.delete,
  }
}

interface NewGradingPeriodSetFormProps {
  enrollmentTerms: EnrollmentTerm[]
  closeForm: () => void
  addGradingPeriodSet: (set: GradingPeriodSet, termIDs: string[]) => void
  urls: {
    gradingPeriodSetsURL: string
  }
}

interface NewGradingPeriodSetFormState {
  buttonsDisabled: boolean
  title: string
  weighted: boolean
  displayTotalsForAllGradingPeriods: boolean
  selectedEnrollmentTermIDs: string[]
}

export default class NewGradingPeriodSetForm extends React.Component<
  NewGradingPeriodSetFormProps,
  NewGradingPeriodSetFormState
> {
  inputRef: React.RefObject<HTMLInputElement>
  cancelButtonRef: Element | null
  createButtonRef: Element | null
  weightedCheckbox: unknown
  displayTotalsCheckbox: unknown

  state: NewGradingPeriodSetFormState = {
    buttonsDisabled: false,
    title: '',
    weighted: false,
    displayTotalsForAllGradingPeriods: false,
    selectedEnrollmentTermIDs: [],
  }

  constructor(props: NewGradingPeriodSetFormProps) {
    super(props)
    this.inputRef = React.createRef<HTMLInputElement>()
    this.cancelButtonRef = null
    this.createButtonRef = null
    this.weightedCheckbox = null
    this.displayTotalsCheckbox = null
  }

  componentDidMount() {
    this.inputRef.current?.focus()
  }

  setSelectedEnrollmentTermIDs = (termIDs: string[]) => {
    this.setState({
      selectedEnrollmentTermIDs: termIDs,
    })
  }

  isTitlePresent = () => {
    if (this.state.title.trim() !== '') {
      return true
    }

    showFlashAlert({type: 'error', message: I18n.t('A name for this set is required')})
    return false
  }

  isValid = () => this.isTitlePresent()

  submit = (event: React.SyntheticEvent<unknown>) => {
    event.preventDefault()
    this.setState({buttonsDisabled: true}, () => {
      if (this.isValid()) {
        const set: GradingPeriodSetCreateParams = {
          title: this.state.title.trim(),
          weighted: this.state.weighted,
          displayTotalsForAllGradingPeriods: this.state.displayTotalsForAllGradingPeriods,
          enrollmentTermIDs: this.state.selectedEnrollmentTermIDs,
        }
        setsApi.create(set).then(this.submitSucceeded).catch(this.submitFailed)
      } else {
        this.setState({buttonsDisabled: false})
      }
    })
  }

  submitSucceeded = (set: CamelizedGradingPeriodSet) => {
    const normalizedSet: GradingPeriodSet = {
      ...set,
      permissions: normalizePermissions(set.permissions),
    }
    showFlashAlert({type: 'success', message: I18n.t('Successfully created a set')})
    this.props.addGradingPeriodSet(normalizedSet, this.state.selectedEnrollmentTermIDs)
  }

  submitFailed = () => {
    showFlashAlert({type: 'error', message: I18n.t('There was a problem submitting your set')})
    this.setState({buttonsDisabled: false})
  }

  onSetTitleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({title: event.target.value})
  }

  onSetWeightedChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({weighted: event.target.checked})
  }

  onSetDisplayTotalsChanged = (event: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({displayTotalsForAllGradingPeriods: event.target.checked})
  }

  render() {
    return (
      <div className="GradingPeriodSetForm pad-box">
        <form className="ic-Form-group ic-Form-group--horizontal">
          <div className="grid-row">
            <div className="col-xs-12 col-lg-6">
              <div className="ic-Form-control">
                <label htmlFor="set-name" className="ic-Label">
                  {I18n.t('Set name')}
                </label>
                <input
                  onChange={this.onSetTitleChange}
                  type="text"
                  id="set-name"
                  className="ic-Input"
                  placeholder={I18n.t('Set name...')}
                  ref={this.inputRef}
                />
              </div>
              <EnrollmentTermInput
                enrollmentTerms={this.props.enrollmentTerms}
                selectedIDs={this.state.selectedEnrollmentTermIDs}
                setSelectedEnrollmentTermIDs={this.setSelectedEnrollmentTermIDs}
              />
              <div className="ic-Input pad-box top-only">
                <Checkbox
                  ref={ref => {
                    this.weightedCheckbox = ref
                  }}
                  label={I18n.t('Weighted grading periods')}
                  value="weighted"
                  checked={this.state.weighted}
                  onChange={this.onSetWeightedChange}
                />
              </div>
              <div className="ic-Input pad-box top-only">
                <Checkbox
                  ref={ref => {
                    this.displayTotalsCheckbox = ref
                  }}
                  label={I18n.t('Display totals for All Grading Periods option')}
                  value="totals"
                  checked={this.state.displayTotalsForAllGradingPeriods}
                  onChange={this.onSetDisplayTotalsChanged}
                />
              </div>
            </div>
          </div>
          <div className="grid-row">
            <div className="col-xs-12 col-lg-12">
              <div className="ic-Form-actions below-line">
                <Button
                  disabled={this.state.buttonsDisabled}
                  onClick={this.props.closeForm}
                  elementRef={ref => {
                    this.cancelButtonRef = ref
                  }}
                >
                  {I18n.t('Cancel')}
                </Button>
                &nbsp;
                <Button
                  disabled={this.state.buttonsDisabled}
                  color="primary"
                  onClick={this.submit}
                  elementRef={ref => {
                    this.createButtonRef = ref
                  }}
                >
                  {I18n.t('Create')}
                </Button>
              </div>
            </div>
          </div>
        </form>
      </div>
    )
  }
}
