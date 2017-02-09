define([
  'react',
  'enzyme',
  'instructure-ui/PopoverMenu',
  'jsx/gradezilla/shared/GradebookExportManager',
  'jsx/gradezilla/default_gradebook/components/ActionMenu'
], (React, { mount }, { default: PopoverMenu }, GradebookExportManager, ActionMenu) => {
  const workingMenuProps = () => (
    {
      gradebookIsEditable: true,
      contextAllowsGradebookUploads: true,
      gradebookImportUrl: 'http://gradebookImportUrl',

      currentUserId: '42',
      gradebookExportUrl: 'http://gradebookExportUrl'
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
      this.wrapper.find('PopoverMenu').simulate('click');
    },

    teardown () {
      this.wrapper.unmount();
    }
  });

  test('renders three menu items', function () {
    const menuItems = document.querySelectorAll('[role="menuitem"]');

    equal(menuItems.length, 3);
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
        attachmentUrl: 'http://attachmentUrl&download_frd=1',
        label: 'New Export (Jan 20, 2009 at 5pm)'
      };
      this.successfulExport = {
        attachmentUrl: 'http://attachmentUrl',
        updatedAt: '2009-01-20T17:00:00Z'
      };

      this.spies = {};
      this.spies.gotoUrl = this.stub(ActionMenu, 'gotoUrl');
      this.spies.startExport = this.stub(GradebookExportManager.prototype, 'startExport');

      this.wrapper = mount(<ActionMenu {...workingMenuProps()} />, { attachTo: document.querySelector('#fixture')});

      this.trigger = this.wrapper.find('PopoverMenu');
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
    this.spies.handleExport = this.stub(ActionMenu.prototype, 'handleExport');

    this.menuItem.click();

    equal(this.spies.handleExport.callCount, 1);
  });

  test('shows a message to the user indicating the export is in progress', function () {
    const exportResult = this.getPromise('resolved');
    this.spies.startExport.returns(exportResult);
    this.spies.flashMessage = this.stub(window.$, 'flashMessage');

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
    // Click the PopoverMenu trigger again to re-open the menu
    this.trigger.simulate('click');

    // Re-fetch the menu element
    this.menuItem = document.querySelector('[role="menuitem"] [data-menu-id="export"]');

    equal(this.menuItem.textContent, 'Export in progress');
    equal(this.menuItem.parentElement.getAttribute('aria-disabled'), 'true');

    return exportResult;
  });

  test('starts the export using the GradebookExportManager instance', function () {
    const exportResult = this.getPromise('resolved');
    this.spies.startExport.returns(exportResult);

    this.menuItem.click();

    equal(this.spies.startExport.callCount, 1);

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
    this.spies.flashError = this.stub(window.$, 'flashError');

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
      this.spies.gotoUrl = this.stub(ActionMenu, 'gotoUrl');

      this.wrapper = mount(<ActionMenu {...workingMenuProps()} />);
      this.wrapper.find('PopoverMenu').simulate('click');

      this.menuItem = document.querySelectorAll('[role="menuitem"] [data-menu-id="import"]')[0];
    },

    teardown () {
      this.menuItem = undefined;
      this.wrapper.unmount();
    }
  });

  test('clicking on the import menu option calls the handleImport function', function () {
    const handleImportSpy = this.spy(ActionMenu.prototype, 'handleImport');

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
    const disableImportsSpy = this.spy(ActionMenu.prototype, 'disableImports');

    this.wrapper.update();

    equal(disableImportsSpy.callCount, 1);
  });

  test('returns false when gradebook is editable and context allows gradebook uploads', function () {
    notOk(this.wrapper.instance().disableImports())
  });

  test('returns true when gradebook is not editable and context allows gradebook uploads', function () {
    const newImportProps = {
      ...workingMenuProps().export,
      gradebookIsEditable: false
    };

    this.wrapper.setProps(newImportProps, () => {
      ok(this.wrapper.instance().disableImports())
    });
  });

  test('returns true when gradebook is editable but context does not allow gradebook uploads', function () {
    const newImportProps = {
      ...workingMenuProps().export,
      contextAllowsGradebookUploads: false
    };

    this.wrapper.setProps(newImportProps, () => {
      ok(this.wrapper.instance().disableImports())
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
    const lastExportFromState = this.stub(ActionMenu.prototype, 'lastExportFromState').returns(stateExport);

    deepEqual(this.wrapper.instance().previousExport(), stateExport);
    equal(lastExportFromState.callCount, 1);
  });

  test('returns the previous export stored in the props if nothing is available in state', function () {
    const expectedPreviousExport = {
      attachmentUrl: 'http://downloadUrl&download_frd=1',
      label: 'Previous Export (Jan 20, 2009 at 5pm)'
    };

    const lastExportFromState = this.stub(ActionMenu.prototype, 'lastExportFromState').returns(undefined);
    const lastExportFromProps = this.stub(ActionMenu.prototype, 'lastExportFromProps').returns(previousExportProps().lastExport);

    deepEqual(this.wrapper.instance().previousExport(), expectedPreviousExport);
    equal(lastExportFromState.callCount, 1);
    equal(lastExportFromProps.callCount, 1);
  });

  test('returns undefined if state has nothing and props have nothing', function () {
    const lastExportFromState = this.stub(ActionMenu.prototype, 'lastExportFromState').returns(undefined);
    const lastExportFromProps = this.stub(ActionMenu.prototype, 'lastExportFromProps').returns(undefined);

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

    ok(this.wrapper.instance().exportInProgress());
  });

  test('returns false if exportInProgress is set to false', function () {
    this.wrapper.instance().setExportInProgress(false);

    notOk(this.wrapper.instance().exportInProgress());
  });
});
