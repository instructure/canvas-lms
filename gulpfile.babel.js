const gulp = require('gulp')
const gulpPlugins = require('gulp-load-plugins')()

const DIST = 'public/dist'
const PUBLIC_NOT_DIST = ['public/**/*', '!' + DIST + '/**/*']

gulp.task('rev', function() {
  return gulp.src(PUBLIC_NOT_DIST)
    .pipe(gulp.dest(DIST))
    .pipe(gulpPlugins.rev())
    .pipe(gulp.dest(DIST))
    .pipe(gulpPlugins.rev.manifest())
    .pipe(gulp.dest(DIST))
})

gulp.task('watch', function (){
  gulp.watch(PUBLIC_NOT_DIST, ['rev'])
})

gulp.task('default', ['rev', 'watch'])
