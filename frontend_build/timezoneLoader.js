module.exports = function timezoneLoader (content) {
  this.cacheable()

  // the 'Africa/Abidjan' part of 'public/javascripts/vendor/timezone/Africa/Abidjan.js'
  const timezoneName = this.resource.match(/vendor\/timezone\/(.*)\.js$/)[1]

  // remove the define(function () { return ... }); wrapper
  const bareContent = content
    .replace(/^define\(function \(\) { return/, '')
    .replace(/}\);$/, '')

  return `
    var _preloadedData = require('timezone_core')._preloadedData;
    module.exports = _preloadedData['${timezoneName}'] = ${bareContent};
  `
}
