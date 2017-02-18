define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/add_people/components/add_people',
], (React, ReactDOM, TestUtils, AddPeople) => {
  module('AddPeople')

  const props = {
    isOpen: true,
    courseParams: {
      courseId: '1',
      defaultInstitutionName: "Ed's House",
      inviteUsersURL: '/courses/#/invite_users',
      roles: [
        {
          base_role_name: 'StudentEnrollment',
          name: 'StudentEnrollment',
          label: 'Student',
          plural_label: 'Students',
          id: '3',
          count: 7,
          manageable_by_user: true
        },
        {
          base_role_name: 'TeacherEnrollment',
          name: 'TeacherEnrollment',
          label: 'Teacher',
          plural_label: 'Teachers',
          id: '4',
          count: 1,
          manageable_by_user: true
        },
        {
          base_role_name: 'TaEnrollment',
          name: 'TaEnrollment',
          label: 'TA',
          plural_label: 'TAs',
          id: '5',
          count: 0,
          manageable_by_user: true
        },
        {
          base_role_name: 'DesignerEnrollment',
          name: 'DesignerEnrollment',
          label: 'Designer',
          plural_label: 'Designers',
          id: '6',
          count: 0,
          manageable_by_user: true
        },
        {
          base_role_name: 'ObserverEnrollment',
          name: 'ObserverEnrollment',
          label: 'Observer',
          plural_label: 'Observers',
          id: '7',
          count: 0,
          manageable_by_user: true
        }
      ],
      sections: [
        {
          id: '8',
          name: 'Section'
        },
        {
          id: '5',
          name: 'Section 0'
        },
        {
          id: '6',
          name: 'Section 1'
        },
        {
          id: '7',
          name: 'Section 2'
        },
        {
          id: '9',
          name: 'Section 10'
        },
        {
          id: '10',
          name: 'Section 20'
        },
        {
          id: '11',
          name: 'Section 21'
        },
        {
          id: '12',
          name: 'Section 22'
        },
        {
          id: '2',
          name: 'Section A'
        },
        {
          id: '3',
          name: 'Section b'
        },
        {
          id: '4',
          name: 'Section c'
        },
        {
          id: '1',
          name: 'work 101'
        }
      ]
    },
    apiState: {
      isPending: 0
    },
    inputParams: {
      searchType: 'cc_path',
      nameList: [],
      role: '',
      section: ''
    },
    userValidationResult: {
      validUsers: [],
      duplicates: {},
      missing: {}
    },
    usersToBeEnrolled: [],
    usersEnrolled: false
  };
  const noop = function () {};

  test('renders the component', () => {
    TestUtils.renderIntoDocument(<AddPeople {...props} validateUsers={noop} enrollUsers={noop} onClose={noop} />);
    // can't use TestUtils.findRenderedDOMComponentWithClass, because it's a Modal and actually gets rendered elsewhere in the DOM
    const addPeople = document.querySelectorAll('.addpeople');
    equal(addPeople.length, 1, 'AddPeople component rendered.');
  });
});
