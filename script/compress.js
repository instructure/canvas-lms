const glob = require('glob');
const computecluster = require('compute-cluster');
const path = require('path');

const clusterOpts = {
  module: path.join(__dirname, 'compress_worker.js'),
  max_backlog: 10000
}
// by default, we'll create a cluster as big as the number of cores on your machine,
// set the CANVAS_BUILD_CONCURRENCY environment variable if you want it to be something else
if (process.env.CANVAS_BUILD_CONCURRENCY) { clusterOpts.max_processes = parseInt(process.env.CANVAS_BUILD_CONCURRENCY); }

// allocate a compute cluster
const cc = new computecluster(clusterOpts);

const files = glob.sync('public/optimized/compiled/{*.js,**/*.js}');
let toRun = files.length;

for (let i = 0; i < files.length; i++) {
  cc.enqueue(files[i], (err, r) => {
    if (err) return console.log('an error occured:', err);
    if (--toRun === 0) {
      console.log(`${files.length}files minified`)
      cc.exit();
    }
  });
}
