// We used to compile jst templates into the app before requiring,
// but with webpack we can pull them right out of the plugins,
// this takes requirements for "analytics/jst/thing" and rewrites them
// to "analytics/app/views/jst/thing" so that they can be found off of
// the "gem/plugins" directory in the webpack path resolve config

const pluginJstRegexp = /('|")[^/\s]+\/jst\//g

module.exports = function (input) {
  this.cacheable()
  return input.replace(pluginJstRegexp, match => match.replace('jst', 'app/views/jst'))
}
