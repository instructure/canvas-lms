define([
  '../../../compiled/react_files/mockFilesENV',
  'react',
  'jquery',
  'jsx/files/ItemCog',
  'compiled/models/Folder'
], (mockFilesENV, React, $, ItemCog, Folder) => {
  const { TestUtils } = React.addons;
  const { Simulate } = TestUtils;

  let itemCog = null;
  let fakeServer = null;

  const readOnlyConfig = {
    download: true,
    editName: false,
    restrictedDialog: false,
    move: false,
    deleteLink: false
  };

  const manageFilesConfig = {
    download: true,
    editName: true,
    usageRights: true,
    move: true,
    deleteLink: true
  };

  const buttonsEnabled = (itemCog, config) => {
    let valid = true;
    for (const prop in config) {
      let button = null;
      if (itemCog.refs && itemCog.refs[prop]) {
        button = $(itemCog.refs[prop].getDOMNode()).length;
      } else {
        button = false;
      }
      if ((config[prop] && !!button) || (!config[prop] && !button)) {
        continue;
      } else {
        valid = false;
      }
    }
    return valid;
  };

  const sampleProps = (canManageFiles = false) => {
    return {
      model: new Folder({id: 999}),
      modalOptions: {
        closeModal () {},
        openModal () {}
      },
      startEditingName () {},
      userCanManageFilesForContext: canManageFiles,
      usageRightsRequiredForContext: true
    };
  };

  module('ItemCog', {
    setup () {
      itemCog = React.render(<ItemCog {...sampleProps(true)} />, $('<div>').appendTo('#fixtures')[0]);
    },
    teardown () {
      React.unmountComponentAtNode(React.findDOMNode(itemCog).parentNode);
      $('#fixtures').empty();
    }
  });


  test('deletes model when delete link is pressed', () => {
    const ajaxSpy = sinon.spy($, 'ajax');
    sinon.stub(window, 'confirm').returns(true);
    Simulate.click(React.findDOMNode(itemCog.refs.deleteLink));
    ok(window.confirm.calledOnce, 'confirms before deleting');
    ok(ajaxSpy.calledWithMatch({url: '/api/v1/folders/999', type: 'DELETE', data: {force: 'true'}}), 'sends DELETE to right url');
    $.ajax.restore();
    window.confirm.restore();
  });

  test('only shows download button for limited users', () => {
    const readOnlyItemCog = React.render(<ItemCog {...sampleProps(false)} />, $('<div>').appendTo('#fixtures')[0]);
    ok(buttonsEnabled(readOnlyItemCog, readOnlyConfig), 'only download button is shown');
  });

  test('shows all buttons for users with manage_files permissions', () => {
    ok(buttonsEnabled(itemCog, manageFilesConfig), 'all buttons are shown');
  });

  test('downloading a file returns focus back to the item cog', () => {
    Simulate.click(React.findDOMNode(itemCog.refs.download));
    equal(document.activeElement, $(React.findDOMNode(itemCog)).find('.al-trigger')[0], 'the cog has focus');
  });

  test('deleting a file returns focus to the previous item cog when there are more items', () => {
    const props = sampleProps(true);
    props.model.destroy = function () { return true; };
    sinon.stub(window, 'confirm').returns(true);
    const itemCogs = React.render(
      <div>
        <ItemCog {...props} />
        <ItemCog {...props} />
      </div>, $('<div>').appendTo('#fixtures')[0]);
    const renderedCogs = TestUtils.scryRenderedComponentsWithType(itemCogs, ItemCog)
    Simulate.click(React.findDOMNode(renderedCogs[1].refs.deleteLink));
    equal(document.activeElement, $(React.findDOMNode(renderedCogs[0])).find('.al-trigger')[0], 'the cog has focus');
    window.confirm.restore();
  });

  test('deleting a file returns focus to the name column header when there are no items left', () => {
    $('#fixtures').empty();
    const props = sampleProps(true);
    props.model.destroy = function () { return true; };
    sinon.stub(window, 'confirm').returns(true);
    const container = React.render(
      <div>
        <div className="ef-name-col">
          <a href="#" className="someFakeLink">Name column header</a>
        </div>
        <ItemCog {...props} />
      </div>, $('<div>').appendTo('#fixtures')[0]);
    const renderedCog = TestUtils.findRenderedComponentWithType(container, ItemCog);
    Simulate.click(React.findDOMNode(renderedCog.refs.deleteLink));
    equal(document.activeElement, $('.someFakeLink')[0], 'the name column has focus');
    window.confirm.restore();
  });

});
