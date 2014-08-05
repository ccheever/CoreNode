var child_process = require('child_process');
var path = require('path');

var gulp = require('gulp');
var concat = require('gulp-concat');

var paths = {
  options: {cwd: path.join(__dirname, '..')},
  nodeLib: [
    'CoreNode/js/{node,iOS}.js',
    'CoreNode/js/node-lib/*.js',
  ],
  fsModule: [
    'CoreNode/js/node-lib/fs.js',
    'CoreNode/js/ios-lib/_fs-coda.js',
  ],
};


gulp.task('embed-sources', function(callback) {
  child_process.exec('./generate_natives.py', function(error, stdout, stderr) {
    if (stdout) {
      console.log(stdout);
    }

    if (stderr) {
      console.error(stderr);
    }

    if (error) {
      var err = new Error(stderr);
      err.code = error;
    }
    callback(err);
  });
});

gulp.task('watch-node-lib', function() {
  gulp.watch(paths.nodeLib, paths.options, ['embed-sources']);
});

gulp.task('build-fs-module', function() {
  gulp.src(paths.fsModule, paths.options)
    .pipe(concat('fs.js'))
    .pipe(gulp.dest('CoreNode/js/ios-lib', paths.options))
    ;
});

gulp.task('watch-fs-module', function() {
  gulp.watch(paths.fsModule, paths.options, ['build-fs-module']);
});

gulp.task('default', ['build-fs-module', 'embed-sources', 'watch-node-lib', 'watch-fs-module']);
