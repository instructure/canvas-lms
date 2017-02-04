define([
  'react',
  'react-addons-test-utils',
  'jquery',
  'jsx/files/Toolbar'
], (React, TestUtils, $, Toolbar) => {

  const Folder = require('compiled/models/Folder');
  const File = require('compiled/models/File');

  let file = null;
  let courseFolder = null;
  let userFolder = null;
  let toolbarFactory = null;

  const buttonEnabled = (button) => {
    if(button.length == 1){
      const el = button[0];
      if(el.nodeName === 'A'){
        return !el.disabled && el.tabIndex !== -1;
      } else if(el.nodeName === 'BUTTON'){
        return !el.disabled;
      }
    }
    return false;
  };

  const buttonsEnabled = (toolbar, config) => {
    for(const prop in config){
      const button = toolbar.find(prop);
      if((config[prop] && buttonEnabled(button)) || (!config[prop] && !buttonEnabled(button))){
        continue;
      } else {
        return false;
      }
    }
    return true;
  };

  QUnit.module('Toolbar', {
    setup() {
      file = new File({id: 1});
      courseFolder = new Folder({context_type: 'Course', context_id: 1});
      userFolder = new Folder({context_type: 'User', context_id: 2});
      toolbarFactory = React.createFactory(Toolbar);
    }
  });


  test('renders multi select action items when there is more than one item selected', () => {
    const toolbar = TestUtils.renderIntoDocument(toolbarFactory({params: 'foo', query:'', selectedItems: [file], contextId: '1', contextType: 'courses'}));
    ok($(toolbar.getDOMNode()).find('.ui-buttonset .ui-button').length, 'shows multiple select action items');
  });

  test('renders only view and download buttons for limited users', () => {
    const toolbar = TestUtils.renderIntoDocument(toolbarFactory({params: 'foo', query:'', selectedItems: [file], currentFolder: userFolder, contextId: '2', contextType: 'users', userCanManageFilesForContext: false}));
    const config = {
      '.btn-view': true,
      '.btn-download': true,
      '.btn-move': false,
      '.btn-restrict': false,
      '.btn-delete': false,
      '.btn-add-folder': false,
      '.btn-upload': false
    };
    ok(buttonsEnabled($(toolbar.getDOMNode()), config), 'only view and download buttons are shown');
  });

  test('renders all buttons for users with manage_files permissions', ()  => {
    const toolbar = TestUtils.renderIntoDocument(toolbarFactory({params: 'foo', query:'', selectedItems: [file], currentFolder: courseFolder, contextId: '1', contextType: 'courses', userCanManageFilesForContext: true, userCanRestrictFilesForContext: true}));
    const config = {
      '.btn-view': true,
      '.btn-download': true,
      '.btn-move': true,
      '.btn-restrict': true,
      '.btn-delete': true,
      '.btn-add-folder': true,
      '.btn-upload': true
    };
    ok(buttonsEnabled($(toolbar.getDOMNode()), config), 'move, restrict access, delete, add folder, and upload file buttons are additionally shown for users with manage_files permissions');
  });

  test('disables preview button on folder', () => {
    const toolbar = TestUtils.renderIntoDocument(toolbarFactory({params: 'foo', query:'', selectedItems: [userFolder], currentFolder: courseFolder, contextId: '1', contextType: 'courses', userCanManageFilesForContext: true, userCanRestrictFilesForContext: true}));
    const config = {
      '.btn-view': false,
      '.btn-download': true,
      '.btn-move': true,
      '.btn-restrict': true,
      '.btn-delete': true,
      '.btn-add-folder': true,
      '.btn-upload': true
    };
    ok(buttonsEnabled($(toolbar.getDOMNode()), config), 'view button hidden when folder selected');
  });

});
