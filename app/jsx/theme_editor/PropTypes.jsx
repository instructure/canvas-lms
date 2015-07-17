define([
  'react',
  'underscore'
], (React, _) => {

  var MD5_REGEX = /[0-9a-fA-F]{32}$/
  var types = {}

  types.md5 = function (props, propName, componentName) {
    var val = props[propName];
    if (val !== null && !MD5_REGEX.test(val)) {
      return new Error(`Invalid md5: ${val} propName: ${propName} componentName: ${componentName}`)
    }
  }

  var baseVarDef = {
    default: React.PropTypes.string.isRequired,
    human_name: React.PropTypes.string.isRequired,
    variable_name: React.PropTypes.string.isRequired
  }

  types.color = React.PropTypes.shape(_.extend({
    type: React.PropTypes.oneOf(['color']).isRequired
  }, baseVarDef))

  types.image = React.PropTypes.shape(_.extend({
    type: React.PropTypes.oneOf(['image']).isRequired,
    accept: React.PropTypes.string.isRequired,
    helper_text: React.PropTypes.string.isRequired
  }, baseVarDef))

  types.varDef = React.PropTypes.oneOfType([types.image, types.color])

  types.brandConfig = React.PropTypes.shape({
    md5: types.md5,
    variables: React.PropTypes.object.isRequired
  })

  types.sharedBrandConfig = React.PropTypes.shape({
    md5: types.md5,
    name: React.PropTypes.string.isRequired
  })

  types.sharedBrandConfigs = React.PropTypes.arrayOf(types.sharedBrandConfig)

  types.variableGroup = React.PropTypes.shape({
    group_name: React.PropTypes.string.isRequired,
    variables: React.PropTypes.arrayOf(types.varDef).isRequired
  })

  types.userVariableInput = React.PropTypes.shape({
    val: React.PropTypes.string,
    invalid: React.PropTypes.bool
  })

  types.variableSchema = React.PropTypes.arrayOf(types.variableGroup).isRequired

  return types
});
