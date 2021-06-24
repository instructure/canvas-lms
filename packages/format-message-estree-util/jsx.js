'use strict'

/*
 * This object gets mixed into the main collection of helpers
 */
exports = module.exports = {
  isTranslatableElement: function (node) {
    return this.hasTranslateAttribute(node, 'yes')
  },

  hasTranslateAttribute: function (node, value) {
    var translate = this.getAttribute(node, 'translate')
    return (
      translate &&
      this.isStringLiteral(translate) &&
      (!value || translate.value === value)
    )
  },

  getElementTargetLocale: function (node) {
    var lang = this.getAttribute(node, 'lang')
    return (
      lang &&
      this.isStringLiteral(lang) &&
      lang.value
    )
  },

  getAttribute: function (node, name) {
    if (node.type !== 'JSXElement') return
    var attrs = (node.openingElement && node.openingElement.attributes) || []
    var attrNode = attrs.filter(function (attribute) {
      return (
        attribute.name &&
        attribute.name.type === 'JSXIdentifier' &&
        attribute.name.name === name
      )
    })[0]
    return attrNode && attrNode.value
  },

  getAttributes: function (node) {
    if (node.type !== 'JSXElement') return
    var attrs = node.openingElement.attributes || []
    var map = {}
    attrs.forEach(function (attribute) {
      if (attribute.name && attribute.name.type === 'JSXIdentifier') {
        map[attribute.name.name] = attribute.value
      }
    })
    return map
  },

  getElementMessageDetails: function (node) {
    var i = 0
    var wrappers = []
    function nextToken (node, options) {
      var token = i++
      wrappers[token] = {
        node: node,
        options: options || {}
      }
      return token
    }

    var parameters = {}
    return {
      default: this.getMessageText(node, nextToken, parameters),
      wrappers: wrappers,
      parameters: parameters
    }
  },

  getMessageText: function (node, nextToken, parameters) {
    var self = this
    return node.children.reduce(function (message, child) {
      if (child.type === 'JSXText' || self.isStringLiteral(child)) {
        return message + self.cleanJSXText(String(child.value))
      }
      if (child.type === 'JSXExpressionContainer') {
        return message + self.getParameterText(child.expression, nextToken, parameters)
      }
      if (child.type === 'JSXElement') {
        return message + self.getChildMessageText(child, nextToken, parameters)
      }
      return message
    }, '')
  },

  hasTranslatableText: function (node) {
    return node.children.some(function (child) {
      if (child.type === 'JSXText' || this.isStringLiteral(child)) {
        return this.cleanJSXText(String(child.value)).length > 0
      }
      if (child.type === 'JSXExpressionContainer') {
        if (child.expression.type === 'JSXEmptyExpression') return false
        if (this.isStringLiteral(child.expression)) return child.expression.value.length > 0
        return true
      }
      if (child.type === 'JSXElement') {
        return this.hasTranslatableText(child)
      }
      return false
    }, this)
  },

  cleanJSXText: function (text) {
    var lines = text.split(/\r\n|\n|\r/)
    var lastNonEmptyLine = 0

    for (var l = 0; l < lines.length; ++l) {
      if (lines[l].match(/[^ \t]/)) {
        lastNonEmptyLine = l
      }
    }

    var clean = ''
    for (var i = 0; i < lines.length; ++i) {
      var line = lines[i]
      var isFirstLine = i === 0
      var isLastLine = i === lines.length - 1
      var isLastNonEmptyLine = i === lastNonEmptyLine

      // replace rendered whitespace tabs with spaces
      var trimmedLine = line.replace(/\t/g, ' ')

      // trim whitespace touching a newline
      if (!isFirstLine) {
        trimmedLine = trimmedLine.replace(/^[ ]+/, '')
      }

      // trim whitespace touching an endline
      if (!isLastLine) {
        trimmedLine = trimmedLine.replace(/[ ]+$/, '')
      }

      if (trimmedLine) {
        if (!isLastNonEmptyLine) {
          trimmedLine += ' '
        }

        clean += trimmedLine
      }
    }
    return clean
  },

  getParameterText: function (node, nextToken, parameters) {
    if (node.type === 'Literal' || node.type === 'StringLiteral') {
      return String(node.value)
    }
    if (node.type === 'JSXEmptyExpression') {
      return ''
    }
    var parameterText = this.getParameterFromHelper(node, nextToken, parameters)
    if (parameterText) {
      return parameterText
    }
    var name = this.getCodeSlug(node)
    parameters[name] = node
    return '{ ' + name + ' }'
  },

  getCodeSlug: function (node) {
    // adapted from https://github.com/jenseng/react-i18nliner
    return this.getSource(node)
      .replace(/<[^>]*>/, '') // remove jsx tags
      .replace(/(this|state|props)\./g, '') // remove common objects
      .replace(/([A-Z]+)?([A-Z])/g, '$1 $2') // add spaces for consective capitals
      .toLowerCase()
      .replace(/[^a-z0-9]/g, ' ') // remove non-ascii
      .trim()
      .replace(/\s+/g, '_')
  },

  getChildMessageText: function (node, nextToken, parameters) {
    var token
    var children = node.children
    var hasSubContent = (
      children && children.length > 0 &&
      !this.hasTranslateAttribute(node) &&
      this.hasTranslatableText(node)
    )
    if (!hasSubContent) {
      token = nextToken(node, { selfClosing: true })
      return '<' + token + '/>'
    }

    token = nextToken(node)
    var innerText = this.getMessageText(node, nextToken, parameters)
    return '<' + token + '>' + innerText + '</' + token + '>'
  },

  getParameterFromHelper: function (node, nextToken, parameters) {
    if (node.type !== 'CallExpression') return
    var name = this.getHelperFunctionName(node.callee)
    if (!name) return

    var args = node.arguments
    if (args.length < 1) return
    var id = this.getCodeSlug(args[0])
    var parameter = id + ', ' + name

    if (name === 'number' || name === 'date' || name === 'time') {
      if (args[1] && this.isStringLiteral(args[1])) {
        var style = args[1].value
        parameter += ', ' + (
          /[{}\s]/.test(style)
            ? '\'' + style.replace(/'/g, '\'\'') + '\''
            : style.replace(/'/g, '\'\'')
        )
      }
      parameters[id] = args[0]
      return '{ ' + parameter + ' }'
    }

    var options
    if (name === 'select') {
      if (args.length < 2) return
      options = this.getOptionsFromObjectExpression(args[1], nextToken, parameters)
      if (!options) return
      parameters[id] = args[0]
      return '{ ' + parameter + ', ' + options + ' }'
    }

    if (name === 'plural' || name === 'selectordinal') {
      if (args.length < 2) return
      var hasOffset = this.isNumericLiteral(args[1])
      options = this.getOptionsFromObjectExpression(args[hasOffset ? 2 : 1], nextToken, parameters)
      if (!options) return
      if (hasOffset) {
        options = 'offset:' + args[1].value + options
      }
      parameters[id] = args[0]
      return '{ ' + parameter + ', ' + options + ' }'
    }
  },

  getOptionsFromObjectExpression: function (node, nextToken, parameters) {
    if (node.type !== 'ObjectExpression') return
    var options = ''
    var properties = node.properties
    for (var p = 0, pp = properties.length; p < pp; ++p) {
      var property = properties[p]
      if (property.computed || property.shorthand || property.method) return
      var key = property.key.name || property.key.value
      var valueNode = property.value
      var value
      if (valueNode.type === 'JSXElement') {
        value = this.getChildMessageText(valueNode, nextToken, parameters)
      } else if (this.isStringLiteral(valueNode)) {
        value = String(valueNode.value)
      }
      if (value == null) return
      options += '\n' + key + ' {' + value + '}'
    }
    return options
  }
}
