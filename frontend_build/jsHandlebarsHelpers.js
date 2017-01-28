const dependenciesRegexp = /define\(?\s*\[(.|\n)*?]/
const extraDep = ", 'coffeescripts/handlebars_helpers']"

module.exports = function (input) {
  this.cacheable()
  return input.replace(dependenciesRegexp, match => {
    if (/('|")jst\//.test(match)) {
      const defineWithHandlebarsDependency = match.replace(/]$/m, extraDep)
      return defineWithHandlebarsDependency
    }
    return match
  })
}
