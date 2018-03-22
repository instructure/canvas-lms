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
import { func, number, shape, string, bool } from 'prop-types';
import I18n from 'i18n!gradebook';
import Container from '@instructure/ui-core/lib/components/Container';
import NumberInput from '@instructure/ui-core/lib/components/NumberInput';
import PresentationContent from '@instructure/ui-core/lib/components/PresentationContent';
import Text from '@instructure/ui-core/lib/components/Text';
import RadioInput from '@instructure/ui-core/lib/components/RadioInput';
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent';
import classnames from 'classnames';
import round from 'coffeescripts/util/round';
import NumberHelper from '../../../shared/helpers/numberHelper'

function defaultDurationLate (interval, secondsLate) {
  let durationLate = secondsLate / 3600

  if (interval === 'day') {
    durationLate /= 24
  }

  return round(durationLate, 2)
}

export default function SubmissionTrayRadioInput (props) {
  const showNumberInput = props.value === 'late' && props.checked;
  const interval = props.latePolicy.lateSubmissionInterval;
  const numberInputDefault = defaultDurationLate(interval, props.submission.secondsLate)
  const numberInputLabel = interval === 'day' ? I18n.t('Days late') : I18n.t('Hours late');
  const numberInputText = interval === 'day' ? I18n.t('Day(s)') : I18n.t('Hour(s)');
  const styles = {
    backgroundColor: props.color,
    height: showNumberInput ? '5rem' : '2rem'
  };

  const radioInputClasses = classnames(
    'SubmissionTray__RadioInput',
    { 'SubmissionTray__RadioInput-WithBackground': props.color !== 'transparent' }
  );

  function handleNumberInputBlur ({ target: { value } }) {
    if (!NumberHelper.validate(value)) {
      return
    }

    const parsedValue = NumberHelper.parse(value)
    const roundedValue = round(parsedValue, 2)
    if (roundedValue === numberInputDefault) {
      return
    }

    let secondsLateOverride = parsedValue * 3600
    if (props.latePolicy.lateSubmissionInterval === 'day') {
      secondsLateOverride *= 24
    }

    props.updateSubmission({
      latePolicyStatus: 'late',
      secondsLateOverride: Math.trunc(secondsLateOverride)
    })
  }

  return (
    <div className={radioInputClasses} style={styles}>
      <RadioInput
        checked={props.checked}
        disabled={props.disabled}
        name="SubmissionTrayRadioInput"
        label={props.text}
        onChange={props.onChange}
        value={props.value}
      />

      {
        showNumberInput &&
          <span className="NumberInput__Container NumberInput__Container-LeftIndent">
            <NumberInput
              defaultValue={numberInputDefault.toString()}
              disabled={props.disabled}
              inline
              label={<ScreenReaderContent>{numberInputLabel}</ScreenReaderContent>}
              locale={props.locale}
              min="0"
              onBlur={handleNumberInputBlur}
              showArrows={false}
              width="5rem"
            />

            <PresentationContent>
              <Container as="div" margin="0 small">
                <Text>{numberInputText}</Text>
              </Container>
            </PresentationContent>
          </span>
      }
    </div>
  );
}

SubmissionTrayRadioInput.propTypes = {
  checked: bool.isRequired,
  color: string,
  disabled: bool.isRequired,
  latePolicy: shape({
    lateSubmissionInterval: string.isRequired
  }).isRequired,
  locale: string.isRequired,
  onChange: func.isRequired,
  submission: shape({
    secondsLate: number.isRequired
  }).isRequired,
  text: string.isRequired,
  updateSubmission: func.isRequired,
  value: string.isRequired
};

SubmissionTrayRadioInput.defaultProps = {
  color: 'transparent'
};
