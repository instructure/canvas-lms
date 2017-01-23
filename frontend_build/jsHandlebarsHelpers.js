module.exports = function (input) {
  this.cacheable();
  const dependenciesRegexp = /define\(?\s*\[(.|\n)*?]/;
  const newInput = input.replace(dependenciesRegexp, (match) => {
    if (/('|")jst\//.test(match)) {
      const extraDep = ", 'coffeescripts/handlebars_helpers']";
      const defineWithHandlebarsDependency = match.replace(/]$/m, extraDep);
      return defineWithHandlebarsDependency;
    }
    return match;
  });
  return newInput;
}
