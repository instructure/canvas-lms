define([
  'jsx/quizzes/question_bank/loadBanks'
], (loadBanks) => {
  QUnit.module("loadBanks");

  test("is a function", () => {
    ok(typeof loadBanks === 'function')
  })
});
