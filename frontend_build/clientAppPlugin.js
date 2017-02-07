// we have these mini apps in "client_apps" that used to be ember apps that
// got built on their own before the primary build ran.  This Plugin
// takes care of taking their package-specific shims that require Core
// javascript from canvas, as well as dealing with a few other client-app-specific
// config issues.

class clientAppPlugin {
  apply (compiler) {
    compiler.plugin('normal-module-factory', nmf => {
      nmf.plugin('before-resolve', (result, callback) => {
        let request = result.request

        if (/client_apps\/canvas_quizzes/.test(result.context)) {
          // The client apps depend on requiring lodash directly, which was set to
          // map to lodash.underscore prior to 37914f705ee4055224107f01f0afb772d443f90d
          // which added up-to-date normal lodash via 'lodash'
          if (request === 'lodash') {
            request = 'underscore'
          }
        }

        // client apps are using a jsx plugin for require js; we have a JSX
        // loader for webpack so we can just ditch the loader prefix
        if (/^jsx!/.test(request)) {
          request = request.replace('jsx!', '')
        }

        // client apps had to wrap this file with their own dependency mapping.
        // Since webpack knows where to find all the dependencies, we can just load
        //  the core canvas jquery plugin directly.
        if (/jquery\/instructure_date_and_time/.test(request)) {
          request = request.replace(/jquery\/instructure_date_and_time/, 'jquery.instructure_date_and_time')
        }

        let newRequest = request

        if (/^canvas_quizzes\/apps\/[^/]+$/.test(request)) {
          // when a core app js file loads a client app (canvas_quizzes/app/statistics), rather than
          // requiring the pre-built file (client_apps/dist/canvas_quizzes/apps/statistics.js)
          // this reaches into it's respective
          // "main" file for the app (client_apps/canvas_quizzes/apps/statistics/js/main)
          // to compile from source (canvas).
          newRequest = request + '/js/main'
        } else if (/^canvas\/vendor\//.test(request)) {
          // client apps would prefix canvas vendor files with "canvas" and map them across.
          // webpack knows where to look for vendor files, so we can ditch the prefix
          // and let it resolve normally.
          newRequest = request.replace(/^canvas\/vendor\//, '')
        } else if (/^canvas_quizzes/.test(request)) {
          // client apps have a set of common js files they share, prefixed by "canvas_quizzes".
          // here we sniff those requires and rewrite them to the directory where the common
          // javascript source files live.
          newRequest = request.replace('canvas_quizzes', 'canvas_quizzes/apps/common/js')
        } else if (/^canvas_packages/.test(request)) {
          // client apps would prefix canvas core js files with "canvas_packages" and map them across.
          // webpack knows where to look for canvas core files, so we can ditch the prefix
          // and let it resolve normally.
          newRequest = request.replace('canvas_packages/', '')
        }

        // each client app requests the common client app config, but it's
        // not very webpack-friendly.  This replaces those requests with webpack
        // specific shims that do the same work without sharing a config file that
        // has to know how to dynamically require similarly named files from different
        // apps based on context.
        if (/^canvas_quizzes\/config$/.test(result.request)) {
          if (/apps\/statistics\/js/.test(result.context)) {
            newRequest = 'canvas_quizzes/apps/statistics/js/webpack_config'
          } else if (/apps\/events\/js/.test(result.context)) {
            newRequest = 'canvas_quizzes/apps/events/js/webpack_config'
          }
        }

        result.request = newRequest
        return callback(null, result)
      })
    })
  }
}

module.exports = clientAppPlugin
