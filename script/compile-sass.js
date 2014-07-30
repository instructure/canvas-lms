const computecluster = require('compute-cluster');
const glob = require('glob');
const path = require('path');
const mkdirp = require('mkdirp');

var clusterOpts = {
  module:  path.join(__dirname, "compile-sass_worker.js"),
  max_backlog: 10000
}

// You can run this with with `node script/compile-sass.js app/stylesheets/jst/something.scss to compile a specific file.
var sassFileToConvert = process.argv[2];
var sassFiles = sassFileToConvert ? [sassFileToConvert] : glob.sync("app/stylesheets/{,plugins/*/}**/[^_]*.s[ac]ss");


// by default, we'll create a cluster as big as the number of cores on your machine,
// set the CANVAS_BUILD_CONCURRENCY environment variable if you want it to be something else
if (process.env.CANVAS_BUILD_CONCURRENCY) clusterOpts.max_processes = parseInt(process.env.CANVAS_BUILD_CONCURRENCY);
// if we're just doing one file, just spin up one worker
if (sassFileToConvert) clusterOpts.max_processes = 1;
var cc = new computecluster(clusterOpts);

const VARIANTS = 'legacy_normal_contrast legacy_high_contrast new_styles_normal_contrast new_styles_high_contrast k12_normal_contrast k12_high_contrast'.split(' ')

var toRun = 0;
VARIANTS.forEach(function(variant){
  sassFiles.forEach(function(sassFile){
    // TODO: figure out how to exclude app/stylesheets/jst from the glob when running everything.
    if (sassFile.match(/^app\/stylesheets\/jst/) && (!sassFileToConvert || variant !== 'legacy_normal_contrast')) return;

    toRun++
    cc.enqueue([variant, sassFile], function(err,r){
      if (err) return console.log("an error occured compiling sass:", err);
      if (--toRun === 0) {
        cc.exit();
      }
    })
  })
})

