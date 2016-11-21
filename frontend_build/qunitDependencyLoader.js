// Our spec files use qunit's global variables. in webpack.test.config.js, we set
// up some 'imports' loaders for 'test', 'asyncTest', and 'start' so they are available 
// globally but we can't do the same for 'module' because if you define a global 
// variable 'module' that screws everything up. so this just replaces 
// "module(..." calls with "qunit.module"
// We should get rid of all these loaders and just change our actual source 
// to s/test/qunit.test/ and s/module/qunit.module/

const lineThatStartsWithTheWordModule = /^\s+(return )?module\(/gm

module.exports = function(source) {
  this.cacheable()
  // replace "module(..." calls with "qunit.module"
  return source.replace(lineThatStartsWithTheWordModule, match => 
    match.replace('module', 'qunit.module')
  )
}
