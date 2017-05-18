import React from 'react';
import { mount } from 'enzyme';
import GradebookSettingsModal from 'jsx/gradezilla/GradebookSettingsModal';
import $ from 'jquery';

QUnit.module('GradebookSettingsModal', {
  setup () {
    this.qunitTimeout = QUnit.config.testTimeout;
    QUnit.config.testTimeout = 100;
  },

  mountComponent (props = { onClose: () => {} }) {
    this.wrapper = mount(
      <GradebookSettingsModal {...props} />
    );
    this.component = this.wrapper.get(0)
  },

  teardown () {
    QUnit.config.testTimeout = this.qunitTimeout;
    this.wrapper.unmount();
  }
});

test('modal is initially closed', function () {
  this.mountComponent();
  equal(this.wrapper.find('Modal').prop('isOpen'), false);
});

test('calling open causes the modal to be rendered', function () {
  this.mountComponent();
  this.component.open();
  equal(this.wrapper.find('Modal').prop('isOpen'), true);
});

test('calling close closes the modal', function () {
  this.mountComponent();

  this.component.open();
  equal(this.wrapper.find('Modal').prop('isOpen'), true);

  this.component.close();
  equal(this.wrapper.find('Modal').prop('isOpen'), false);
});

test('clicking cancel closes the modal', function () {
  this.mountComponent();

  this.component.open();
  equal(this.wrapper.find('Modal').prop('isOpen'), true);

  $('#gradebook-settings-cancel-button').click();
  equal(this.wrapper.find('Modal').prop('isOpen'), false);
});

test('onClose is called after the modal closes', function (assert) {
  const done = assert.async();
  const onClose = () => {
    equal(this.wrapper.find('Modal').prop('isOpen'), false);
    done();
  };

  this.mountComponent({ onClose });

  this.component.open();
  this.component.close();
});
