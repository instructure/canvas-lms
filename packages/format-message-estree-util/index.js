'use strict'

var MODULE_NAME_PATTERN = /(^|\/)format-message(?:\.js)?$/

exports = module.exports = {
  setBabelContext: function (path, state) {
    this.context = {
      type: 'babel',
      path: path,
      state: state
    }
  },

  setESLintContext: function (context) {
    this.context = {
      type: 'eslint',
      context: context
    }
  },

  getSource: function (node) {
    var context = this.context
    if (context && context.type === 'babel' && node.end) {
      return context.path.hub.file.code.slice(node.start, node.end)
    }
    if (context && context.type === 'eslint') {
      return context.context.getSourceCode().getText(node)
    }
    return ''
  },

  getBinding: function (node) {
    var context = this.context
    var binding
    if (context && context.type === 'babel') {
      binding = this.context.path.scope.getBinding(node.name)
      if (binding) binding.node = binding.path.node
      return binding
    }
    if (context && context.type === 'eslint') {
      var scope = context.context.getScope()
      while (!binding && scope) {
        var ref = scope.variables.filter(function (variable) {
          return variable.name === node.name
        })[0]
        binding = ref && ref.defs && ref.defs[0]
        scope = scope.upper
      }
      return binding
    }
  },

  isStringLiteral: function (node) {
    return (
      node.type === 'StringLiteral' || // babel
      (node.type === 'Literal' && typeof node.value === 'string')
    )
  },

  isNumericLiteral: function (node) {
    return (
      node.type === 'NumericLiteral' || // babel
      (node.type === 'Literal' && typeof node.value === 'number')
    )
  },

  isImportFormatMessage: function (binding) {
    var node = binding.node
    var parent = binding.path ? binding.path.parentPath.node : node.parent

    return (
      parent &&
      parent.source &&
      this.isStringLiteral(parent.source) &&
      MODULE_NAME_PATTERN.test(parent.source.value) &&
      (node.type === 'ImportDefaultSpecifier' ||
        (node.type === 'ImportSpecifier' && node.imported && node.imported.name === 'default'))
    )
  },

  isRequireFormatMessage: function (node) {
    var arg
    return (
      node &&
      node.type === 'CallExpression' &&
      node.callee &&
      node.callee.type === 'Identifier' &&
      node.callee.name === 'require' &&
      !!(arg = node.arguments[0]) &&
      this.isStringLiteral(arg) &&
      MODULE_NAME_PATTERN.test(arg.value)
    )
  },

  isFormatMessage: function (node) {
    if (node.type !== 'Identifier') return false
    var binding = this.getBinding(node)
    if (!binding || !binding.node) return false

    return (
      this.isImportFormatMessage(binding) ||
      (binding.node.type === 'VariableDeclarator' &&
        binding.node.id.type === 'Identifier' &&
        binding.node.init &&
        this.isRequireFormatMessage(binding.node.init))
    )
  },

  isRichMessage: function (node) {
    var name = this.getFormatMessagePropertyName(node)
    if (name === 'rich') return name
  },

  isStringish: function (node) {
    return this.isLiteralish(node) && typeof this.getLiteralValue(node) === 'string'
  },

  isLiteralish: function (node) {
    return (
      this.isStringLiteral(node) ||
      (node.type === 'TemplateLiteral' &&
        node.expressions.length === 0 &&
        node.quasis.length === 1) ||
      (node.type === 'BinaryExpression' &&
        node.operator === '+' &&
        this.isLiteralish(node.left) &&
        this.isLiteralish(node.right))
    )
  },

  getLiteralValue: function (node) {
    // assumes isLiteralish(node) === true
    switch (node.type) {
      case 'NullLiteral':
        return null
      case 'RegExpLiteral':
        return new RegExp(node.regex.pattern, node.regex.flags)
      case 'TemplateLiteral':
        return node.quasis[0].value.cooked
      case 'BinaryExpression':
        return this.getLiteralValue(node.left) + this.getLiteralValue(node.right)
      default:
        return node.value
    }
  },

  getLiteralsFromObjectExpression: function (node) {
    var self = this
    return node.properties.reduce(function (props, prop) {
      var canGetValue =
        (prop.computed === false || prop.key.type === 'StringLiteral') &&
        self.isLiteralish(prop.value)
      if (canGetValue) {
        var key = prop.key.name || prop.key.value
        props[key] = self.getLiteralValue(prop.value)
      }
      return props
    }, {})
  },

  getMessageDetails: function (args) {
    var message = args[0]
    if (message && this.isLiteralish(message)) {
      return {default: this.getLiteralValue(message)}
    }
    if (message && message.type === 'ObjectExpression') {
      return this.getLiteralsFromObjectExpression(message)
    }
    return {}
  },

  getLiteralParams: function (args) {
    var params = args[1]
    if (params && params.type === 'ObjectExpression') {
      return this.getLiteralsFromObjectExpression(params)
    }
    return {}
  },

  getTargetLocale: function (args) {
    var locale = args[2]
    if (locale && this.isLiteralish(locale)) {
      return this.getLiteralValue(locale)
    }
    return null
  },

  getHelperFunctionName: function (node) {
    var name = this.getFormatMessagePropertyName(node)
    if (this.isHelperName(name)) return name
  },

  getFormatMessagePropertyName: function (node) {
    var binding
    var name
    var isImportedCall =
      node.type === 'Identifier' &&
      (binding = this.getBinding(node)) &&
      ((name = this.getImportHelper(binding)) ||
        (name = this.getRequireHelper(binding.node, node.name)))
    if (isImportedCall) return name

    var isMemberCall =
      node.type === 'MemberExpression' &&
      this.isFormatMessage(node.object) &&
      node.property.type === 'Identifier' &&
      (name = node.property.name)
    if (isMemberCall) return name
  },

  getImportHelper: function (binding) {
    var node = binding.node
    var parent = binding.path ? binding.path.parentPath.node : node.parent
    var name
    var isImportHelper =
      node &&
      node.type === 'ImportSpecifier' &&
      node.imported.type === 'Identifier' &&
      (name = node.imported.name) &&
      this.isStringLiteral(parent.source) &&
      MODULE_NAME_PATTERN.test(parent.source.value)
    if (isImportHelper) return name
  },

  getRequireHelper: function (node, referenceName) {
    var name
    var isMemberRequire =
      node &&
      node.type === 'VariableDeclarator' &&
      node.id &&
      node.id.type === 'Identifier' &&
      node.init &&
      node.init.type === 'MemberExpression' &&
      this.isRequireFormatMessage(node.init.object) &&
      node.init.property.type === 'Identifier' &&
      (name = node.init.property.name)
    if (isMemberRequire) return name

    var isDestructureRequire =
      node &&
      node.type === 'VariableDeclarator' &&
      this.isRequireFormatMessage(node.init) &&
      node.id &&
      node.id.type === 'ObjectPattern' &&
      node.id.properties.some(function (property) {
        var isAHelper = property.key.type === 'Identifier' && this.isHelperName(property.key.name)
        if (!isAHelper) return false
        if (property.value.type === 'Identifier' && property.value.name === referenceName) {
          name = property.key.name
          return true
        }
        return false
      }, this)
    if (isDestructureRequire) return name
  },

  isHelperName: function (name) {
    return (
      name === 'number' ||
      name === 'date' ||
      name === 'time' ||
      name === 'select' ||
      name === 'plural' ||
      name === 'selectordinal'
    )
  }
}

// mix in jsx helpers
var jsx = require('./jsx')
Object.keys(jsx).forEach(function (key) {
  exports[key] = jsx[key]
})
