define([
  'react',
  'enzyme',
  'jsx/account_course_user_search/CoursesList',
  'jsx/account_course_user_search/CoursesListRow'
], (React, {shallow}, CoursesList, CoursesListRow) => {
  QUnit.module('Account Course User Search CoursesList View');

  const props = {
    courses: [{
      id: '123',
      name: 'this is a name',
      workflow_state: 'alive',
      total_students: 6,
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
    const wrapper = shallow(<CoursesList {...props} />)

    const renderedList = wrapper.find(CoursesListRow)
    const renderedUrls = renderedList.props().urls;
    deepEqual(renderedUrls, {
      USER_LISTS_URL: 'http://courses/123/users',
      ENROLL_USERS_URL: 'http://courses/123/users/enroll'
    }, 'it passed url props in and they were replaced properly');
  });
});
