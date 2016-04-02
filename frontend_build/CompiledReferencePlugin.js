// We have a lot of references to "compiled" directories right now,
// but since webpack can load and compile coffeescript on the fly,
// we can just use a coffeescript loader.  The problem, though, is
// that we don't want to have to change the current references everywhere,
// and it's technically possible to have naming conflicts today.
// to bridge the gap, we'll add "app" to the search path for webpack in
// the config, and replace "compiled" references with "coffeescripts" in The
// path, which should both differentiate them from files in the public/javascripts
// directory with the same name, and load them directly rather than needing
// a compile step ahead of time.

var CompiledReferencePlugin = function(){};
var pluginTranspiledRegexp = /^([^/]+)\/compiled\//;

var rewritePluginPath = function(requestString){
  var pluginName = pluginTranspiledRegexp.exec(requestString)[1];
  var jsxRegexp = /compiled\/jsx/;
  var relativePath = requestString.replace(pluginName + "/compiled/", "");
  if(jsxRegexp.test(requestString)){
    // this references a JSX file which already has "jsx" in it's file path
    return pluginName + "/app/" + relativePath;
  }else{
    // this references a coffeescript file which needs "coffeescripts" to
    // replace the "compiled" part of the path
    return pluginName + "/app/coffeescripts/" + relativePath;
  }
};

CompiledReferencePlugin.prototype.apply = function(compiler){

  compiler.plugin("normal-module-factory", function(nmf) {
    nmf.plugin("before-resolve", function(result, callback) {
      var requestString = result.request;

      if(/^jsx\//.test(requestString)){
        // this is a jsx file in canvas. We have to require it with it's full
        // extension while we still have a require-js build or we risk loading
        // it's compiled js instead
        result.request = requestString + ".jsx"
      } else if(/^jst\//.test(requestString)){
        // this is a handlebars file in canvas. We have to require it with it's full
        // extension while we still have a require-js build or we risk loading
        // it's compiled js instead
        result.request = requestString + ".handlebars"
      } else if(/^compiled\//.test(requestString)){
        // this references a coffesscript file in canvas
        result.request = requestString.replace("compiled/", "coffeescripts/");
      }else if(/^spec\/javascripts\/compiled/.test(requestString)){
        // this references a coffesscript spec file in canvas
        result.request = requestString.replace("spec/javascripts/compiled/", "");
      }

      // this references a file in a canvas plugin
      var pluginTranspiledRegexp = /^([^/]+)\/compiled\//;
      if(pluginTranspiledRegexp.test(requestString)){
        result.request = rewritePluginPath(requestString);
      }
      return callback(null, result);
    });
  });

};


module.exports = CompiledReferencePlugin;
