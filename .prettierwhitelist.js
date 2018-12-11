function appAndSpecDirsFor(dir) {
  return `{app/jsx,app/coffeescripts,spec/javascripts/jsx,spec/coffeescripts}/${dir}/**/*.js`
}

// If you are starting a new project or section of greenfield code,
// or if there is a folder of code that your team controls that you want
// to start ensuring conforms to prettier, add it to this array to opt-in
// now to conform to prettier.
const PRETTIER_WHITELIST = module.exports =  [
  './*.js',
  'app/jsx/*.js',
  'frontend_build/**/*.js',
  'script/**/*.js',
  'app/jsx/account_settings/**/*.js',
  appAndSpecDirsFor('account_course_user_search'),
  appAndSpecDirsFor('announcements'),
  appAndSpecDirsFor('assignments_2'),
  appAndSpecDirsFor('dashboard_card'),
  appAndSpecDirsFor('discussions'),
  appAndSpecDirsFor('editor'),
  appAndSpecDirsFor('help_dialog'),
  appAndSpecDirsFor('login'),
  appAndSpecDirsFor('permissions'),
  appAndSpecDirsFor('theme_editor')
]
