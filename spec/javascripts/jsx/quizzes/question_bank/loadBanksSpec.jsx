define([
  'jsx/quizzes/question_bank/loadBanks'
], (loadBanks) => {
  module("loadBanks");

  test("is a function", () => {
    ok(typeof loadBanks === 'function')
  })
});
