// An example of needing this: we've wrapped backbone in an AMD wrapper.
//  now "this" is an empty object when it would be "window" if we could Use
// a normal imports loader
// Because we've sinned in the past by wrapping AMD wrappers around
//  source files, this loader is our penance until we can undo such
//  silliness.  The next commit around this should load backbone as is
//  (raw npm install) rather than wrapping the raw files in vendor with
//  amd wrappers.  Then this loader goes away.
module.exports = function(input){
  this.cacheable();
  var output = input.replace("}).call(this);", "}).call(window);");
  return output;
}
