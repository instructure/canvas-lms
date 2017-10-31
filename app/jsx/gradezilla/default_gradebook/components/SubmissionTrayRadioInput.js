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
import Container from 'instructure-ui/lib/components/Container';
import NumberInput from 'instructure-ui/lib/components/NumberInput';
import PresentationContent from 'instructure-ui/lib/components/PresentationContent';
import Typography from 'instructure-ui/lib/components/Typography';
import RadioInput from 'instructure-ui/lib/components/RadioInput';
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';
import classnames from 'classnames';
import round from 'coffeescripts/util/round';

function defaultDurationLate (interval, secondsLate) {
  let durationLate = secondsLate / 3600;

  if (interval === 'day') {
    durationLate /= 24;
  }

  return round(durationLate, 2).toString();
}

export default function SubmissionTrayRadioInput (props) {
  const showNumberInput = props.value === 'late' && props.checked;
  const interval = props.latePolicy.lateSubmissionInterval;
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

  return (
    <div className={radioInputClasses} style={styles}>
      <RadioInput
        checked={props.checked}
        disabled={props.disabled}
        name={props.value}
        label={props.text}
        onChange={props.onChange}
        value={props.value}
      />

      {
        showNumberInput &&
          <span className="NumberInput__Container NumberInput__Container-LeftIndent">
            <NumberInput
              defaultValue={defaultDurationLate(interval, props.submission.secondsLate)}
              disabled={props.disabled}
              inline
              label={<ScreenReaderContent>{numberInputLabel}</ScreenReaderContent>}
              locale={props.locale}
              min="0"
              onBlur={props.onNumberInputBlur}
              showArrows={false}
              width="5rem"
            />

            <PresentationContent>
              <Container as="div" margin="0 small">
                <Typography>{numberInputText}</Typography>
              </Container>
            </PresentationContent>
          </span>
      }
    </div>
  );
}

SubmissionTrayRadioInput.propTypes = {
  checked: bool.isRequired,
  color: string.isRequired,
  disabled: bool.isRequired,
  latePolicy: shape({
    lateSubmissionInterval: string.isRequired
  }).isRequired,
  locale: string.isRequired,
  onChange: func.isRequired,
  onNumberInputBlur: func.isRequired,
  submission: shape({
    secondsLate: number.isRequired
  }).isRequired,
  text: string.isRequired,
  value: string.isRequired
};

SubmissionTrayRadioInput.defaultProps = {
  color: 'transparent'
};
