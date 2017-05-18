const gulp = require('gulp')
const gulpPlugins = require('gulp-load-plugins')()

const DIST = 'public/dist'

const STUFF_TO_REV = [
  'public/fonts/**/*.{eot,otf,svg,ttf,woff,woff2}',
  'public/images/**/*',

  // These are things we javascript_include_tag(...) directly from rails
  'public/javascripts/vendor/require.js',
  'public/optimized/vendor/require.js',
  'public/javascripts/vendor/ie11-polyfill.js',
  'public/javascripts/vendor/lato-fontfaceobserver.js',

  // this is used by the include_account_js call in mobile_auth.html.erb to make sure '$' is there for accounts' custom js files
  'public/javascripts/symlink_to_node_modules/jquery/jquery.js',

  // when using webpack, we put a script tag for these directly on the page out-of-band from webpack
  'public/javascripts/vendor/timezone/**/*',


  // Special Cases:

  // These files have links in their css to images from their own dir
  'public/javascripts/vendor/slickgrid/**/*',
  'public/javascripts/symlink_to_node_modules/tinymce/skins/lightgray/**/*',

  // Include *everything* from plugins & client_apps
  // so we don't have to worry about their internals
  // TODO: do we need these if we are all-webpack?
  'public/plugins/**/*.*',
  'public/javascripts/client_apps**/*',
]


gulp.task('rev', function(){
  gulp.src(STUFF_TO_REV, {
    base: 'public', // tell it to use the 'public' folder as the base of all paths
    follow: true // follow symlinks, so it picks up on images inside plugins and stuff
  })
  .pipe(gulpPlugins.rev())
  .pipe(gulp.dest(DIST))
  .pipe(gulpPlugins.rev.manifest())
  .pipe(gulp.dest(DIST))
})

gulp.task('watch', function(){
  gulp.watch(STUFF_TO_REV, ['rev'])
})

gulp.task('default', ['rev', 'watch'])
