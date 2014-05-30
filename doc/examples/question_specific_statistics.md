Based on the question type it represents, the `question_statistics` document
may include extra metrics. You can find these metrics below.

#### Multiple Choice & True/False

```javascript
{
  // Number of students who have answered this question.
  "answered_student_count": 0,

  // Number of students who rank in the top bracket (the top 27%)
  // among the submitters which have also answered this question.
  "top_student_count": 0,

  // Number of students who rank in the middle bracket (the middle 46%)
  // among the submitters which have also answered this question.
  "middle_student_count": 0,

  // Number of students who rank in the bottom bracket (the bottom 27%)
  // among the submitters which have also answered this question
  "bottom_student_count": 0,

  // Number of students who have answered this question correctly.
  "correct_student_count": 0,

  // Number of students who have answered this question incorrectly.
  "incorrect_student_count": 0,

  // Ratio of students who have answered this question correctly.
  "correct_student_ratio": 0,

  // Ratio of students who have answered this question incorrectly.
  "incorrect_student_ratio": 0,

  // Number of students who rank in the top bracket (the top 27%) among
  // the submitters which have also provided a correct answer to this question.
  "correct_top_student_count": 0,

  // Number of students who rank in the middle bracket (the middle 46%) among
  // the submitters which have also provided a correct answer to this question.
  "correct_middle_student_count": 0,

  // Number of students who rank in the bottom bracket (the bottom 27%) among
  // the submitters which have also provided a correct answer to this question.
  "correct_bottom_student_count": 0,

  // Variance of *all* the scores.
  "variance": 0,

  // Standard deviation of *all* the scores.
  "stdev": 0,

  // Denotes the ratio of students who have answered this question correctly,
  // which should give an indication of how difficult the question is.
  "difficulty_index": 0,

  // The reliability, or internal consistency, coefficient of all the scores
  // as measured by the Cronbach's alpha algorithm. Value ranges between 0 and
  // 1.
  //
  // Note: This metric becomes available only in quizzes with more than fifteen
  // submissions.
  "alpha": null,

  // A point biserial correlation coefficient for each of the question's
  // answers. This metric helps measure the efficiency of an individual
  // question: the calculation looks at the difference between high-scorers
  // who chose this answer and low-scorers who also chose this answer.
  //
  // See the reference above for a description of each field.
  "point_biserials": [
    {
      "answer_id": 3866,
      "point_biserial": null,
      "correct": true,
      "distractor": false
    },
    {
      "answer_id": 2040,
      "point_biserial": null,
      "correct": false,
      "distractor": true
    },
    {
      "answer_id": 7387,
      "point_biserial": null,
      "correct": false,
      "distractor": true
    },
    {
      "answer_id": 4082,
      "point_biserial": null,
      "correct": false,
      "distractor": true
    }
  ]
}
```

#### Fill in Multiple Blanks

```javascript
{
  // TODO
  "multiple_responses": null,
  // TODO
  "answer_sets": null
}
```

#### Multiple Dropdowns

```javascript
{
  // TODO
  "multiple_responses": null,
  // TODO
  "answer_sets": null
}
```

#### Essay

```javascript
{
  // TODO
  "essay_responses": null
}
```

#### Matching

```javascript
{
  // TODO
  "matching_answer_incorrect_matches": null,
  // TODO
  "matches": null,
  // TODO
  "multiple_answers": null
}
```
