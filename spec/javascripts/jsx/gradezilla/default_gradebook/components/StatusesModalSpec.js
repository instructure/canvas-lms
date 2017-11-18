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
import { shallow, mount, ReactWrapper } from 'enzyme';
import StatusesModal from 'jsx/gradezilla/default_gradebook/components/StatusesModal';
import { statusColors } from 'jsx/gradezilla/default_gradebook/constants/colors';

let clock;

function defaultProps (props = {}) {
  return {
    colors: statusColors(),
    afterUpdateStatusColors () {},
    onClose () {},
    ...props
  };
}

QUnit.module('StatusesModal', function (suiteHooks) {
  suiteHooks.beforeEach(function () {
    const applicationElement = document.createElement('div');
    applicationElement.id = 'application';
    document.getElementById('fixtures').appendChild(applicationElement);
    clock = sinon.useFakeTimers();
  });

  suiteHooks.afterEach(function () {
    document.getElementById('fixtures').innerHTML = '';
    clock.restore();
  });

  QUnit.module('StatusesModal', {
    setup () {
      this.wrapper = shallow(
        <StatusesModal {...defaultProps()} />
      );
    },

    teardown () {
      this.wrapper.unmount();
      document.getElementById('fixtures').innerHTML = '';
    }
  });

  test('modal is initially closed', function () {
    strictEqual(this.wrapper.find('Modal').prop('open'), false);
  });

  test('modal has a label of "Statuses"', function () {
    equal(this.wrapper.find('Modal').prop('label'), 'Statuses');
  });

  test('modal has a close button label of "Close"', function () {
    equal(this.wrapper.find('Modal').prop('closeButtonLabel'), 'Close');
  });

  test('modal has an onDismiss function', function () {
    equal(typeof this.wrapper.find('Modal').prop('onDismiss'), 'function');
  });

  test('modal has an onExited function', function () {
    equal(typeof this.wrapper.find('Modal').prop('onExited'), 'function');
  });

  test('modal has a "Statuses" header', function () {
    equal(this.wrapper.find('Heading').children().text(), 'Statuses');
  });

  test('modal has a "Done" button', function () {
    equal(this.wrapper.find('Button').children().text(), 'Done');
  });

  test('modal opens', function () {
    this.wrapper.instance().open();
    strictEqual(this.wrapper.find('Modal').prop('open'), true);
  });

  test('modal closes', function () {
    const statusModal = this.wrapper.instance();
    statusModal.open();
    clock.tick(50); // wait for Modal to transition open
    statusModal.close();
    clock.tick(50); // wait for Modal to transition closed
    strictEqual(this.wrapper.find('Modal').prop('open'), false);
  });

  test('on close prop is passed to Modal onExit', function () {
    const onClose = this.stub();
    const wrapper = shallow(<StatusesModal {...defaultProps({ onClose })} />);
    equal(wrapper.find('Modal').prop('onExited'), onClose);
  });

  QUnit.module('StatusesModal#isPopoverShown', {
    setup () {
      this.wrapper = shallow(<StatusesModal {...defaultProps()} />);
      this.instance = this.wrapper.instance();
    },
    teardown () {
      this.wrapper.unmount();
    }
  });

  test('it is true when statuses matches openPopover', function () {
    const status = 'late';
    this.instance.handleOnToggle(status)(true);
    strictEqual(this.instance.isPopoverShown(status), true);
  });

  test('it is when statuses does not match openPopover', function () {
    this.instance.handleOnToggle('late')(true);
    strictEqual(this.instance.isPopoverShown('missing'), false);
  });

  QUnit.module('StatusesModal#updateStatusColors');

  test('it calls afterUpdateStatusColors', function () {
    const afterUpdateStatusColors = this.stub();
    const wrapper = shallow(<StatusesModal {...defaultProps({ afterUpdateStatusColors })} />);
    const instance = wrapper.instance();
    instance.updateStatusColors('late')('#000000');
    strictEqual(afterUpdateStatusColors.callCount, 1);
    wrapper.unmount();
  });

  test('it calls afterUpdateStatusColors with updated colors', function () {
    const afterUpdateStatusColors = this.stub();
    const color = '#000000';
    const expectedColors = {
      late: color,
      missing: '#FFE8E5',
      resubmitted: '#E5F7E5',
      dropped: '#FEF0E5',
      excused: '#FEF7E5'
    };
    const wrapper = shallow(<StatusesModal {...defaultProps({ afterUpdateStatusColors })} />);
    const instance = wrapper.instance();
    instance.updateStatusColors('late')(color);

    deepEqual(afterUpdateStatusColors.firstCall.args[0], expectedColors);
    wrapper.unmount();
  });

  test('it calls afterUpdateStatusColors with updated successFn', function () {
    const successFn = this.stub();
    function afterUpdateStatusColors (_color, fn) { fn(); }
    const wrapper = shallow(<StatusesModal {...defaultProps({ afterUpdateStatusColors })} />);
    const instance = wrapper.instance();
    instance.updateStatusColors('late')('#000000', successFn);

    strictEqual(successFn.calledOnce, true);
    wrapper.unmount();
  });

  test('it calls afterUpdateStatusColors and sets openPopover to null', function () {
    const successFn = this.stub();
    function afterUpdateStatusColors (_color, fn) { fn(); }
    const wrapper = shallow(<StatusesModal {...defaultProps({ afterUpdateStatusColors })} />);
    const instance = wrapper.instance();
    instance.updateStatusColors('late')('#000000', successFn);

    strictEqual(instance.isPopoverShown(null), true);
    wrapper.unmount();
  });

  test('it calls afterUpdateStatusColors with updated failureFn', function () {
    const failureFn = this.stub();
    function afterUpdateStatusColors (_color, _fn, fn) { fn(); }
    const wrapper = shallow(<StatusesModal {...defaultProps({ afterUpdateStatusColors })} />);
    const instance = wrapper.instance();
    instance.updateStatusColors('late')('#000000', () => {}, failureFn);

    strictEqual(failureFn.calledOnce, true);
    wrapper.unmount();
  });

  QUnit.module('StatusesModal Behavior', {
    setup () {
      this.wrapper = shallow(<StatusesModal {...defaultProps()} />);
      this.instance = this.wrapper.instance();
    },
    teardown () {
      this.wrapper.unmount();
    }
  });

  test('clicking Done closes the popover', function () {
    const { wrapper, instance } = this;
    instance.open();
    wrapper.find('Button').simulate('click');
    strictEqual(wrapper.find('Modal').prop('open'), false);
  });

  test('renders five StatusColorListItems', function () {
    const { wrapper, instance } = this;
    instance.open();
    strictEqual(wrapper.find('StatusColorListItem').length, 5);
  });

  QUnit.module('StatusesModal integration behavior with StatusColorListItem', {
    setup () {
      const afterUpdateStatusColors = (color, successFn) => successFn();
      this.wrapper = mount(<StatusesModal {...defaultProps({ afterUpdateStatusColors })} />);
      this.instance = this.wrapper.instance();
    },
    teardown () {
      this.wrapper.unmount();
    }
  });

  test('after clicking apply in the color picker, the color picker popover is closed', function () {
    const { wrapper, instance } = this;
    instance.open();
    clock.tick(50); // wait for Modal to transition open
    const modalContent = new ReactWrapper(wrapper.node.modalContentRef, wrapper.node);
    modalContent.find('StatusColorListItem PopoverTrigger Button').at(0).simulate('click');
    const colorPickerContent = new ReactWrapper(wrapper.node.colorPickerContents.late, wrapper.node);
    const applyButton = colorPickerContent.find('button').findWhere(button => button.prop('children') === 'Apply');
    applyButton.simulate('click');
    strictEqual(modalContent.find('StatusColorListItem Popover').at(0).prop('show'), false);
  });

  test('after clicking a color in the color picker, the status modal is not closed', function () {
    sinon.stub(this.instance, 'close');
    this.instance.open();
    clock.tick(50); // wait for Modal to transition open
    const modalContent = new ReactWrapper(this.wrapper.node.modalContentRef, this.wrapper.node);
    modalContent.find('StatusColorListItem PopoverTrigger Button').at(0).simulate('click');
    const colorButton = document.querySelector("button[role='radio'][title='steel (#E9EDF5)']");
    colorButton.click();
    strictEqual(this.instance.close.callCount, 0);
  });

  test('after clicking cancel in the color picker, the color picker popover is closed', function () {
    const { wrapper, instance } = this;
    instance.open();
    clock.tick(50); // wait for Modal to transition open
    const modalContent = new ReactWrapper(wrapper.node.modalContentRef, wrapper.node);
    modalContent.find('StatusColorListItem PopoverTrigger Button').at(0).simulate('click');
    const colorPickerContent = new ReactWrapper(wrapper.node.colorPickerContents.late, wrapper.node);
    const applyButton = colorPickerContent.find('button').findWhere(button => button.prop('children') === 'Cancel');
    applyButton.simulate('click');
    strictEqual(modalContent.find('StatusColorListItem Popover').at(0).prop('show'), false);
  });

  QUnit.module('StatusesModal integration behavior with StatusColorListItem');

  test('selecting a color and clicking Apply in the color picker passes the ' +
    'color to afterUpdateStatusColors', function () {
    const afterUpdateStatusColors = this.stub();
    const wrapper = mount(<StatusesModal {...defaultProps({ afterUpdateStatusColors })} />);
    const instance = wrapper.instance();
    instance.open();
    clock.tick(50); // wait for Modal to transition open
    const modalContent = new ReactWrapper(wrapper.node.modalContentRef, wrapper.node);
    modalContent.find('StatusColorListItem PopoverTrigger Button').at(0).simulate('click');
    const colorPickerContent = new ReactWrapper(wrapper.node.colorPickerContents.late, wrapper.node);
    const whiteSwatch = colorPickerContent.find('button').findWhere(button => button.prop('title') === 'white (#FFFFFF)');
    whiteSwatch.simulate('click');
    const applyButton = colorPickerContent.find('button').findWhere(button => button.prop('children') === 'Apply');
    applyButton.simulate('click');
    strictEqual(afterUpdateStatusColors.firstCall.args[0].late, '#FFFFFF');
    wrapper.unmount();
  });
});
