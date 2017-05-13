define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/add_people/components/add_people',
], (React, ReactDOM, TestUtils, AddPeople) => {
  QUnit.module('AddPeople');

  const props = {
    isOpen: true,
    courseParams: {
      roles: [],
      sections: []
    },
    apiState: {
      isPending: 0
    },
    inputParams: {
      nameList: '',
    }
  };

  test('renders the component', () => {
    const component = TestUtils.renderIntoDocument(
      <AddPeople
        validateUsers={() => {}}
        enrollUsers={() => {}}
        reset={() => {}}
        {...props}
      />
    );
    const addPeople = document.querySelectorAll('.addpeople');
    equal(addPeople.length, 1, 'AddPeople component rendered.');
    component.close();
    ReactDOM.unmountComponentAtNode(component.node._overlay.parentElement);
  });
});
