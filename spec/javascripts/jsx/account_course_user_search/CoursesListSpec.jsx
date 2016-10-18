define([
  'react',
  'react-addons-test-utils',
  'jsx/account_course_user_search/CoursesList'
], (React, TestUtils, CoursesList) => {

  module('Account Course User Search CoursesList View');

  const props = {
    courses: [{
      id: '123',
      teachers: [{
        id: '1',
        display_name: 'Testing Teacher'
      }]
    }],
    addUserUrls: {
      USER_LISTS_URL: 'http://courses/{{id}}/users',
      ENROLL_USERS_URL: 'http://courses/{{id}}/users/enroll'
    },
    roles: [{
      course_id: '1',
      roles: [{
        base_role_type: 'StudentEnrollment'
      }]
    }]
  };

  test('renders with the proper urls and roles', () => {

    const component = TestUtils.renderIntoDocument(<CoursesList {...props} />);

    const renderedList = TestUtils.findRenderedDOMComponentWithClass(component, 'courses-list')
    const renderedUrls = renderedList.props.children[0].props.urls;
    deepEqual(renderedUrls, {
      USER_LISTS_URL: 'http://courses/123/users',
      ENROLL_USERS_URL: 'http://courses/123/users/enroll'
    }, 'it passed url props in and they were replaced properly');
  });
});