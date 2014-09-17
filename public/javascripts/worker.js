/**
 * Adapted from https://github.com/chadly/requirejs-web-workers
 *
 * Lazily load a Web Worker script, if the browser supports it.
 *
 * Returns a function that returns an instance of Worker when invoked, if
 * browser support exists. Otherwise (< IE10), null will be returned.
 *
 * === Usage example
 *
 *     // file: /public/javascripts/my_namespace/my_worker.js
 *     self.addEventListener('message', function onMessage(msg) {
 *       // ...
 *     });
 *
 *     // file: /public/javascripts/my_namespace/my_consumer.js
 *     define([ 'worker!/my_namespace/my_worker' ], function(MyWorkerFactory) {
 *       if (MyWorkerFactory) {
 *         var myWorker = new MyWorkerFactory();
 *         
 *         myWorker.postMessage("it's alive!!!");
 *       }
 *       else {
 *         // fallback code, Web Workers are not available
 *       }
 *     });
 *
 * Copyright (c) 2013 Chad Lee
 * Copyright (c) 2014 Instructure, INC.
 *
 * License: MIT
 */
define([], function() {
  return {
    version: "1.0.0",
    load: function (name, req, onLoad, config) {
      var workerUrl;

      if (config.isBuild) {
        // don't do anything if this is a build, can't inline a web worker
        onLoad();
        return;
      }

      workerUrl = req.toUrl(name + '.js');

      if ('Worker' in window) {
        onLoad(function generateWorker() {
          return new Worker(workerUrl);
        });
      } else {
        onLoad(null);
      }
    }
  };
});