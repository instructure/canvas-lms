// This is a port of some of the functionality in
// lib/brandable_css.rb, because shelling out to run this
// stuff take FOREVER.  That means for the time being, changes here
// if they happen may need to be mirrored in that file.
var fs = require('fs');
var yaml = require('js-yaml');
var child_process = require('child_process');
var configDocument = yaml.safeLoad(fs.readFileSync(__dirname + '/../config/brandable_css.yml', 'utf8'));
var variants = Object.keys(configDocument.variants);
var manifestKeySeperator = configDocument.manifest_key_seperator;
var useCompressed = process.env.RAILS_ENV == 'production'
var SassStyle = process.env.SASS_STYLE || (useCompressed ? 'compressed' : 'nested');

// load checksums data for fast retrieval during parsing
var checksumsFilePath = "/../" + configDocument.paths.bundles_with_deps + SassStyle;
var checksumsJson = JSON.parse(fs.readFileSync(__dirname + checksumsFilePath, 'utf8'))
var combinedChecksums = {}
Object.keys(checksumsJson).forEach(function(key){
  if(checksumsJson.hasOwnProperty(key)){
    var jsonObj = checksumsJson[key]
    combinedChecksums[key] = {
      combinedChecksum: jsonObj.combinedChecksum,
      includesNoVariables: jsonObj.includesNoVariables
    }
  }
})

var cacheFor = function(bundleName, variant){
  var key = [bundleName + ".scss", variant].join(manifestKeySeperator);
  return combinedChecksums[key];
}

var fingerprint = function(bundleName){
  var fingerprints = {}
  variants.forEach(function(variant){
    fingerprints[variant] = cacheFor(bundleName, variant);
  })
  return fingerprints;
};

module.exports.allFingerprintsFor = fingerprint;
