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

import React from 'react';
import { bool, func, number, shape, string } from 'prop-types';
import Alert from '@instructure/ui-alerts/lib/components/Alert';
import View from '@instructure/ui-layout/lib/components/View';
import FormFieldGroup from '@instructure/ui-forms/lib/components/FormFieldGroup';
import NumberInput from '@instructure/ui-forms/lib/components/NumberInput';
import PresentationContent from '@instructure/ui-a11y/lib/components/PresentationContent';
import Spinner from '@instructure/ui-elements/lib/components/Spinner';
import Text from '@instructure/ui-elements/lib/components/Text';
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox';
import Select from '@instructure/ui-core/lib/components/Select';
import Round from 'compiled/util/round';
import NumberHelper from '../../../shared/helpers/numberHelper';
import I18n from 'i18n!gradebook';

function isNumeric (input) {
  return NumberHelper.validate(input);
}

function isInRange (input) {
  const num = NumberHelper.parse(input);
  return num >= 0 && num <= 100;
}

function validationError (input) {
  if (!isNumeric(input)) {
    return 'notNumeric';
  } else if (!isInRange(input)) {
    return 'outOfRange';
  }
  return null;
}

const errorMessages = {
  missingSubmissionDeduction: {
    notNumeric: I18n.t('Missing submission grade must be numeric'),
    outOfRange: I18n.t('Missing submission grade must be between 0 and 100')
  },
  lateSubmissionDeduction: {
    notNumeric: I18n.t('Late submission deduction must be numeric'),
    outOfRange: I18n.t('Late submission deduction must be between 0 and 100')
  },
  lateSubmissionMinimumPercent: {
    notNumeric: I18n.t('Lowest possible grade must be numeric'),
    outOfRange: I18n.t('Lowest possible grade must be between 0 and 100')
  }
};

function validationErrorMessage (input, validationType) {
  const error = validationError(input);
  return errorMessages[validationType][error];
}

function markMissingSubmissionsDefaultValue (missingSubmissionDeduction) {
  return Round(100 - missingSubmissionDeduction, 2).toString();
}

function messages (names, validationErrors) {
  const errors = names.map(name => validationErrors[name]);
  return errors.reduce((acc, error) => (
    error ? acc.concat([{ text: error, type: 'error' }]) : acc
  ), []);
}

class LatePoliciesTabPanel extends React.Component {
  static propTypes = {
    latePolicy: shape({
      changes: shape({
        missingSubmissionDeductionEnabled: bool,
        missingSubmissionDeduction: number,
        lateSubmissionDeductionEnabled: bool,
        lateSubmissionDeduction: number,
        lateSubmissionInterval: string,
        lateSubmissionMinimumPercent: number
      }).isRequired,
      validationErrors: shape({
        missingSubmissionDeduction: string,
        lateSubmissionDeduction: string,
        lateSubmissionMinimumPercent: string
      }).isRequired,
      data: shape({
        missingSubmissionDeductionEnabled: bool,
        missingSubmissionDeduction: number,
        lateSubmissionDeductionEnabled: bool,
        lateSubmissionDeduction: number,
        lateSubmissionInterval: string,
        lateSubmissionMinimumPercentEnabled: bool,
        lateSubmissionMinimumPercent: number
      })
    }).isRequired,
    changeLatePolicy: func.isRequired,
    locale: string.isRequired,
    showAlert: bool.isRequired
  };


  state = { showAlert: this.props.showAlert };
  missingPolicyMessages = messages.bind(this, ['missingSubmissionDeduction'])
  latePolicyMessages = messages.bind(this, ['lateSubmissionDeduction', 'lateSubmissionMinimumPercent'])

  componentDidUpdate(_prevProps, prevState) {
    if (!prevState.showAlert || this.state.showAlert) {
      return;
    }

    const inputEnabled = this.getLatePolicyAttribute('missingSubmissionDeductionEnabled');
    if (inputEnabled) {
      this.missingSubmissionDeductionInput.focus();
    } else {
      this.missingSubmissionCheckbox.focus();
    }
  }

  getLatePolicyAttribute = (key) => {
    const { changes, data } = this.props.latePolicy;
    if (key in changes) {
      return changes[key];
    }

    return data && data[key];
  }

  changeMissingSubmissionDeductionEnabled = ({ target: { checked } }) => {
    const changes = this.calculateChanges({ missingSubmissionDeductionEnabled: checked });
    this.props.changeLatePolicy({ ...this.props.latePolicy, changes });
  }

