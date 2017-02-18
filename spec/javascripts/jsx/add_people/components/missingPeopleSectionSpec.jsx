define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/add_people/components/missing_people_section',
], (React, ReactDOM, TestUtils, MissingPeopleSection) => {
  module('MissingPeopleSection')

  const missing = {
    addr1: {address: 'addr1', type: 'unique_id', createNew: false, newUserInfo: undefined},
    addr2: {address: 'addr2', type: 'unique_id', createNew: true, newUserInfo: {name: 'the name2', email: 'email2'}}
  }
  const noop = function () {};
  const inviteUsersURL = '/courses/#/invite_users';

  test('renders the component', () => {
    const component = TestUtils.renderIntoDocument(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={inviteUsersURL}
        missing={missing}
        onChange={noop}
      />)
    const missingPeopleSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')
    ok(missingPeopleSection)
  });

  test('renders the table', () => {
    const component = TestUtils.renderIntoDocument(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={inviteUsersURL}
        missing={missing}
        onChange={noop}
      />)
    const missingPeopleSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')

    const rows = missingPeopleSection.querySelectorAll('tr');
    equal(rows.length, 3, 'three rows')
    const headings = rows[0].querySelectorAll('th');
    equal(headings.length, 4, 'four column headings');
    const createUserBtn = rows[1].querySelectorAll('td')[1].firstChild;
    equal(createUserBtn.tagName, 'BUTTON', 'create new user button');
    const nameInput = rows[2].querySelector('input[type="text"]');
    ok(nameInput, 'name input');
    const emailInput = rows[2].querySelector('input[type="email"]');
    ok(emailInput, 'email input');
  });
  test('cannot create users', () => {
    const component = TestUtils.renderIntoDocument(
      <MissingPeopleSection
        searchType="unique_id"
        inviteUsersURL={undefined}
        missing={missing}
        onChange={noop}
      />)
    const missingPeopleSection = TestUtils.findRenderedDOMComponentWithClass(component, 'namelist')

    const createUserBtn = missingPeopleSection.querySelector('button');
    equal(createUserBtn, null, 'create new user button');
  })
})
