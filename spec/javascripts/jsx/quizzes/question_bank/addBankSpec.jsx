define([
  'jsx/quizzes/question_bank/addBank'
], (addBank) => {
  QUnit.module("addBank")
  test("is a function", () => {
    ok(typeof addBank === 'function')
  });
});
