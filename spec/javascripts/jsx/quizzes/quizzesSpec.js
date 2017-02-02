if (!Object.assign) {
  Object.assign = function assign (...args) {
    const first = args.shift();
    args.forEach((arg) => {
      const keys = Object.keys(arg);
      keys.forEach((key) => {
        first[key] = arg[key]
      })
    })
    return first;
  }
}

/* NOTE: this test is meant to test 'quizzes', but you'll notice that the define
   does not include the 'quizzes' module. this is because simply including the
   quizzes module breaks the KeyboardShortcutsSpec.js spec test later. there is
   a side effect from including 'quizzes' when the $document.ready() method is
   called. a line in there calls the render() of RCEKeyboardShortcut which
   creates a side effect to fail a later test. so what we do here is stub out
   the ready() $.fn , then restore it after we are done
   to avoid the side-effect. see CNVS-30988.
*/

define([
  'jquery'
], ($) => {
  const $questionContent = {bind () {}}

  QUnit.module('isChangeMultiFuncBound', {
    setup () {
      this.sandb = this.sandbox.create();
      this.sandb.stub($, '_data');
      this.sandb.stub($.fn, 'ready');
    },
    teardown () {
      this.sandb.restore();
    }
  })

  test('gets events from data on first element', (assert) => {
    const done = assert.async();
    const $el = [{}];
    require(['quizzes'], ({isChangeMultiFuncBound}) => {
      isChangeMultiFuncBound($el);
      ok($._data.calledWithExactly($el[0], 'events'));
      done();
    });
  });

  test('returns true if el has correct change event', (assert) => {
    const done = assert.async();
    const $el = [{}];
    const events = {
      change: [{handler: {origFuncNm: 'changeMultiFunc'}}]
    }
    require(['quizzes'], ({isChangeMultiFuncBound}) => {
      $._data.returns(events);
      ok(isChangeMultiFuncBound($el));
      done();
    });
  });

  test('returns false if el has incorrect change event', (assert) => {
    const done = assert.async();
    const $el = [{}];
    const events = {
      change: [{handler: {name: 'other'}}]
    }
    require(['quizzes'], ({isChangeMultiFuncBound}) => {
      $._data.returns(events);
      ok(!isChangeMultiFuncBound($el));
      done();
    });
  });

  let sandbx;
  QUnit.module('rebindMultiChange', {
    setup () {
      sandbx = this.sandbox.create();
      this.sandb = this.sandbox.create();
      this.sandb.stub($questionContent, 'bind');
      this.sandb.stub($, '_data');
      this.sandb.stub($.fn, 'ready');
      $questionContent.bind.returns({change () {}});
    },
    teardown () {
      this.sandb.restore();
      sandbx.restore();
    }
  });

  test('rebinds event on questionContent', (assert) => {
    const done = assert.async();
    const questionType = 'multiple_dropdowns_question';
    const events = {
      change: [{handler: {name: 'other'}}]
    }
    $._data.returns(events);
    require(['quizzes'], ({quiz}) => {
      sandbx.stub(quiz, 'loadJQueryElemById');
      quiz.loadJQueryElemById.returns($questionContent);
      quiz.rebindMultiChange(questionType, 'question_content_0', {});
      equal($questionContent.bind.callCount, 1);
      done();
    });
  });

  test('does nothing if "change" event exists', (assert) => {
    const done = assert.async();
    const questionType = 'multiple_dropdowns_question';
    const events = {
      change: [{handler: {origFuncNm: 'changeMultiFunc'}}]
    }
    $._data.returns(events);
    require(['quizzes'], ({quiz}) => {
      sandbx.stub(quiz, 'loadJQueryElemById');
      quiz.loadJQueryElemById.returns($questionContent);
      quiz.rebindMultiChange(questionType, 'question_content_0', {});
      equal($questionContent.bind.callCount, 0);
      done();
    });
  });

  test('does nothing if wrong questionType', (assert) => {
    const done = assert.async();
    const questionType = 'other_question';
    const events = {
      change: [{handler: {name: 'other'}}]
    }
    $._data.returns(events);
    require(['quizzes'], ({quiz}) => {
      sandbx.stub(quiz, 'loadJQueryElemById');
      quiz.loadJQueryElemById.returns($questionContent);
      quiz.rebindMultiChange(questionType, 'question_content_0', {});
      equal($questionContent.bind.callCount, 0);
      done();
    });
  });
});
