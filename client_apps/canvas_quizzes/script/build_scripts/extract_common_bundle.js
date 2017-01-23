const glob = require('glob');
const readJSON = require('../helpers/read_json');
const K = require('./constants');

/**
 * Prepare a set of module IDs for use inside the "bundles" r.js config hash.
 * The module IDs need to be stripped of any loader plugins (like jsx!) because
 * at the time the bundle is used, the files will be compiled and the loader
 * will not be available in the first place.
 *
 * This is needed for both run-time and build-time configs (which gets exposed
 * to Canvas.)
 *
 * @param  {String[]} commonModules
 *         IDs of the modules that are provided by the common bundle.
 *         See ./extract_common_modules.js for getting this array.
 *
 * @return {String[]}
 */
module.exports = function (commonModules) {
  return commonModules.map(moduleId =>
    // Since we're excluding the JSX plugin from the build, we need to discard
    // the loader plugin prefix from the module identifiers:
     moduleId.replace('jsx!', ''));
};
