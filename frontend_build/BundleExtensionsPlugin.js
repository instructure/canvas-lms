// this is how we do the magic for making sure extensions in plugins get applied
// to canvas modules.  It depends upon conventional file system names (
// some file in the plugin has the same name as the coffeescript file it extends
// in canvas)
/*
# given app/coffeescripts/foo.coffee in canvas-lms, if you want to
# monkey patch it from your plugin, create
# app/coffeescripts/extensions/foo.coffee (in your plugin) like so:
#
# define ->
#   (Foo) ->
#     Foo::zomg = -> "i added this method"
#     Foo
#
# and that's it, no changes required in canvas-lms, no plugin
# bundles, etc.
#
# note that Foo is not an explicit dependency, it magically figures
# it out. also note that your module should return a function that
# accepts and returns Foo. this function will magically wrap around
# Foo so you can do stuff to it anytime somebody requires "foo" as
# per usual.
*/
var glob = require("glob");

var loadExtensionsMap = function(){
  var pluginExtensionsPattern = __dirname + "/../gems/plugins/*/app/coffeescripts/extensions/**/*.coffee";
  var pluginExtensions = glob.sync(pluginExtensionsPattern, []);
  var extensionsMap = {};
  var extensionPartsRegexp = /plugins\/([^/]*)\/app\/coffeescripts\/extensions\/(.*)\.coffee/;
  pluginExtensions.forEach(function(extension){
    var extractions = extension.match(extensionPartsRegexp);
    var pluginName = extractions[1];
    var fileName = extractions[2];
    if(extensionsMap[fileName] === undefined){
      extensionsMap[fileName] = [];
    }
    extensionsMap[fileName].push(pluginName);
  });
  return extensionsMap;
};

// this is all the extensions that we can find in gems/plugins
var extensions = loadExtensionsMap();

var requireUndextendedRegexp = /^unextended!/;
var extensionRequirementRegexp = /\/extensions\//;

var BundleExtensionsPlugin = function(){};

BundleExtensionsPlugin.prototype.apply = function(compiler){

  compiler.plugin("normal-module-factory", function(nmf) {
    nmf.plugin("before-resolve", function(result, callback) {
      var addLoadersFor = [];
      // if we're resolving an extension, we don't want to try to
      // extend the extension itself, so skip the check and move on
      if(!extensionRequirementRegexp.test(result.request)){
        Object.keys(extensions).forEach(function(key){
          if(result.request.indexOf(key) > -1){
            if(requireUndextendedRegexp.test(result.request)){
              // skip, unextended loader means we really want the original
            } else {
              // we're trying to resolve a file that has an extension in at least one plugin,
              // so we'll set the flag that tells us to add the withExtensions loader
              // down below
              addLoadersFor = extensions[key];
            }
          }
        });

        if(addLoadersFor.length > 0){
          var newRequest = "withExtensions?" + addLoadersFor.join(",") + "!" +result.request;
          result.request = newRequest;
        }
      }
      return callback(null, result);
    });
  });

};


module.exports = BundleExtensionsPlugin;
