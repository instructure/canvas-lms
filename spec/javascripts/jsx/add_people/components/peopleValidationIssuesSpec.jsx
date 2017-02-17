define([
  'underscore',
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/add_people/components/people_validation_issues',
], (_, React, ReactDOM, TestUtils, PeopleValidationIssues) => {
  QUnit.module('PeopleValidationIssues')

  const duplicates = {
    addr1: {
      address: 'addr1',
      selectedUserId: -1,
      skip: false,
      createNew: false,
      newUserInfo: undefined,
      userList: [{
        address: 'addr1',
        user_id: 1,
        user_name: 'Addr1 User1',
        account_id: 1,
        account_name: 'School of Rock',
        email: 'addr1@foo.com',
        login_id: 'addr1'
      },
      {
        address: 'addr1',
        user_id: 2,
        user_name: 'Addr1 User2',
        account_id: 1,
        account_name: 'School of Rock',
        email: 'addr1@foo.com',
        login_id: 'addr1'
      }]
    },
    addr2: {
      address: 'addr2',
      selectedUserId: -1,
      skip: false,
      createNew: false,
      newUserInfo: undefined,
      userList: [{
        address: 'addr2',
        user_id: 3,
        user_name: 'addr2User',
        account_id: 1,
        account_name: 'School of Rock',
        email: 'addr2@foo.com',
        login_id: 'addr2'
      },
      {
        address: 'addr2',
        user_id: 4,
        user_name: 'addr2User',
        account_id: 1,
        account_name: 'School of Rock',
        email: 'addr2@foo.com',
        login_id: 'addr1'
      }]
    }
  };
  const missing = {
    addr3: {address: 'addr3', type: 'unique_id', createNew: false, newUserInfo: undefined},
    addr4: {address: 'addr4', type: 'unique_id', createNew: true, newUserInfo: {name: 'the name2', email: 'email2'}}
  }
  const noop = function () {};
  const inviteUsersURL = '/courses/#/invite_users';

  test('renders the component', () => {
    const component = TestUtils.renderIntoDocument(
      <PeopleValidationIssues
        duplicates={duplicates}
        missing={missing}
        searchType="unique_id"
        inviteUsersURL={inviteUsersURL}
        onChangeDuplicate={noop}
        onChangeMissing={noop}
      />
    );
    const peopleValidationIssues = TestUtils.findRenderedDOMComponentWithClass(component, 'addpeople__peoplevalidationissues');
    ok(peopleValidationIssues, 'PeopleValidationIssues panel rendered');
    ok(peopleValidationIssues.querySelector('.peopleValidationissues__duplicates'), 'duplicates section rendered');
    ok(peopleValidationIssues.querySelector('.peoplevalidationissues__missing'), 'missing section rendered');
    const dupeSets = peopleValidationIssues.querySelectorAll('.peopleValidationissues__duplicates .namelist');
    equal(dupeSets.length, 2, 'there are 2 sets of duplicates');
  });
})
