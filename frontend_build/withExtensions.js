// This loader knows how to build a glue module that requires both the original
// unextended file from canvas, and any extensions from plugins, and builds
// a chain of calls to apply the extensions.  This is a replacement for any
// place in the app the original file is required.

var extractFileName = function(remainingRequest){
  var loaderedPieces = remainingRequest.split("!");
  var unloaderedRequest = loaderedPieces[loaderedPieces.length - 1];
  return unloaderedRequest.replace(/^.*\/app\/coffeescripts\//, "");
};

module.exports = function(source){
  throw "Should not ever make it to the actual extensions "+
        "loader because the pitching function does the work";
};

module.exports.pitch = function(remainingRequest, precedingRequest, data) {
  this.cacheable();

  var fileName = extractFileName(remainingRequest);
  var plugins = this.query.replace("?", "").split(",");
  var originalRequire = "unextended!coffeescripts/" + fileName;
  var pluginPaths = [originalRequire];
  var pluginArgs = [];
  plugins.forEach(function(plugin, i){
    var pluginExtension = "" + plugin + "/app/coffeescripts/extensions/" + fileName;
    pluginPaths.push(pluginExtension);
    pluginArgs.push("p"+i+"");
  });

  var pluginChain = "orig"

  var i = pluginArgs.length -1;
  while(i >= 0){
    var pluginCall = pluginArgs[i];
    pluginChain = "" + pluginCall + "(" + pluginChain + ")";
    i = i-1;
  }

  var extendedJavascript = ""+
    "define(" + JSON.stringify(pluginPaths) + ",function(orig, " + pluginArgs.join(",") + "){\n" +
    "  return " + pluginChain + ";\n" +
    "});";

  return extendedJavascript;
};