  changeLateSubmissionDeductionEnabled = ({ target: { checked } }) => {
    const updates = { lateSubmissionDeductionEnabled: checked };
    if (!checked) {
      updates.lateSubmissionMinimumPercentEnabled = false;
    } else if (this.getLatePolicyAttribute('lateSubmissionMinimumPercent') > 0) {
      updates.lateSubmissionMinimumPercentEnabled = true;
    }
    this.props.changeLatePolicy({ ...this.props.latePolicy, changes: this.calculateChanges(updates) });
  }

  validateAndChangeNumber = (name, inputValue) => {
    const errorMessage = validationErrorMessage(inputValue, name);
    if (errorMessage) {
      const validationErrors = { ...this.props.latePolicy.validationErrors, [name]: errorMessage };
      return this.props.changeLatePolicy({ ...this.props.latePolicy, validationErrors });
    }

    let newValue = Round(NumberHelper.parse(inputValue), 2);
    if (name === 'missingSubmissionDeduction') {
      // "Mark missing submission with 40 percent" => missingSubmissionDeduction is 60
      newValue = 100 - newValue;
    }
    return this.changeNumber(name, newValue);
  }

  changeNumber = (name, value) => {
    const changesData = { [name]: value };
    if (name === 'lateSubmissionMinimumPercent') {
      changesData.lateSubmissionMinimumPercentEnabled = value !== 0;
    }
    const updates = {
      changes: this.calculateChanges(changesData),
      validationErrors: { ...this.props.latePolicy.validationErrors }
    };
    delete updates.validationErrors[name];
    this.props.changeLatePolicy({ ...this.props.latePolicy, ...updates });
  }

  changeLateSubmissionInterval = ({ target: { value } }) => {
    const changes = this.calculateChanges({ lateSubmissionInterval: value });
    this.props.changeLatePolicy({ ...this.props.latePolicy, changes });
  }

  calculateChanges(newData) {
    const changes = { ...this.props.latePolicy.changes };
    Object.keys(newData).forEach((key) => {
      const initialValue = this.props.latePolicy.data[key];
      const newValue = newData[key];
      if (initialValue !== newValue) {
        changes[key] = newValue;
      } else if (key in changes) {
        // if the new value and the initial value match, that
        // key/val pair should not be tracked as a change
        delete changes[key];
      }
    });

    return changes;
  }

  closeAlert = () => {
    this.setState({ showAlert: false });
  }

