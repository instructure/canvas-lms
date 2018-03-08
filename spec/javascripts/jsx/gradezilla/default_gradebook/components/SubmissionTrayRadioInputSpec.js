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
import { mount } from 'enzyme';
import SubmissionTrayRadioInput from 'jsx/gradezilla/default_gradebook/components/SubmissionTrayRadioInput';
import NumberInput from '@instructure/ui-core/lib/components/NumberInput';

QUnit.module('SubmissionTrayRadioInput', {
  mountComponent (customProps) {
    const props = {
      checked: false,
      color: '#FEF7E5',
      disabled: false,
      latePolicy: { lateSubmissionInterval: 'day' },
      locale: 'en',
      onChange () {},
      onNumberInputBlur () {},
      submission: { secondsLate: 0 },
      text: 'Missing',
      value: 'missing',
      ...customProps
    };
    return mount(<SubmissionTrayRadioInput {...props} />);
  },

  numberInputContainer () {
    return this.wrapper.find('.NumberInput__Container');
  },

  numberInput () {
    return this.numberInputContainer().find(NumberInput);
  },

  numberInputDescription () {
    return this.numberInputContainer().find('span[role="presentation"]').node.textContent;
  },

  numberInputLabel () {
    return this.numberInputContainer().find('label').node.textContent;
  },

  radioInput () {
    return this.wrapper.find('input[type="radio"]');
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('does not render a NumberInput when value is not "late"', function () {
  this.wrapper = this.mountComponent();
  strictEqual(this.wrapper.find(NumberInput).length, 0);
});

test('renders with a NumberInput when value is "late" and checked is true', function () {
  this.wrapper = this.mountComponent({ value: 'late', checked: true });
  strictEqual(this.numberInput().length, 1);
});

test('renders without a NumberInput when value is "late" and checked is false', function () {
  this.wrapper = this.mountComponent({ value: 'late' });
  strictEqual(this.numberInput().length, 0);
});

test('renders with the NumberInput enabled when disabled is false', function () {
  this.wrapper = this.mountComponent({ value: 'late', checked: true });
  strictEqual(this.numberInput().props().disabled, false);
});

test('renders with the NumberInput disabled when disabled is true', function () {
  this.wrapper = this.mountComponent({ value: 'late', checked: true, disabled: true });
  strictEqual(this.numberInput().props().disabled, true);
});

test('renders a radio option with a name of "SubmissionTrayRadioInput"', function () {
  this.wrapper = this.mountComponent();
  strictEqual(this.radioInput().node.name, 'SubmissionTrayRadioInput');
});

test('renders with the radio option enabled when disabled is false', function () {
  this.wrapper = this.mountComponent({ disabled: false });
  strictEqual(this.wrapper.find('RadioInput').props().disabled, false);
});

test('renders with the radio option disabled when disabled is true', function () {
  this.wrapper = this.mountComponent({ disabled: true });
  strictEqual(this.wrapper.find('RadioInput').props().disabled, true);
});

test('renders with the radio option selected when checked is true', function () {
  this.wrapper = this.mountComponent({ checked: true });
  strictEqual(this.radioInput().node.checked, true);
});

test('renders with the radio option deselected when checked is false', function () {
  this.wrapper = this.mountComponent();
  strictEqual(this.radioInput().node.checked, false);
});

test('calls onChange when the radio option is selected', function () {
  const onChange = this.stub();
  this.wrapper = this.mountComponent({ onChange });
  this.radioInput().simulate('change', { target: { checked: true } });
  strictEqual(onChange.callCount, 1);
});

test('the text next to the NumberInput reads "Day(s)" if the late policy interval is "day"', function () {
  this.wrapper = this.mountComponent({ value: 'late', checked: true });
  strictEqual(this.numberInputDescription(), 'Day(s)');
});

test('the text next to the NumberInput reads "Hour(s)" if the late policy interval is "day"', function () {
  this.wrapper = this.mountComponent({ value: 'late', checked: true, latePolicy: { lateSubmissionInterval: 'hour' } });
  strictEqual(this.numberInputDescription(), 'Hour(s)');
});

test('the label for the NumberInput reads "Days late" if the late policy interval is "day"', function () {
  this.wrapper = this.mountComponent({ value: 'late', checked: true });
  strictEqual(this.numberInputLabel(), 'Days late');
});

test('the label for the NumberInput reads "Hours late" if the late policy interval is "hour"', function () {
  this.wrapper = this.mountComponent({ value: 'late', checked: true, latePolicy: { lateSubmissionInterval: 'hour' } });
  strictEqual(this.numberInputLabel(), 'Hours late');
});

test('the default value for the NumberInput is converted to days if the late policy interval is "day"', function () {
  // two days in seconds
  const secondsLate = 172800;
  this.wrapper = this.mountComponent({
    value: 'late',
    checked: true,
    submission: { latePolicyStatus: 'late', secondsLate }
  });
  strictEqual(this.numberInput().props().defaultValue, '2');
});

test('the default value for the NumberInput is converted to hours if the late policy interval is "hour"', function () {
  // two days in seconds
  const secondsLate = 172800;
  this.wrapper = this.mountComponent({
    value: 'late',
    checked: true,
    latePolicy: { lateSubmissionInterval: 'hour' },
    submission: { latePolicyStatus: 'late', secondsLate }
  });
  strictEqual(this.numberInput().props().defaultValue, '48');
});

test('the default value for the NumberInput is rounded to two digits after the decimal point', function () {
  // two days and four minutes in seconds
  const secondsLate = 173040;
  this.wrapper = this.mountComponent({
    value: 'late',
    checked: true,
    latePolicy: { lateSubmissionInterval: 'hour' },
    submission: { latePolicyStatus: 'late', secondsLate }
  });
  strictEqual(this.numberInput().props().defaultValue, '48.07');
});
