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
import {mount} from 'enzyme'
import $ from 'jquery'
import PostGradesApp from 'jsx/gradezilla/SISGradePassback/PostGradesApp'
import GradebookExportManager from 'jsx/gradezilla/shared/GradebookExportManager'
import ActionMenu from 'jsx/gradezilla/default_gradebook/components/ActionMenu'

const workingMenuProps = () => (
  {
    gradebookIsEditable: true,
    contextAllowsGradebookUploads: true,
    gradebookImportUrl: 'http://gradebookImportUrl',

    currentUserId: '42',
    gradebookExportUrl: 'http://gradebookExportUrl',

    postGradesLtis: [{
      id: '1',
      name: 'Pinnacle',
      onSelect () {}
    }],

    postGradesFeature: {
      enabled: false,
      label: '',
      store: {},
      returnFocusTo: { focus () {} }
    },

    publishGradesToSis: {
      isEnabled: false
    },

    gradingPeriodId: "1234"
  }
);
const previousExportProps = () => (
  {
    lastExport: {
      progressId: '9000',
      workflowState: 'completed'
    },
    attachment: {
      id: '691',
      downloadUrl: 'http://downloadUrl',
      updatedAt: '2009-01-20T17:00:00Z'
    }
  }
);

QUnit.module('ActionMenu - Basic Rendering', {
  setup () {
    const propsWithPreviousExport = {
      ...workingMenuProps(),
      ...previousExportProps()
    };
    this.wrapper = mount(<ActionMenu {...propsWithPreviousExport} />);
    this.wrapper.find('button').simulate('click');
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('renders the Import menu item', function () {
  const specificMenuItem = document.querySelector('[role="menuitem"] [data-menu-id="import"]');

  equal(specificMenuItem.textContent, 'Import');
});

test('renders the Export menu item', function () {
  const specificMenuItem = document.querySelector('[role="menuitem"] [data-menu-id="export"]');

  equal(specificMenuItem.textContent, 'Export');
  equal(specificMenuItem.parentElement.getAttribute('aria-disabled'), null);
});

test('renders the Previous export menu item', function () {
  const specificMenuItem = document.querySelector('[role="menuitem"] [data-menu-id="previous-export"]');

  equal(specificMenuItem.textContent, 'Previous Export (Jan 20, 2009 at 5pm)');
});

test('renders the Sync Grades LTI menu items', function () {
  const specificMenuItem = document.querySelector('[role="menuitem"] [data-menu-id="post_grades_lti_1"]');

  equal(specificMenuItem.textContent, 'Sync to Pinnacle');
});

test('renders no Post Grades feature menu item when disabled', function () {
  const specificMenuItem = document.querySelector('[role="menuitem"] [data-menu-id="post_grades_feature_tool"]');

  strictEqual(specificMenuItem, null);
})

test('renders the Post Grades feature menu item when enabled', function () {
  this.wrapper.unmount();
  const props = workingMenuProps();
  props.postGradesFeature.enabled = true;

  this.wrapper = mount(<ActionMenu {...props} />);
  this.wrapper.find('button').simulate('click');

  const specificMenuItem = document.querySelector('[role="menuitem"] [data-menu-id="post_grades_feature_tool"]');
  equal(specificMenuItem.textContent, 'Sync to SIS');
})

test('renders the Post Grades feature menu item with label when sis handle is set', function () {
  this.wrapper.unmount();
  const props = workingMenuProps();
  props.postGradesFeature.enabled = true;
  props.postGradesFeature.label = 'Powerschool';

  this.wrapper = mount(<ActionMenu {...props} />);
  this.wrapper.find('button').simulate('click');

  const specificMenuItem = document.querySelector('[role="menuitem"] [data-menu-id="post_grades_feature_tool"]');
  equal(specificMenuItem.textContent, 'Sync to Powerschool');
})

QUnit.module('ActionMenu - getExistingExport', {
  setup () {
    this.wrapper = mount(<ActionMenu {...workingMenuProps()} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('returns an export hash with workflowState when progressId and attachment.id are present', function () {
  const propsWithPreviousExport = {
    ...workingMenuProps(),
    ...previousExportProps()
  };
  const expectedExport = {
    attachmentId: '691',
    progressId: '9000',
    workflowState: 'completed'
  };

  this.wrapper = mount(<ActionMenu {...propsWithPreviousExport} />);

  deepEqual(this.wrapper.instance().getExistingExport(), expectedExport);
});

test('returns undefined when lastExport is undefined', function () {
  equal(this.wrapper.instance().getExistingExport(), undefined);
});

test("returns undefined when lastExport's attachment is undefined", function () {
  const propsWithPreviousExport = {
    ...workingMenuProps(),
    ...previousExportProps()
  };

  delete propsWithPreviousExport.attachment;
  this.wrapper = mount(<ActionMenu {...propsWithPreviousExport} />);

  equal(this.wrapper.instance().getExistingExport(), undefined);
});

test('returns undefined when lastExport is missing progressId', function () {
  const propsWithPreviousExport = {
    ...workingMenuProps(),
    ...previousExportProps()
  };

  propsWithPreviousExport.lastExport.progressId = '';
  this.wrapper = mount(<ActionMenu {...propsWithPreviousExport} />);

  equal(this.wrapper.instance().getExistingExport(), undefined);
});

test("returns undefined when lastExport's attachment is missing its id", function () {
  const propsWithPreviousExport = {
    ...workingMenuProps(),
    ...previousExportProps()
  };

  propsWithPreviousExport.attachment.id = '';
  this.wrapper = mount(<ActionMenu {...propsWithPreviousExport} />);

  equal(this.wrapper.instance().getExistingExport(), undefined);
});

QUnit.module('ActionMenu - handleExport', {
  getPromise (type) {
    if (type === 'resolved') {
      return Promise.resolve({
        attachmentUrl: 'http://attachmentUrl',
        updatedAt: '2009-01-20T17:00:00Z'
      });
    }

    return Promise.reject('Export failure reason');
  },

  setup () {
    this.expectedPreviousExport = {
      attachmentUrl: 'http://attachmentUrl',
      label: 'New Export (Jan 20, 2009 at 5pm)'
    };
    this.successfulExport = {
      attachmentUrl: 'http://attachmentUrl',
      updatedAt: '2009-01-20T17:00:00Z'
    };

    this.spies = {};
    this.spies.gotoUrl = sandbox.stub(ActionMenu, 'gotoUrl');
    this.spies.startExport = sandbox.stub(GradebookExportManager.prototype, 'startExport');

    this.wrapper = mount(<ActionMenu {...workingMenuProps()} />, { attachTo: document.querySelector('#fixture')});

    this.trigger = this.wrapper.find('button');
    this.trigger.simulate('click');

    this.menuItem = document.querySelector('[role="menuitem"] [data-menu-id="export"]');
  },

  teardown () {
    this.menuItem = undefined;
    this.wrapper.unmount();

    this.spies = {};
  }
});

test('clicking on the export menu option calls the handleExport function', function () {
  this.spies.handleExport = sandbox.stub(ActionMenu.prototype, 'handleExport');

  this.menuItem.click();

  equal(this.spies.handleExport.callCount, 1);
});

test('shows a message to the user indicating the export is in progress', function () {
  const exportResult = this.getPromise('resolved');
  this.spies.startExport.returns(exportResult);
  this.spies.flashMessage = sandbox.stub(window.$, 'flashMessage');

  this.menuItem.click();

  equal(this.spies.flashMessage.callCount, 1);
  equal(this.spies.flashMessage.getCall(0).args[0], 'Gradebook export started');

  return exportResult;
});

test('changes the "Export" menu item to indicate the export is in progress', function () {
  const exportResult = this.getPromise('resolved');
  this.spies.startExport.returns(exportResult);

  // Click the menu item.  This closes it.
  this.menuItem.click();
  // Click the Menu trigger again to re-open the menu
  this.trigger.simulate('click');

  // Re-fetch the menu element
  this.menuItem = document.querySelector('[role="menuitem"] [data-menu-id="export"]');

  equal(this.menuItem.textContent, 'Export in progress');
  equal(this.menuItem.parentElement.parentElement.parentElement.getAttribute('aria-disabled'), 'true');

  return exportResult;
});

test('starts the export using the GradebookExportManager instance', function () {
  const exportResult = this.getPromise('resolved');
  this.spies.startExport.returns(exportResult);

  this.menuItem.click();

  equal(this.spies.startExport.callCount, 1);

  return exportResult;
});

test('passes the grading period to the GradebookExportManager', function () {
  const exportResult = this.getPromise('resolved');

  this.spies.startExport.returns(exportResult);

  this.menuItem.click();

  strictEqual(this.spies.startExport.firstCall.args[0], "1234");

  return exportResult;
});

test('on success, takes the user to the newly completed export', function () {
  const exportResult = this.getPromise('resolved');
  this.spies.startExport.returns(exportResult);

  const expectedTargetUrl = this.successfulExport.attachmentUrl;

  return this.wrapper.instance().handleExport().then(() => {
    equal(this.spies.gotoUrl.callCount, 1);
    equal(this.spies.gotoUrl.getCall(0).args[0], expectedTargetUrl);
  });
});

test('on success, re-enables the "Export" menu item', function () {
  const exportResult = this.getPromise('resolved');
  this.spies.startExport.returns(exportResult);

  this.trigger.simulate('click');

  return this.wrapper.instance().handleExport().then(() => {
    this.trigger.simulate('click');

    this.menuItem = document.querySelector('[role="menuitem"] [data-menu-id="export"]');

    equal(this.menuItem.textContent, 'Export');
    equal(this.menuItem.parentElement.getAttribute('aria-disabled'), null);
  });
});

test('on success, shows the "New Export" menu item', function () {
  const exportResult = this.getPromise('resolved');
  this.spies.startExport.returns(exportResult);

  this.trigger.simulate('click');

  return this.wrapper.instance().handleExport().then(() => {
    this.trigger.simulate('click');

    const previousExportMenu = document.querySelector('[role="menuitem"] [data-menu-id="previous-export"]');

    equal(previousExportMenu.textContent, 'New Export (Jan 20, 2009 at 5pm)');
  });
});

test('on failure, shows a message to the user indicating the export failed', function () {
  const exportResult = this.getPromise('rejected');
  this.spies.startExport.returns(exportResult);
  this.spies.flashError = sandbox.stub(window.$, 'flashError');

  return this.wrapper.instance().handleExport().then(() => {
    equal(this.spies.flashError.callCount, 1);
    equal(this.spies.flashError.getCall(0).args[0], 'Gradebook Export Failed: Export failure reason');
  });
});

test('on failure, renables the "Export" menu item', function () {
  const exportResult = this.getPromise('rejected');
  this.spies.startExport.returns(exportResult);

  this.trigger.simulate('click');

  return this.wrapper.instance().handleExport().then(() => {
    this.trigger.simulate('click');

    this.menuItem = document.querySelector('[role="menuitem"] [data-menu-id="export"]');

    equal(this.menuItem.textContent, 'Export');
    equal(this.menuItem.parentElement.getAttribute('aria-disabled'), null);
  });
});

QUnit.module('ActionMenu - handleImport', {
  setup () {
    this.spies = {};
    this.spies.gotoUrl = sandbox.stub(ActionMenu, 'gotoUrl');

    this.wrapper = mount(<ActionMenu {...workingMenuProps()} />);
    this.wrapper.find('button').simulate('click');

    this.menuItem = document.querySelectorAll('[role="menuitem"] [data-menu-id="import"]')[0];
  },

  teardown () {
    this.menuItem = undefined;
    this.wrapper.unmount();
  }
});

test('clicking on the import menu option calls the handleImport function', function () {
  const handleImportSpy = sandbox.spy(ActionMenu.prototype, 'handleImport');

  this.menuItem.click();

  equal(handleImportSpy.callCount, 1);
});

test('it takes you to the new imports page', function () {
  this.menuItem.click();

  equal(this.spies.gotoUrl.callCount, 1);
});

QUnit.module('ActionMenu - disableImports', {
  setup () {
    this.wrapper = mount(<ActionMenu {...workingMenuProps()} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('is called once when the component renders', function () {
  const disableImportsSpy = sandbox.spy(ActionMenu.prototype, 'disableImports');

  this.wrapper.update();

  equal(disableImportsSpy.callCount, 1);
});

test('returns false when gradebook is editable and context allows gradebook uploads', function () {
  strictEqual(this.wrapper.instance().disableImports(), false)
});

test('returns true when gradebook is not editable and context allows gradebook uploads', function () {
  const newImportProps = {
    ...workingMenuProps().export,
    gradebookIsEditable: false
  };

  this.wrapper.setProps(newImportProps, () => {
    strictEqual(this.wrapper.instance().disableImports(), true)
  });
});

test('returns true when gradebook is editable but context does not allow gradebook uploads', function () {
  const newImportProps = {
    ...workingMenuProps().export,
    contextAllowsGradebookUploads: false
  };

  this.wrapper.setProps(newImportProps, () => {
    strictEqual(this.wrapper.instance().disableImports(), true)
  });
});

QUnit.module('ActionMenu - lastExportFromProps', {
  setup () {
    this.wrapper = mount(<ActionMenu {...workingMenuProps()} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('returns the lastExport hash if props have a completed last export', function () {
  const propsWithPreviousExport = {
    ...workingMenuProps(),
    ...previousExportProps()
  };

  this.wrapper = mount(<ActionMenu {...propsWithPreviousExport} />);

  deepEqual(this.wrapper.instance().lastExportFromProps(), propsWithPreviousExport.lastExport);
});

test('returns undefined if props have no lastExport', function () {
  equal(this.wrapper.instance().lastExportFromProps(), undefined);
});

test('returns undefined if props have a lastExport but it is not completed', function () {
  const propsWithPreviousExport = {
    ...workingMenuProps(),
    ...previousExportProps()
  };

  propsWithPreviousExport.lastExport.workflowState = 'discombobulated';
  this.wrapper = mount(<ActionMenu {...propsWithPreviousExport} />);

  equal(this.wrapper.instance().lastExportFromProps(), undefined);
});

QUnit.module('ActionMenu - lastExportFromState', {
  setup () {
    this.wrapper = mount(<ActionMenu {...workingMenuProps()} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('returns the previous export if state has a previousExport defined', function () {
  const expectedPreviousExport = {
    label: 'previous export label',
    attachmentUrl: 'http://attachmentUrl'
  };

  this.wrapper.instance().setState({ previousExport: expectedPreviousExport });

  deepEqual(this.wrapper.instance().lastExportFromState(), expectedPreviousExport);
});

test('returns undefined if an export is already in progress', function () {
  this.wrapper.instance().setExportInProgress(true);

  equal(this.wrapper.instance().lastExportFromState(), undefined);
});

test('returns undefined if no previous export is set in the state', function () {
  this.wrapper.instance().setExportInProgress(false);

  equal(this.wrapper.instance().lastExportFromState(), undefined);
});

QUnit.module('ActionMenu - previousExport', {
  setup () {
    const neededProps = {
      ...workingMenuProps(),
      attachment: previousExportProps().attachment
    };

    this.wrapper = mount(<ActionMenu {...neededProps} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('returns the previous export stored in the state if it is available', function () {
  const stateExport = {
    label: 'previous export label',
    attachmentUrl: 'http://attachmentUrl'
  };
  const lastExportFromState = sandbox.stub(ActionMenu.prototype, 'lastExportFromState').returns(stateExport);

  deepEqual(this.wrapper.instance().previousExport(), stateExport);
  equal(lastExportFromState.callCount, 1);
});

test('returns the previous export stored in the props if nothing is available in state', function () {
  const expectedPreviousExport = {
    attachmentUrl: 'http://downloadUrl',
    label: 'Previous Export (Jan 20, 2009 at 5pm)'
  };

  const lastExportFromState = sandbox.stub(ActionMenu.prototype, 'lastExportFromState').returns(undefined);
  const lastExportFromProps = sandbox.stub(ActionMenu.prototype, 'lastExportFromProps').returns(previousExportProps().lastExport);

  deepEqual(this.wrapper.instance().previousExport(), expectedPreviousExport);
  equal(lastExportFromState.callCount, 1);
  equal(lastExportFromProps.callCount, 1);
});

test('returns undefined if state has nothing and props have nothing', function () {
  const lastExportFromState = sandbox.stub(ActionMenu.prototype, 'lastExportFromState').returns(undefined);
  const lastExportFromProps = sandbox.stub(ActionMenu.prototype, 'lastExportFromProps').returns(undefined);

  deepEqual(this.wrapper.instance().previousExport(), undefined);
  equal(lastExportFromState.callCount, 1);
  equal(lastExportFromProps.callCount, 1);
});

QUnit.module('ActionMenu - exportInProgress', {
  setup () {
    this.wrapper = mount(<ActionMenu {...workingMenuProps()} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('returns true if exportInProgress is set', function () {
  this.wrapper.instance().setExportInProgress(true);

  strictEqual(this.wrapper.instance().exportInProgress(), true);
});

test('returns false if exportInProgress is set to false', function () {
  this.wrapper.instance().setExportInProgress(false);

  strictEqual(this.wrapper.instance().exportInProgress(), false);
});

QUnit.module('ActionMenu - Post Grade Ltis', {
  setup () {
    this.props = workingMenuProps();
    this.props.postGradesLtis[0].onSelect = sinon.stub();

    this.wrapper = mount(<ActionMenu {...this.props} />);
    this.wrapper.find('button').simulate('click');
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('Invokes the onSelect prop when selected', function () {
  document.querySelector('[data-menu-id="post_grades_lti_1"]').click();

  strictEqual(this.props.postGradesLtis[0].onSelect.called, true);
});

test('Draws with "Sync to" label', function () {
  const label = document.querySelector('[data-menu-id="post_grades_lti_1"]').textContent;

  strictEqual(label.includes('Sync to Pinnacle'), true);
});

QUnit.module('ActionMenu - Post Grade Feature', {
  setup () {
    this.props = workingMenuProps();
    this.props.postGradesFeature.enabled = true;

    this.wrapper = mount(<ActionMenu {...this.props} />);
    this.wrapper.find('button').simulate('click');
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('launches the PostGrades App when selected', function (assert) {
  const done = assert.async();
  sandbox.stub(PostGradesApp, 'AppLaunch');

  document.querySelector('[data-menu-id="post_grades_feature_tool"]').click();

  setTimeout(function () {
    strictEqual(PostGradesApp.AppLaunch.called, true);
    done();
  }, 15);
});

QUnit.module('ActionMenu - Publish grades to SIS', {
  setup () {
    this.wrapper = mount(<ActionMenu {...workingMenuProps()} />);
    this.wrapper.find('button').simulate('click');
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('Does not render menu item when isEnabled is false and publishToSisUrl is undefined', function () {
  const menuItem = document.querySelector('[role="menuitem"] [data-menu-id="publish-grades-to-sis"]');
  equal(menuItem, null);
});

test('Does not render menu item when isEnabled is true and publishToSisUrl is undefined', function () {
  this.wrapper.setProps({
    publishGradesToSis: {
      isEnabled: true
    }
  });

  const menuItem = document.querySelector('[role="menuitem"] [data-menu-id="publish-grades-to-sis"]');
  equal(menuItem, null);
});

test('Renders menu item when isEnabled is true and publishToSisUrl is defined', function () {
  this.wrapper.setProps({
    publishGradesToSis: {
      isEnabled: true,
      publishToSisUrl: 'http://example.com'
    }
  });

  const menuItem = document.querySelector('[role="menuitem"] [data-menu-id="publish-grades-to-sis"]');
  ok(menuItem);
});

test('Calls gotoUrl with publishToSisUrl when clicked', function () {
  this.wrapper.setProps({
    publishGradesToSis: {
      isEnabled: true,
      publishToSisUrl: 'http://example.com'
    }
  });
  sandbox.stub(ActionMenu, 'gotoUrl');

  const $menuItem = $('[role="menuitem"] [data-menu-id="publish-grades-to-sis"]');
  $menuItem.click();

  equal(ActionMenu.gotoUrl.callCount, 1);
  equal(ActionMenu.gotoUrl.getCall(0).args[0], 'http://example.com');
});
