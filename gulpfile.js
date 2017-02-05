const gulp = require('gulp')
const gulpPlugins = require('gulp-load-plugins')()

const DIST = 'public/dist'

const STUFF_TO_REV = [
  'public/fonts/**/*',
  'public/images/**/*',

  // These are things we javascript_include_tag(...) directly from rails
  'public/javascripts/vendor/require.js',
  'public/optimized/vendor/require.js',
  'public/javascripts/vendor/ie11-polyfill.js',
  'public/javascripts/vendor/lato-fontfaceobserver.js',

  // when using webpack, we put a script tag for these directly on the page out-of-band from webpack
  'public/javascripts/vendor/timezone/**/*',

  // But for all other javascript, we only load stuff using js_bundle.
  // Meaning that we only include stuff in the "bundles" dir from rails.
  // In prod, the 'optimized' versions of these bundles will include all their deps
  'public/javascripts/compiled/bundles/**/*',
  'public/optimized/compiled/bundles/**/*',
  'public/javascripts/plugins/*/compiled/bundles/**/*',
  'public/optimized/plugins/*/compiled/bundles/**/*',

  // Special Cases:

  // These files have links in their css to images from their own dir
  'public/javascripts/vendor/slickgrid/**/*',
  'public/javascripts/symlink_to_node_modules/tinymce/skins/lightgray/**/*',

  // Include *everything* from plugins & client_apps
  // so we don't have to worry about their internals
  'public/plugins/**/*',
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
