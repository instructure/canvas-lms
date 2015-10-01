module.exports = function(input){
  this.cacheable();
  var dependenciesRegexp = /define\(?\s*\[(.|\n)*?]/;
  var newInput = input.replace(dependenciesRegexp, function(match){
    if(/('|")jst\//.test(match)){
      var extraDep = ", 'coffeescripts/handlebars_helpers']";
      var defineWithHandlebarsDependency = match.replace(/]$/m, extraDep);
      return defineWithHandlebarsDependency;
    }
    return match;
  });
  return newInput;
}
