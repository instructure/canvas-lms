////
// if you want underscore in your code. require 'underscore' (this file)

define(['vendor/lodash.underscore'], function(){
  // grab the global '_' variable, make it not global and return it
  return _.noConflict();
});