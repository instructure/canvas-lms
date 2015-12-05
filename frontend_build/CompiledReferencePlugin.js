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

CompiledReferencePlugin.prototype.apply = function(compiler){

  compiler.plugin("normal-module-factory", function(nmf) {
    nmf.plugin("before-resolve", function(result, callback) {
      var requestString = result.request;
      // this references a coffesscript file in canvas
      if(/^compiled\//.test(requestString)){
        result.request = requestString.replace("compiled/", "coffeescripts/");
      }

      // this references a coffeescript file in a canvas plugin
      var pluginCoffeeRegexp = /^([^/]+)\/compiled\//;
      if(pluginCoffeeRegexp.test(requestString)){
        var pluginName = pluginCoffeeRegexp.exec(requestString)[1];
        var relativePath = requestString.replace(pluginName + "/compiled/", "");
        var fullRequire = pluginName + "/app/coffeescripts/" + relativePath;
        result.request = fullRequire;
      }
      return callback(null, result);
    });
  });

};


module.exports = CompiledReferencePlugin;
