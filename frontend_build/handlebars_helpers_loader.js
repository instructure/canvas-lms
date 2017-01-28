// handlebars-loader wants to know about every helper we have, and uses
// a file convention to autofind them.  Since we don't match that
// convention, we need to specify which helpers are ones it should
// count on being present (ones defined in handlebars_helpers).
// We'll then make sure modules requiring a jst file have a dependency
// on handlebars_helpers built in, since they self-register with handlebars
// runtime that should be ok.

const fs = require('fs')
const path = require('path')
const coffee = require('coffee-script')

function loadHelpersAST () {
  const filename = path.join(__dirname, '..', 'app/coffeescripts/handlebars_helpers.coffee')
  const source = fs.readFileSync(filename, 'utf8')
  return coffee.nodes(source)
}

// we're looking in the helpers AST for the for loop that goes through a javascript
// object (the "source" object) and calls "registerHelper" with each property
//   We want to make those same properties into "known" helpers.
function isHandlebarsAssignmentNode (node) {
  return node.body.contains(childNode =>
    childNode.constructor.name === 'Call' &&
    childNode.variable.base.value === 'Handlebars' &&
    childNode.variable.contains(registerNode =>
      registerNode.constructor.name === 'Access' &&
      registerNode.name.value === 'registerHelper'
    )
  )
}

function findHelperNodes (helpersAST) {
  let helpersCollection = null
  helpersAST.traverseChildren(true, child => {
    if (child.constructor.name === 'For') {
      if (isHandlebarsAssignmentNode(child)) {
        helpersCollection = child.source.base.properties
        return false
      }
    }
  })
  return helpersCollection
}

// given an array of nodes (which are functions assigned to property names),
// return an array of property names in the "knownHelpers" query format for
// the handlebars loader.
function buildQueryStringElements (helperNodes) {
  const queryElements = []
  helperNodes.forEach(helper => {
    const helperName = helper.variable.base.value
    queryElements.push(`knownHelpers[]=${helperName}`)
  })
  return queryElements
}

module.exports = {
  queryString() {
    const helpersAST = loadHelpersAST()
    const helpersCollection = findHelperNodes(helpersAST)
    const queryElements = buildQueryStringElements(helpersCollection)
    return queryElements.join('&')
  }
}
