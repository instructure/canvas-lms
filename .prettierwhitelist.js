function appAndSpecDirsFor(dir) {
  return `{app/jsx,app/coffeescripts,spec/javascripts/jsx,spec/coffeescripts}/${dir}/**/*.js`
}

function appAndSpecFilesFor(path) {
  return `{app/jsx,app/coffeescripts,spec/javascripts/jsx,spec/coffeescripts}/${path}{,Spec}.js`
}

// If you are starting a new project or section of greenfield code,
// or if there is a folder of code that your team controls that you want
// to start ensuring conforms to prettier, add it to this array to opt-in
// now to conform to prettier.
const PRETTIER_WHITELIST = (module.exports = [
  './*.js',
  'app/jsx/**/*.js',
  'app/coffeescripts/**/*.js',
  'spec/**/*.js',
  'frontend_build/**/*.js',
  'public/javascripts/**/*.js',
  'packages/canvas-media/src/**/*.js',
  'script/**/*.js',
  'app/jsx/account_settings/**/*.js',
  'app/jsx/course_settings/**/*.js',
  'app/coffeescripts/ember/**/*.js',
  'public/javascripts/page_views.js',
  'public/javascripts/speed_grader*.js',
  'spec/javascripts/jsx/spec-support/**/*.js',
  'public/javascripts/tinymce_plugins/instructure_external_tools/*.js',
  'app/jsx/editor/*.js',
  appAndSpecDirsFor('account_course_user_search'),
  appAndSpecDirsFor('announcements'),
  appAndSpecDirsFor('assignments/GradeSummary'),
  appAndSpecDirsFor('assignments_2'),
  appAndSpecDirsFor('content_shares'),
  appAndSpecDirsFor('dashboard_card'),
  appAndSpecDirsFor('discussions'),
  appAndSpecDirsFor('editor'),
  appAndSpecDirsFor('gradebook'),
  appAndSpecDirsFor('gradezilla'),
  appAndSpecDirsFor('gradebook-history'),
  appAndSpecDirsFor('grading'),
  appAndSpecDirsFor('help_dialog'),
  appAndSpecDirsFor('login'),
  appAndSpecDirsFor('permissions'),
  appAndSpecDirsFor('shared/components'),
  appAndSpecDirsFor('shared/direct_share'),
  appAndSpecDirsFor('speed_grader'),
  appAndSpecDirsFor('theme_editor')
])
