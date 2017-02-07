define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/add_people/components/people_search',
], (React, ReactDOM, TestUtils, PeopleSearch) => {
  module('PeopleSearch')

  const searchProps = {
    roles: [{id: '1', name: 'Student'}, {id: '2', name: 'TA'}],
    sections: [{id: '1', name: 'section 2'}, {id: '2', name: 'section 10'}],
    section: '1',
    role: '2',
    limitPrivilege: true,
    searchType: 'unique_id',
    nameList: ['foo', 'bar', 'baz'],
    canReadSIS: true
  };

  test('renders the component', () => {
    const component = TestUtils.renderIntoDocument(<PeopleSearch {...searchProps} />);
    const peopleSearch = TestUtils.findRenderedDOMComponentWithClass(component, 'addpeople__peoplesearch');
    ok(peopleSearch)
  });
  test('sets the correct values', () => {
    const component = TestUtils.renderIntoDocument(<PeopleSearch {...searchProps} />);
    const peopleSearch = TestUtils.findRenderedDOMComponentWithClass(component, 'addpeople__peoplesearch');
    const loginRadio = peopleSearch.querySelector('input[type="radio"][value="unique_id"]');
    equal(loginRadio.checked, true, 'login id radio button is checked');
    const nameInput = peopleSearch.querySelector('textarea');
    equal(nameInput.value, 'foo,bar,baz', 'names are in the textarea');
    const selects = peopleSearch.querySelectorAll('.peoplesearch__selections select');
    equal(selects[0].value, '2', 'role 2 is selected');
    equal(selects[1].value, '1', 'section 1 is selected');
    const sections = Array.prototype.map.call(selects[1].options, o => o.innerHTML);
    deepEqual(sections, ['section 2', 'section 10'], 'sections are sorted by name');
    const limitPrivilegeCheckbox = peopleSearch.querySelector('#limit_privileges_to_course_section');
    equal(limitPrivilegeCheckbox.checked, true, 'limit privileges checkbox is checked');
  });
  test('removes search by SIS ID', () => {
    const newProps = Object.assign({}, searchProps);
    newProps.canReadSIS = false;
    const component = TestUtils.renderIntoDocument(<PeopleSearch {...newProps} />);
    const peopleSearch = TestUtils.findRenderedDOMComponentWithClass(component, 'addpeople__peoplesearch');
    const sisRadio = peopleSearch.querySelector('input[type="radio"][value="sis_user_id"]');
    equal(sisRadio, null, 'sis id radio button is not displayed');
  });
});
