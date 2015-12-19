// handlebars-loader wants to know about every helper we have, and uses
// a file convention to autofind them.  Since we don't match that
// convention, we need to specify which helpers are ones it should
// count on being present (ones defined in handlebars_helpers).
// We'll then make sure modules requiring a jst file have a dependency
// on handlebars_helpers built in, since they self-register with handlebars
//runtime that should be ok.

var fs = require('fs');
var path = require('path');
var coffee = require('coffee-script');

var loadHelpersAST = function(){
  var filename = path.join(__dirname, "..", "app/coffeescripts/handlebars_helpers.coffee");
  var source = fs.readFileSync(filename, 'utf8');
  return coffee.nodes(source);
};

// we're looking in the helpers AST for the for loop that goes through a javascript
// object (the "source" object) and calls "registerHelper" with each property
//   We want to make those same properties into "known" helpers.
var isHandlebarsAssignmentNode = function(node){
  var result = node.body.contains(function(childNode){
    return childNode.constructor.name === 'Call' &&
      childNode.variable.base.value === 'Handlebars' &&
      childNode.variable.contains(function(registerNode){
        return registerNode.constructor.name === 'Access' &&
          registerNode.name.value === 'registerHelper';
      });
  });
  return result;
}

var findHelperNodes = function(helpersAST){
  var helpersCollection = null;
  helpersAST.traverseChildren(true, function(child){
    if(child.constructor.name === 'For'){
      if(isHandlebarsAssignmentNode(child)){
        helpersCollection = child.source.base.properties;
        return false;
      }
    }
  });
  return helpersCollection;
}

// given an array of nodes (which are functions assigned to property names),
// return an array of property names in the "knownHelpers" query format for
// the handlebars loader.
var buildQueryStringElements = function(helperNodes){
  var queryElements = [];
  helperNodes.forEach(function(helper){
    var helperName = helper.variable.base.value;
    queryElements.push("knownHelpers[]=" + helperName);
  });
  return queryElements;
};


module.exports = {
  queryString: function(){
    var helpersAST = loadHelpersAST();
    var helpersCollection = findHelperNodes(helpersAST);
    var queryElements = buildQueryStringElements(helpersCollection);
    return queryElements.join("&");
  }
}