  render () {
    if (!this.props.latePolicy.data) {
      return (
        <div id="LatePoliciesTabPanel__Container-noContent">
          <Spinner title={I18n.t('Loading')} size="large" margin="small" />
        </div>
      );
    }

    const { data, validationErrors } = this.props.latePolicy;
    const numberInputWidth = "5.5rem";
    return (
      <div id="LatePoliciesTabPanel__Container">
        <View as="div" margin="small">
          <Checkbox
            label={I18n.t('Automatically apply grade for missing submissions')}
            defaultChecked={data.missingSubmissionDeductionEnabled}
            onChange={this.changeMissingSubmissionDeductionEnabled}
            ref={(c) => { this.missingSubmissionCheckbox = c; }}
          />
        </View>

        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Missing policies')}</ScreenReaderContent>}
          messages={this.missingPolicyMessages(validationErrors)}
        >
          <View as="div" margin="small small small large">
            <div style={{ marginLeft: '0.25rem'}}>
              <PresentationContent>
                <View as="div" margin="0 0 x-small 0">
                  <label htmlFor="missing-submission-grade">
                    <Text size="small" weight="bold">{I18n.t('Missing submission grade')}</Text>
                  </label>
                </View>
              </PresentationContent>

              <div className="NumberInput__Container">
                <NumberInput
                  id="missing-submission-grade"
                  locale={this.props.locale}
                  inputRef={(m) => { this.missingSubmissionDeductionInput = m; }}
                  label={<ScreenReaderContent>{I18n.t('Missing submission grade percent')}</ScreenReaderContent>}
                  disabled={!this.getLatePolicyAttribute('missingSubmissionDeductionEnabled')}
                  defaultValue={markMissingSubmissionsDefaultValue(data.missingSubmissionDeduction)}
                  onChange={(_e, val)  => this.validateAndChangeNumber('missingSubmissionDeduction', val)}
                  min="0"
                  max="100"
                  inline
                  width={numberInputWidth}
                />

                <PresentationContent>
                  <View as="div" margin="0 small">
                    <Text>{I18n.t('%')}</Text>
                  </View>
                </PresentationContent>
              </div>
            </div>
          </View>
        </FormFieldGroup>

        <PresentationContent><hr /></PresentationContent>

        {this.state.showAlert &&
          <Alert
            variant="warning"
            closeButtonLabel={I18n.t('Close')}
            onDismiss={this.closeAlert}
            margin="small"
          >
            {I18n.t('Changing the late policy will affect previously graded submissions.')}
          </Alert>
        }

        <View as="div" margin="small">
          <Checkbox
            label={I18n.t('Automatically apply deduction to late submissions')}
            defaultChecked={data.lateSubmissionDeductionEnabled}
            onChange={this.changeLateSubmissionDeductionEnabled}
          />
        </View>

        <FormFieldGroup
          description={<ScreenReaderContent>{I18n.t('Late policies')}</ScreenReaderContent>}
          messages={this.latePolicyMessages(validationErrors)}
        >
          <View as="div" margin="small small small large">
            <div style={{ marginLeft: '0.25rem' }}>
              <View display="inline-block" as="div" margin="0 small 0 0">
                <PresentationContent>
                  <View as="div" margin="0 0 x-small 0">
                    <label htmlFor="late-submission-deduction">
                      <Text size="small" weight="bold">{I18n.t('Deduct')}</Text>
                    </label>
                  </View>
                </PresentationContent>

                <div style={{display: 'flex', alignItems: 'center'}}>
                  <NumberInput
                    id="late-submission-deduction"
                    locale={this.props.locale}
                    inputRef={(l) => { this.lateSubmissionDeductionInput = l; }}
                    label={<ScreenReaderContent>{I18n.t('Late submission deduction percent')}</ScreenReaderContent>}
                    defaultValue={data.lateSubmissionDeduction.toString()}
                    disabled={!this.getLatePolicyAttribute('lateSubmissionDeductionEnabled')}
                    onChange={(_e, val) => this.validateAndChangeNumber('lateSubmissionDeduction', val)}
                    min="0"
                    max="100"
                    inline
                    width={numberInputWidth}
                  />
                  <PresentationContent>
                    <View as="div" margin="0 small">
                      <Text>{I18n.t('%')}</Text>
                    </View>
                  </PresentationContent>
                </div>
              </View>

              <View display="inline-block" as="div" margin="0 0 0 small">
                <PresentationContent>
                  <View as="div" margin="0 0 x-small 0">
                    <label htmlFor="late-submission-interval">
                      <Text size="small" weight="bold">{I18n.t('For each late')}</Text>
                    </label>
                  </View>
                </PresentationContent>

                <Select
                  id="late-submission-interval"
                  disabled={!this.getLatePolicyAttribute('lateSubmissionDeductionEnabled')}
                  label={<ScreenReaderContent>{I18n.t('Late submission deduction interval')}</ScreenReaderContent>}
                  inline
                  width="6rem"
                  defaultValue={data.lateSubmissionInterval}
                  onChange={this.changeLateSubmissionInterval}
                >
                  <option value="day">{I18n.t('Day')}</option>
                  <option value="hour" >{I18n.t('Hour')}</option>
                </Select>
              </View>
            </div>
          </View>

          <View as="div" margin="small small small large">
            <div style={{ marginLeft: '0.25rem' }}>
              <PresentationContent>
                <View as="div" margin="0 0 x-small 0">
                  <label htmlFor="late-submission-minimum-percent">
                    <Text size="small" weight="bold">{I18n.t('Lowest possible grade')}</Text>
                  </label>
                </View>
              </PresentationContent>

              <div style={{display: 'flex', alignItems: 'center'}}>
                <NumberInput
                  id="late-submission-minimum-percent"
                  locale={this.props.locale}
                  inputRef={(l) => { this.lateSubmissionMinimumPercentInput = l; }}
                  label={<ScreenReaderContent>{I18n.t('Lowest possible grade percent')}</ScreenReaderContent>}
                  defaultValue={data.lateSubmissionMinimumPercent.toString()}
                  disabled={!this.getLatePolicyAttribute('lateSubmissionDeductionEnabled')}
                  onChange={(_e, val) => this.validateAndChangeNumber('lateSubmissionMinimumPercent', val)}
                  min="0"
                  max="100"
                  inline
                  width={numberInputWidth}
                />

                <PresentationContent>
                  <View as="div" margin="0 small">
                    <Text>{I18n.t('%')}</Text>
                  </View>
                </PresentationContent>
              </div>
            </div>
          </View>
        </FormFieldGroup>
      </div>
    );
  }
}

export default LatePoliciesTabPanel;
