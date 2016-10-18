const i18nRegex = /["']vendor\/i18n['"]/
const emberRegex = /['"]ember["']/

module.exports = function nonAmdLoader(input){
  this.cacheable()
  return input
    // Make I18n available on the window so that libraries
    // that expect to find it there don't die
    .replace(i18nRegex, match => match.replace('vendor', 'expose?I18n!exports?I18n!vendor'))
    .replace(emberRegex, "'shims/ember'")
}
