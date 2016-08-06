define([
  'jsx/quizzes/question_bank/addBank'
], (addBank) => {
  module("addBank")
  test("is a function", () => {
    ok(typeof addBank === 'function')
  });
});
