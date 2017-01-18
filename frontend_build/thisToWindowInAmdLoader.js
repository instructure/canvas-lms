//Tinymce has a crazy internal loading system for plugins.
// Because we've sinned in the past by wrapping AMD wrappers around
//  source files, this loader is our penance until we can undo such
//  silliness.  The next commit around this should load tinymce as is
//  (raw npm install) rather than wrapping the raw files in bower with
//  amd wrappers.  Then this loader goes away.
module.exports = function(input){
  this.cacheable();
  var output = input.replace("})(this)", "})(window)");
  return output;
}
