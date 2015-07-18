var gulp = require('gulp')
var browserify = require('browserify')
var eslint = require('gulp-eslint')
var eslintConfig = require('./eslint.json')
var source = require('vinyl-source-stream')
var connect = require('gulp-connect')
var cache = require('gulp-cached')

gulp.task('browserify', function() {
  return browserify({
      entries: ['./example/example.js'],
      debug: true
    })
    .bundle()
    .pipe(source('example.js'))
    .pipe(gulp.dest('build'))
})

gulp.task('static', function () {
  return gulp.src(['example/**/*.css', 'example/**/*.html'])
    .pipe(gulp.dest('build'))
})

gulp.task('server', function() {
  connect.server({
    root: ['build'],
    port: process.env.PORT || 1337
  })
})

gulp.task('lint', function () {
  return gulp.src(['lib/**/*.js'])
    .pipe(cache('linting'))
    .pipe(eslint(eslintConfig))
    .pipe(eslint.format())
})

gulp.task('default', ['browserify'])

gulp.task('serve', ['static', 'browserify', 'lint', 'server'], function() {
  gulp.watch(['example/**/*'], ['static', 'browserify'])
  gulp.watch(['lib/**/*'], ['browserify'])
})
