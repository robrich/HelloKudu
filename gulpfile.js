/*eslint-env node */
/*eslint strict: [2, 'global'], no-console: 0*/
'use strict';

var gulp = require('gulp');
var minifyCss = require('gulp-minify-css');
var uglify = require('gulp-uglify');

gulp.on('err', function (e) {
  console.log();
  var msg = e && e.err && e.err.message || JSON.stringify(e);
  console.log('Gulp build failed: '+msg);
  process.exit(1);
});

gulp.task('jsmin', function () {
    return gulp.src('src/Web/js/*.js', { base: '.' })
        .pipe(uglify())
        .pipe(gulp.dest('.'));
});

gulp.task('cssmin', function () {
  return gulp.src('src/Web/css/*.css', { base: '.' })
    .pipe(minifyCss())
    .pipe(gulp.dest('.'));
});

gulp.task('default', ['jsmin', 'cssmin']);
