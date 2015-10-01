// we have these mini apps in "client_apps" that used to be ember apps that
// got built on their own before the primary build ran.  This Plugin
// takes care of taking their package-specific shims that require Core
// javascript from canvas, as well as dealing with a few other client-app-specific
// config issues.

var clientAppPlugin = function(){};

clientAppPlugin.prototype.apply = function(compiler){

  compiler.plugin("normal-module-factory", function(nmf) {

    // the client apps have common js files that depend upon config files.
    // the config files are named the same per app, and the common files "require"
    // a non-existant path that maps to one of the mini app config files.  this
    // context tracks which app we're compiling right now so we can rewrite config
    // requests to the correct app.  Probably the best long term approach is
    // to have the apps themselves pass in their config objects to the constructors
    // of the common code rather than doing these kind of opaque path rewrites
    var appContext = "";

    nmf.plugin("before-resolve", function(result, callback) {
      request = result.request;

      // client apps are using a jsx plugin for require js; we have a JSX
      // loader for webpack so we can just ditch the loader prefix
      if(/^jsx!/.test(request)){
        request = request.replace("jsx!", "");
      }

      // client apps had to wrap this file with their own dependency mapping.
      // Since webpack knows where to find all the dependencies, we can just load
      //  the core canvas jquery plugin directly.
      if(/jquery\/instructure_date_and_time/.test(request)){
        request = request.replace(/jquery\/instructure_date_and_time/, "jquery.instructure_date_and_time");
      }

      var newRequest = request;

      if(/^canvas_quizzes\/apps/.test(request)){
        // when a core app js file loads a client app (canvas_quizzes/app/statistics), rather than
        // requiring the pre-built file (client_apps/dist/canvas_quizzes/apps/statistics.js)
        // this reaches into it's respective
        // "main" file for the app (client_apps/canvas_quizzes/apps/statistics/js/main)
        // to compile from source (canvas).  It also sets
        // the app context so subsequent requires get the right config files.
        //  (see appContext above for more on that)
        appContext = request + "/js/";
        newRequest = request + "/js/main";
      } else if(/^app\/config\/environments/.test(request)){
        // rewrite abstract config file requires (like app/config/environments/production)
        // to the right app context for the current require tree (like canvas_quizzes/apps/statistics/js/config/environments/production)
        newRequest = appContext + request.replace("app/", "");
      } else if(/^canvas\/vendor\//.test(request)){
        // client apps would prefix canvas vendor files with "canvas" and map them across.
        // webpack knows where to look for vendor files, so we can ditch the prefix
        // and let it resolve normally.
        newRequest = request.replace(/^canvas\/vendor\//, '');
      } else if(/^canvas_quizzes/.test(request)) {
        // client apps have a set of common js files they share, prefixed by "canvas_quizzes".
        // here we sniff those requires and rewrite them to the directory where the common
        // javascript source files live.
        newRequest = request.replace("canvas_quizzes", "canvas_quizzes/apps/common/js");
      } else if(/^canvas_packages/.test(request)){
        // client apps would prefix canvas core js files with "canvas_packages" and map them across.
        // webpack knows where to look for canvas core files, so we can ditch the prefix
        // and let it resolve normally.
        newRequest = request.replace("canvas_packages/", "");
      }
      result.request = newRequest;
      return callback(null, result);
    });
  });

};


module.exports = clientAppPlugin;
