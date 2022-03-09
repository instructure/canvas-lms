/*
 * Copyright (C) 2022 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

const createScopedTranslateCall = require("./scoped_translate_call")
const Errors = require("./errors");
const { default: I18nJsExtractor } = require("@instructure/i18nliner/dist/lib/extractors/i18n_js_extractor");
const { default: TranslateCall } = require("@instructure/i18nliner/dist/lib/extractors/translate_call");

const ScopedTranslateCall = createScopedTranslateCall(TranslateCall);
const CANVAS_I18N_PACKAGE = '@canvas/i18n'
const CANVAS_I18N_USE_SCOPE_SPECIFIER = 'useScope'
const CANVAS_I18N_RECEIVER = 'I18n'

// This extractor implementation is suitable for ES modules where a module
// imports the "useScope" function from the @canvas/i18n package and assigns the
// output of a call to that function to a receiver named exactly "I18n". Calls
// to the "t" or "translate" methods on that receiver will use the scope
// supplied to that "useScope" call.
//
//     import { useScope } from '@canvas/i18n'
//
//     const I18n = useScope('foo')
//
//     I18n.t('my_key', 'Hello world!')
//     // => { "foo": { "my_key": "Hello World" } }
//
// The extractor looks for the I18n receiver defined in the current lexical
// scope of the call to I18n.t():
//
//     function a() {
//       const I18n = useScope('foo')
//       I18n.t('my_key', 'Key in foo') // => foo.my_key
//     }
//
//     function b() {
//       const I18n = useScope('bar')
//       I18n.t('my_key', 'Key in bar') // => bar.my_key
//     }
//
// Note that the receiver MUST be identified as "I18n". The (base) extractor
// will fail to recognize any translate calls if the output of useScope is
// assigned to a receiver with a different identifier. With that said, the
// identifier for useScope can be renamed at will:
//
//     // this is OK:
//     import { useScope as useI18nScope } from '@canvas/i18n'
//     const I18n = useI18nScope('foo')
//
//     // this is NOT ok:
//     import { useScope } from '@canvas/i18n'
//     const smth = useScope('foo')
//
class ScopedESMExtractor extends I18nJsExtractor {
  constructor() {
    super(...arguments)

    // the identifier for the "useScope" specifier imported from @canvas/i18n,
    // which may be renamed
    this.useScopeIdentifier = null

    // mapping of "I18n" receivers to the (i18n) scopes they were assigned in
    // the call to useScope
    this.receiverScopeMapping = new WeakMap()
  };

  enter(path) {
    // import { useScope } from '@canvas/i18n'
    //          ^^^^^^^^
    // import { useScope as blah } from '@canvas/i18n'
    //                      ^^^^
    if (!this.useScopeIdentifier && path.type === 'ImportDeclaration') {
      trackUseScopeIdentifier.call(this, path);
    }
    // let I18n
    //     ^^^^
    // I18n = useScope('foo')
    //                  ^^^
    // (this happens in CoffeeScript when compiled to JS)
    else if (this.useScopeIdentifier && path.type === 'AssignmentExpression') {
      indexScopeFromAssignment.call(this, path)
    }
    // const I18n = useScope('foo')
    //       ^^^^             ^^^
    else if (this.useScopeIdentifier && path.type === 'VariableDeclarator') {
      indexScopeFromDeclaration.call(this, path)
    }

    return super.enter(...arguments)
  };

  buildTranslateCall(line, method, args, path) {
    const binding = path.scope.getBinding(CANVAS_I18N_RECEIVER)
    const scope = this.receiverScopeMapping.get(binding)

    if (scope) {
      return new ScopedTranslateCall(line, method, args, scope);
    }
    else {
      throw new Errors.UnscopedTranslateCall(line)
    }
  };
};

function trackUseScopeIdentifier({ node }) {
  if (
    node.source &&
    node.source.type === 'StringLiteral' &&
    node.source.value === CANVAS_I18N_PACKAGE
  ) {
    const specifier = node.specifiers.find(x =>
      x.type === 'ImportSpecifier'&&
      x.imported &&
      x.imported.type === 'Identifier' &&
      x.imported.name === CANVAS_I18N_USE_SCOPE_SPECIFIER
    )

    if (
      specifier &&
      specifier.type === 'ImportSpecifier' &&
      specifier.local &&
      specifier.local.type === 'Identifier' &&
      specifier.local.name
    ) {
      this.useScopeIdentifier = specifier.local.name
    }
  }
};

function indexScopeFromAssignment(path) {
  return indexScope.call(this, path, path.node.left, path.node.right)
};

function indexScopeFromDeclaration(path) {
  return indexScope.call(this, path, path.node.id, path.node.init)
};

// left: Identifier
// right: CallExpression
function indexScope(path, left, right) {
  if (
    left &&
    left.type === 'Identifier' &&
    left.name === CANVAS_I18N_RECEIVER &&
    right &&
    right.type === 'CallExpression' &&
    right.callee &&
    right.callee.type === 'Identifier' &&
    right.callee.name === this.useScopeIdentifier &&
    right.arguments &&
    right.arguments.length === 1 &&
    right.arguments[0].type === 'StringLiteral' &&
    right.arguments[0].value
  ) {
    this.receiverScopeMapping.set(
      path.scope.getBinding(CANVAS_I18N_RECEIVER),
      right.arguments[0].value
    )
  }
};

module.exports = ScopedESMExtractor;
