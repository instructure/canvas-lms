// Some tinymce plugins depend on the tinymce global, which
// we can just provide through an exports/imports loader, but there are a few
// which want to "require" submodules within tinymce, which requires that
// all the compat modules be executed and exposed on the window'd tinymce (
// the library exposes a main object [which is what 'require' returns], but Then
//  exposes several other modules on "exports", which normally is "window".)
//  Here we solve that (temporarily, oh please don't make this permenant) by
// maintaining a list of such plugins and running them through a loader
// that makes sure their context is "window", where tinymce is conveniently exposed
// thanks to the "nonAmdLoader".

var shimmableAmdModules = [
  "bower/tinymce/plugins/paste/plugin",
  "bower/tinymce/plugins/table/plugin"
];

var shimmableWindowCallModules = [
  "vendor/backbone"
];

var ShimmedAmdPlugin = function(){};

ShimmedAmdPlugin.prototype.apply = function(compiler){

  compiler.plugin("normal-module-factory", function(nmf) {
    nmf.plugin("before-resolve", function(result, callback) {

      shimmableAmdModules.forEach(function(plugin){
        if(result.request == plugin){
          result.request = "thisToWindowInAmdLoader!" + result.request;
        }
      });

      shimmableWindowCallModules.forEach(function(module){
        if(result.request == module){
          result.request = "callWindowInsteadOfThisLoader!" + result.request;
        }
      })

      return callback(null, result);
    });
  });

};


module.exports = ShimmedAmdPlugin;
