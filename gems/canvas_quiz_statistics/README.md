# CanvasQuizStatistics

A bunch of objects that can generate statistics from a set of responses to a quiz.

_Work In Progress._

## Extending

### Adding support for a new question type

**Implementing the analyzer**

  - define an answer analyzer in `answer_analyzers/question_type.rb`
  - make sure your analyzer implements the common interface, which is defined
    by the `AnswerAnalyzer::Base` class
  - please document both output *and* input formats that you expect to generate the stats

**Registering it**

Edit `lib/canvas_quiz_statistics/answer_analyzers.rb` and:

  + require your analyzer
  + add it to the list of available analyzers in
    `CanvasQuizStatistics::AnswerAnalyzers::AVAILABLE_ANALYZERS`
    where the key should be the question type (with the `_question` suffix)
    and the value would be your analyzer

**Covering it**

You will probably need to simulate question data to cover your analyzer. Grab a JSON snapshot of the `question_data` construct for your question and save it in `spec/support/fixtures/` and check out the fixture helpers in `spec/support/question_helpers.rb` for more information on how to use the fixture.