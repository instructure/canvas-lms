define([
  'i18n!account_course_user_search',
  '../CoursesPane',
  '../UsersPane',
], function(I18n, CoursesPane, UsersPane) {

  const tabs = [
    {
      title: I18n.t('Courses'),
      pane: CoursesPane,
      path: '/courses',
      permissions: ['can_read_course_list']
    },
    {
      title: I18n.t('People'),
      pane: UsersPane,
      path: '/people',
      permissions: ['can_read_roster']
    }
  ];


  return tabs;
});
