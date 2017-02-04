define([
  'underscore',
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/add_people/components/duplicate_section',
], (_, React, ReactDOM, TestUtils, DuplicateSection) => {
  QUnit.module('DuplicateSection')

  const duplicates = {
    address: 'addr1',
    selectedUserId: -1,
    skip: false,
    createNew: false,
    newUserInfo: undefined,
    userList: [{
      address: 'addr1',
      user_id: 1,
      user_name: 'addr1User',
      account_id: 1,
      account_name: 'School of Rock',
      email: 'addr1@foo.com',
      login_id: 'addr1'
    }, {
      address: 'addr1',
      user_id: 2,
      user_name: 'addr2User',
      account_id: 1,
      account_name: 'School of Rock',
      email: 'addr2@foo.com',
      login_id: 'addr1'
    }]
  };
  const noop = function () {};

  test('renders the component', () => {
    const component = TestUtils.renderIntoDocument(
      <DuplicateSection duplicates={duplicates} onSelectDuplicate={noop} onNewForDuplicate={noop} onSkipDuplicate={noop} />
    );
    const duplicateSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist');
    ok(duplicateSection);
  });

  test('renders the table', () => {
    const component = TestUtils.renderIntoDocument(
      <DuplicateSection duplicates={duplicates} onSelectDuplicate={noop} onNewForDuplicate={noop} onSkipDuplicate={noop} />
    );
    const duplicateSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist');

    const rows = duplicateSection.querySelectorAll('tr');
    equal(rows.length, 5, 'five rows');
    const headings = rows[0].querySelectorAll('th');
    equal(headings.length, 6, 'six column headings');
    const createUserBtn = rows[3].querySelectorAll('td')[1].firstChild;
    equal(createUserBtn.tagName, 'BUTTON', 'create new user button');
    const skipUserBtn = rows[4].querySelectorAll('td')[1].firstChild;
    equal(skipUserBtn.tagName, 'BUTTON', 'skip user button');
  });
  test('select a user', () => {
    const dupes = _.cloneDeep(duplicates);
    dupes.selectedUserId = 2;
    const component = TestUtils.renderIntoDocument(
      <DuplicateSection duplicates={dupes} onSelectDuplicate={noop} onNewForDuplicate={noop} onSkipDuplicate={noop} />
    );
    const duplicateSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist');

    const rows = duplicateSection.querySelectorAll('tr');
    const radio1 = rows[1].querySelector('input[type="radio"]');
    const radio2 = rows[2].querySelector('input[type="radio"]');
    equal(radio1.checked, false, 'user 1 not selected');
    equal(radio2.checked, true, 'user 2 selected');
  });
  test('create a user', () => {
    const dupes = _.cloneDeep(duplicates);
    dupes.createNew = true;
    dupes.newUserInfo = {name: 'bob', email: 'bob@em.ail'}
    const component = TestUtils.renderIntoDocument(
      <DuplicateSection duplicates={dupes} onSelectDuplicate={noop} onNewForDuplicate={noop} onSkipDuplicate={noop} />
    );
    const duplicateSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist');

    const rows = duplicateSection.querySelectorAll('tr');
    const nameInput = rows[3].querySelector('input[type="text"]');
    ok(nameInput, 'name input exists');
    equal(nameInput.value, 'bob', 'name has correct value')
    const emailInput = rows[3].querySelector('input[type="email"]');
    ok(emailInput, 'email input', 'email input exists');
    equal(emailInput.value, 'bob@em.ail', 'email has correct value');
  });
  test('create a user', () => {
    const dupes = _.cloneDeep(duplicates);
    dupes.skip = true;
    const component = TestUtils.renderIntoDocument(
      <DuplicateSection duplicates={dupes} onSelectDuplicate={noop} onNewForDuplicate={noop} onSkipDuplicate={noop} />
    );
    const duplicateSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist');

    const rows = duplicateSection.querySelectorAll('tr');
    const skipUserRadioBtn = rows[4].querySelector('input[type="radio"]');
    equal(skipUserRadioBtn.checked, true, 'duplicate set skipped');
  });
})
