define([
  'i18n!calculator.command',
  'jquery' /* $ */
], function(I18n, $) {

  var calcCmd = {};

  (function() {
    var methods = {};
    var predefinedVariables = {};
    var variables = {};
    var lastComputedResult;
    var expressions = [
      {regex: /\s+/, token: 'whitespace'},
      {regex: /[a-zA-Z][a-zA-Z0-9_\.]*/, token: 'variable'},
      {regex: /[0-9]*\.?[0-9]+/, token: 'number'},
      {regex: /\+/, token: 'add'},
      {regex: /\-/, token: 'subtract'},
      {regex: /\*/, token: 'multiply'},
      {regex: /\//, token: 'divide'},
      {regex: /\(/, token: 'open_paren'},
      {regex: /\)/, token: 'close_paren'},
      {regex: /\,/, token: 'comma'},
      {regex: /\^/, token: 'power'},
      {regex: /\=/, token: 'equals'}
    ];
    var parseToken = function(command, index) {
      var value = command.substring(index);
      var item = {};
      for(var idx in expressions) {
        var expression = expressions[idx];
        var match = value.match(expression.regex);
        if(match && match[0] && value.indexOf(match[0]) == 0) {
          item.token = expression.token;
          item.value = match[0];
          item.newIndex = index + match[0].length;
          return item;
        }
      }
      return null;
    };
    var parseSyntax = function(command) {
      var index = 0;
      var result = [];
      while(index < command.length) {
        var item = parseToken(command, index);
        if(!item) {
          throw("unrecognized token at " + index);
        }
        index = item.newIndex;
        result.push(item);
      }
      return result;
    };
    var syntaxIndex = 0;
    var parseArgument = function(syntax) {
      var result = null;
      switch(syntax[syntaxIndex].token) {
      case 'number':
        result = syntax[syntaxIndex];
        break;
      case 'subtract':
        if(syntax[syntaxIndex + 1] && (syntax[syntaxIndex + 1].token == 'number' || syntax[syntaxIndex + 1].token == 'variable')) {
          syntax[syntaxIndex + 1].value = "-" + syntax[syntaxIndex + 1].value;
          syntaxIndex++;
          result = syntax[syntaxIndex];
        } else {
          throw("expecting a number at " + syntax[syntaxIndex].newIndex);
        }
        break;
      case 'variable':
        if(syntax[syntaxIndex + 1] && syntax[syntaxIndex + 1].token == 'open_paren') {
          result = syntax[syntaxIndex];
          result.token = 'method'
          result.arguments = []
          var ender = 'comma';
          syntaxIndex = syntaxIndex + 2;
          if(syntax[syntaxIndex].token == 'close_paren') {
            ender = 'close_paren';
            syntaxIndex++;
          }
          while(ender == 'comma') {
            result.arguments.push(parseExpression(syntax, ['comma', 'close_paren']));
            ender = syntax[syntaxIndex].token;
            syntaxIndex++;
          }
          syntaxIndex--;
          if(ender != 'close_paren') {
            throw("expecting close parenthesis at " + syntax[syntaxIndex].newIndex);
          }
        } else {
          result = syntax[syntaxIndex];
        }
        break;
      case 'open_paren':
        result = syntax[syntaxIndex];
        result.token = 'parenthesized_expression';
        syntaxIndex++;
        result.expression = parseExpression(syntax, ['close_paren']);
        break;
      }
      if(!result) {
        var index = (syntax && syntax[syntaxIndex] && syntax[syntaxIndex].newIndex) || 0;
        var type = (syntax && syntax[syntaxIndex] && syntax[syntaxIndex].token) || "nothing"
        throw("expecting a value at " + index + ", got a " + type);
      }
      syntaxIndex++;
      return result;
    };
    var parseModifier = function(syntax) {
      switch(syntax[syntaxIndex].token) {
      case 'add':
        return syntax[syntaxIndex++];
        break;
      case 'subtract':
        return syntax[syntaxIndex++];
        break;
      case 'multiply':
        return syntax[syntaxIndex++];
        break;
      case 'divide':
        return syntax[syntaxIndex++];
        break;
      case 'power':
        return syntax[syntaxIndex++];
        break;
      }
      var value = (syntax && syntax[syntaxIndex] && syntax[syntaxIndex].token) || 'value';
      var index = (syntax && syntax[syntaxIndex] && syntax[syntaxIndex].newIndex) || 0;
      throw("unexpected " + value + " at " + index);
    };

    var parseExpression = function(syntax, enders) {
      var result = {
        token: 'expression',
        newIndex: syntax[syntaxIndex].newIndex
      };
      result.expressionItems = []
      result.expressionItems.push(parseArgument(syntax));
      if(syntaxIndex > syntax.length) {
        return result;
      }
      var ended = false;
      while(syntaxIndex < syntax.length && !ended) {
        for(var idx in enders) {
          if(syntax[syntaxIndex].token == enders[idx]) {
            ended = true;
          }
        }
        if(!ended) {
          result.expressionItems.push(parseModifier(syntax));
          result.expressionItems.push(parseArgument(syntax));
        }
      }
      return result;
    };
    var parseFullExpression = function(syntax) {
      var newSyntax = [];
      for(var idx in syntax) {
        if(syntax[idx].token != 'whitespace') {
          newSyntax.push(syntax[idx]);
        }
      }
      syntax = newSyntax;
      var result = null;
      syntaxIndex = 0;
      if(syntax[syntaxIndex].token == 'variable' && syntax.length > 1 && syntax[syntaxIndex + 1].token == 'equals') {
        result = {
          token: 'variable_assignment',
          newIndex: syntax[syntaxIndex].newIndex
        }
        result.variable = syntax[syntaxIndex];
        if(syntax.length > 2) {
          syntaxIndex = 2;
          result.assignmentExpression = parseExpression(syntax);
        } else {
          throw("Expecting value at " + syntax[syntaxIndex + 1].newIndex);
        }
      } else {
        result = parseExpression(syntax);
      }
      return result;
    };
    var computeExpression = function(tree) {
      var round0 = tree.expressionItems;
      var round1 = [round0[0]];
      for(var idx = 1; idx < round0.length; idx += 2) {
        var item = round0[idx];
        if(item.token == 'power') {
          var left = round1.pop();
          var right = round0[idx + 1];
          round1.push(numberItem(Math.pow(compute(left), compute(right))));
        } else {
          round1.push(round0[idx]);
          round1.push(round0[idx + 1]);
        }
      }
      var round2 = [round1[0]];
      for(var idx = 1; idx < round1.length; idx += 2) {
        var item = round1[idx];
        if(item.token == 'multiply') {
          var left = round2.pop();
          var right = round1[idx + 1];
          round2.push(numberItem(compute(left) * compute(right)));
        } else if(item.token == 'divide') {
          var left = round2.pop();
          var right = round1[idx + 1];
            round2.push(numberItem(compute(left) / compute(right)));
        } else {
          round2.push(round1[idx]);
          round2.push(round1[idx + 1]);
        }
      }
      var round3 = [round2[0]];
      for(var idx = 1; idx < round2.length; idx += 2) {
        var item = round2[idx];
        if(item.token == 'add') {
          var left = round3.pop();
          var right = round2[idx + 1];
          round3.push(numberItem(compute(left) + compute(right)));
        } else if(item.token == 'subtract') {
          var left = round3.pop();
          var right = round2[idx + 1];
          round3.push(numberItem(compute(left) - compute(right)));
        } else {
          round3.push(round2[idx]);
          round3.push(round2[idx + 1]);
        }
      }
      if(round3.length === 0) {
        throw("expressions should have at least one value");
      } else if(round3.length > 1) {
        throw("unexpected modifier: " + round3[1].token);
      } else {
        return compute(round3[0]);
      }
    };
    var numberItem = function(number) {
      return {
        token: 'number',
        value: number,
        calculatedValue: number
      }
    };
    var compute = function(tree) {
      switch(tree.token) {
      case 'number':
        return parseFloat(tree.value);
        break;
      case 'expression':
        return computeExpression(tree);
        break;
      case 'parenthesized_expression':
        return compute(tree.expression);
        break;
      case 'variable_assignment':
        if(tree.variable.value == '_') {
          throw("the variable '_' is reserved");
        }
        variables[tree.variable.value] = compute(tree.assignmentExpression);
        return variables[tree.variable.value];
        break;
      case 'variable':
        if(tree.value == '_') {
          return lastComputedResult || 0;
        }
        if(tree.value.indexOf("-") == 0) { // the variable is negative, e.g. '-x'
          var absolute = tree.value.replace(/^\-/, "")
          var value = predefinedVariables && predefinedVariables[absolute];
          value = value || (variables && variables[absolute]);
          value = -value;
        } else {
          var value = predefinedVariables && predefinedVariables[tree.value];
          value = value || (variables && variables[tree.value]);
        }
        if (value == undefined) {
          throw("undefined variable " + tree.value);
        }
        return value;
        break;
      case 'method':
        var args = []
        for(var idx in tree.arguments) {
          var value = compute(tree.arguments[idx]);
          tree.arguments[idx].computedValue = value;
          args.push(value);
        }
        if(methods[tree.value]) {
          return methods[tree.value].apply(null, args);
        } else {
          throw("unrecognized method " + tree.value);
        }
        break;
      }
      throw("Unexpected token type: " + tree.token);
    };
    calcCmd.clearMemory = function() {
      variables = {};
      lastComputedResult = null;
    };
    var cached_trees = {};
    calcCmd.compute = function(command) {
      var result = {};
      command = command.toString();
      result.command = command;
      tree = cached_trees[command];
      if(tree) {
        result.syntax = tree.syntax;
        result.tree = tree.tree;
      } else {
        result.syntax = parseSyntax(command);
        result.tree = parseFullExpression(result.syntax);
        cached_trees[command] = result;
      }
      result.computedValue = compute(result.tree);
      lastComputedResult = result.computedValue;
      return result;
    };
    calcCmd.computeValue = function(command) {
      return calcCmd.compute(command).computedValue;
    }
    var isFunction = function(arg) {
      return true;
    }
    calcCmd.addFunction = function(methodName, method, description, examples) {
      if(typeof(methodName) == 'string' && isFunction(method)) {
        method.friendlyName = methodName;
        method.description = description;
        if(typeof(examples) == 'string') {
          examples = [examples];
        }
        method.examples = examples;
        methods[methodName] = method;
        return true;
      }
      return false;
    };
    calcCmd.addPredefinedVariable = function(variableName, value, description) {
      value = parseFloat(value);
      if(typeof(variableName) == 'string' && (value || value == 0)) {
        predefinedVariables[variableName] = value;
      }
    };
    calcCmd.functionDescription = function(method) {
      if(methods[method]) {
        return methods[method].description || I18n.t('no_description', "No description found for the function, %{functionName}", {functionName: method});
      } else {
        return I18n.t('unrecognized', "%{functionName} is not a recognized function", {functionName: method});
      }
    };
    calcCmd.functionExamples = function(method) {
      if(methods[method]) {
        return methods[method].examples || [];
      } else {
        return [];
      }
    };
    calcCmd.functionList = function() {
      var result = [];
      for(var idx in methods) {
        var method = methods[idx];
        result.push([idx, method.description || I18n.t('default_description', "No description given")]);
      }
      result.sort(function(a, b) {
        if(a[0] > b[0]) {
          return 1;
        } else if(a[0] < b[0]) {
          return -1;
        } else {
          return 0;
        }
      });
      return result;
    };
  })();
  (function() {
    var p = function(name, value, description) { calcCmd.addPredefinedVariable(name, value, description); }
    var f = function(name, func, description, example) { calcCmd.addFunction(name, func, description, example); }

    p('pi', Math.PI );
    p('e', Math.exp(1));

    f('abs', function(val) { return Math.abs(val) }, I18n.t('abs.description', "Returns the absolute value of the given value"), "abs(x)");
    f('asin', function(x) { return Math.asin(x); }, I18n.t('asin.description', "Returns the arcsin of the given value"), "asin(x)");
    f('acos', function(x) { return Math.acos(x); }, I18n.t('acos.description', "Returns the arccos of the given value"), "acos(x)");
    f('atan', function(x) { return Math.atan(x); }, I18n.t('atan.description', "Returns the arctan of the given value"), "atan(x)");
    f('log', function(x, base) { return (Math.log(x) / Math.log(base || 10)); }, I18n.t('log.description', "Returns the log of the given value with an optional base"), "log(x, [base])");
    f('ln', function(x) { return Math.log(x); }, I18n.t('ln.description', "Returns the natural log of the given value"), "ln(x)");
    f('rad_to_deg', function(x) { return x * 180 / Math.PI; }, I18n.t('rad_to_deg.description', "Returns the given value converted from radians to degrees"), "rad_to_deg(radians)");
    f('deg_to_rad', function(x) { return x * Math.PI / 180; }, I18n.t('deg_to_rad.description', "Returns the given value converted from degrees to radians"), "deg_to_rad(degrees)");
    f('sin', function(x) { return Math.sin(x); }, I18n.t('sin.description', "Returns the sine of the given value"), "sin(radians)");
    f('cos', function(x) { return Math.cos(x); }, I18n.t('cos.description', "Returns the cosine of the given value"), "cos(radians)" );
    f('tan', function(x) { return Math.tan(x); }, I18n.t('tan.description', "Returns the tangent of the given value"), "tan(radians)");

    f('sec', function(x) { return 1 / Math.cos(x); }, I18n.t('sec.description', "Returns the secant of the given value"), "sec(radians)");
    f('cosec', function(x) { return 1 / Math.sin(x); }, I18n.t('cosec.description', "Returns the cosecant of the given value"), "cosec(radians)" );
    f('cotan', function(x) { return 1 / Math.tan(x); }, I18n.t('cotan.description', "Returns the cotangent of the given value"), "cotan(radians)");

    f('pi', function(x) { return Math.PI; }, I18n.t('pi.description', "Returns the computed value of pi"), "pi()");
    f('if', function(bool, pass, fail) { return bool ? pass : fail; }, I18n.t('if.description', "Evaluates the first argument, returns the second argument if it evaluates to a non-zero value, otherwise returns the third value"), "if(bool,success,fail)");
    var make_list = function(args) {
      if(args.length == 1 && (args[0] instanceof Array)) {
        return args[0];
      } else {
        return args;
      }
    }
    f('max', function() {
      var args = make_list(arguments)
      var max = args[0];
      for(var idx = 0; idx < args.length; idx++) { //in arguments) {
        max = Math.max(max, args[idx]);
      }
      return max;
    }, I18n.t('max.description', "Returns the highest value in the list"), ["max(a,b,c...)", "max(list)"]);
    f('min', function() {
      var args = make_list(arguments);
      var min = args[0];
      for(var idx = 0; idx < args.length; idx++) { //in arguments) {
        min = Math.min(min, args[idx]);
      }
      return min;
    }, I18n.t('min.description', "Returns the lowest value in the list"), ["min(a,b,c...)", "min(list)"]);
    f('sqrt', function(x) { return Math.sqrt(x); }, I18n.t('sqrt.description', "Returns the square root of the given value"), "sqrt(x)");
    f('sort', function(x) {
      var args = make_list(arguments);
      var list = [];
      for(var idx = 0; idx < args.length; idx++) {
        list.push(args[idx]);
      }
      return list.sort(function(a, b) {return a - b;});
    }, I18n.t('sort.description', "Returns the list of values, sorted from lowest to highest"), ["sort(a,b,c...)", "sort(list)"]);
    f('reverse', function(x) {
      var args = make_list(arguments);
      var list = [];
      for(var idx = 0; idx < args.length; idx++) {
        list.unshift(args[idx]);
      }
      return list;
    }, I18n.t('reverse.description', "Reverses the order of the list of values"), ["reverse(a,b,c...)", "reverse(list)"]);
    f('first', function() { return make_list(arguments)[0]; }, I18n.t('first.description', "Returns the first value in the list"), ["first(a,b,c...)", "first(list)"]);
    f('last', function() {
      var args = make_list(arguments);
      return args[args.length - 1];
    }, I18n.t('last.description', "Returns the last value in the list"), ["last(a,b,c...)", "last(list)"]);
    f('at', function(list, x) { return list[x]; }, I18n.t('at.description', "Returns the indexed value in the given list"), "at(list,index)" );
    f('rand', function(x) { return (Math.random() * (x || 1)); }, I18n.t('rand.description', "Returns a random number between zero and the range specified, or one if no number is given"), "rand(x)");
    f('length', function() { return make_list(arguments).length; }, I18n.t('length.description', "Returns the number of arguments in the given list"), ["length(a,b,c...)", "length(list)"]);
    var sum = function(list) {
      var total = 0;
      for(var idx = 0; idx < list.length; idx++) { // in list) {
        if(list[idx]) {
          total += list[idx];
        }
      }
      return total;
    }
    f('mean', function() {
      var args = make_list(arguments);
      return sum(args) / args.length;
    }, I18n.t('mean.description', "Returns the average mean of the values in the list"), ["mean(a,b,c...)", "mean(list)"]);
    f('median', function() {
      var args = make_list(arguments);
      var list = [];
      for(var idx = 0; idx < args.length; idx++) {
        list.push(args[idx]);
      }
      var list = list.sort(function(a, b) {
        return parseFloat(a) - parseFloat(b);
      });
      if(list.length % 2 == 1) {
        return list[Math.floor(list.length / 2)];
      } else {
        return ((list[Math.round(list.length / 2)] + list[Math.round(list.length / 2) - 1]) / 2);
      }
    }, I18n.t('median.description', "Returns the median for the list of values"), ["median(a,b,c...)", "median(list)"]);
    f('range', function() {
      var args = make_list(arguments);
      var list = [];
      for(var idx = 0; idx < args.length; idx++) {
        list.push(args[idx]);
      }
      var list = list.sort();
      return list[list.length - 1] - list[0];
    }, I18n.t('range.description', "Returns the range for the list of values"), ["range(a,b,c...)", "range(list)"]);
    f('count', function() { return make_list(arguments).length; }, I18n.t('count.description', "Returns the number of items in the list"), ["count(a,b,c...)", "count(list)"]);
    f('sum', function() { return sum(make_list(arguments)); }, I18n.t('sum.description', "Returns the sum of the list of values"), ["sum(a,b,c...)", "sum(list)"]);
    var factorials = {};
    var fact = function(n) {
      n = Math.max(parseInt(n), 0);
      if(n == 0 || n == 1) {
        return 1;
      } else if(n > 170) {
        return Infinity;
      } else if(factorials[n]) {
        return factorials[n];
      } else {
        return n * fact(n - 1);
      }
    };
    f('fact', function(n) { return fact(n); }, I18n.t('fact.description', "Returns the factorial of the given number"), "fact(n)");
    f('perm', function(n, k) { return fact(n) / fact(n - k); }, I18n.t('perm.description', "Returns the permutation result for the given values"), "perm(n, k)");
    f('comb', function(n, k) { return fact(n) / (fact(k) * fact(n - k)); }, I18n.t('comb.description', "Returns the combination result for the given values"), "comb(n, k)");
    f('ceil', function(x) { return Math.ceil(x); }, I18n.t('ceil.description', "Returns the ceiling for the given value"), "ceil(x)");
    f('floor', function(x) { return Math.floor(x); }, I18n.t('floor.description', "Returns the floor for the given value"), "floor(x)");
    f('round', function(x) { return Math.round(x); }, I18n.t('round.description', "Returns the given value rounded to the nearest whole number"), "round(x)");
    f('e', function(x) { return Math.exp(x || 1); }, I18n.t('e.description', "Returns the value for e"), "e()");
  })();

  return calcCmd;
});
