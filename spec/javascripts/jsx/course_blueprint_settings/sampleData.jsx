define([], () => ({
  terms: [
    { id: '1', name: 'Term One' },
    { id: '2', name: 'Term Two' },
  ],
  subAccounts: [
    { id: '1', name: 'Account One' },
    { id: '2', name: 'Account Two' },
  ],
  courses: [
    {
      id: '1',
      name: 'Course One',
      course_code: 'course_1',
      term: {
        id: '1',
        name: 'Term One',
      },
      teachers: [{
        display_name: 'Teacher One',
      }],
      sis_course_id: '1001',
    },
    {
      id: '2',
      name: 'Course Two',
      course_code: 'course_2',
      term: {
        id: '2',
        name: 'Term Two',
      },
      teachers: [{
        display_name: 'Teacher Two',
      }],
      sis_course_id: '1001',
    }
  ],
}))
