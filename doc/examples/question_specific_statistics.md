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

<a class="bookmark" id="fimb-question-stats"></a>

#### Fill in Multiple Blanks

```javascript
{
  // Number of students who have filled at least one blank.
  "responses": 2,

  // Number of students who have filled every blank.
  "answered": 2,

  // Number of students who filled all blanks correctly.
  "correct": 1,

  // Number of students who filled one or more blanks correctly.
  "partially_correct": 0,

  // Number of students who didn't fill any blank correctly.
  "incorrect": 1,

  // Each entry in the answer set represents a blank and responses to
  // its pre-defined answers:
  "answer_sets": [
    {
      "id": "70dda5dfb8053dc6d1c492574bce9bfd", // md5sum of the blank
      "text": "color", // the blank_id
      "answers": [
        // Students who filled in this blank with this correct answer:
        {
          "id": "9711",
          "text": "Red",
          "responses": 3,
          "correct": true
        },
        // Students who filled in this blank with this other correct answer:
        {
          "id": "2700",
          "text": "Blue",
          "responses": 0,
          "correct": true
        },
        // Students who filled in this blank with something else:
        {
          "id": "other",
          "text": "Other",
          "responses": 1,
          "correct": false
        },
        // Students who left this blank empty:
        {
          "id": "none",
          "text": "No Answer",
          "responses": 1,
          "correct": false
        }
      ]
    }
  ]
}
```

#### Multiple Dropdowns

Multiple Dropdown question statistics look just like the statistics for [Fill In Multiple Blanks](#fimb-question-stats).

<a class="bookmark" id="essay-question-stats"></a>

#### Essay

```javascript
{
   // The number of students whose responses were graded by the teacher so
   // far.
   "graded": 5,

   // The number of students who got graded with a full score.
   "full_credit": 4,

   // Number of students who wrote any kind of answer.
   "resposes": 5,

   // A set of maps of scores and the number of students who received
   // each score.
   "point_distribution": [
     { "score": 0, "count": 1 },
     { "score": 1, "count": 1 },
     { "score": 3, "count": 3 }
   ]
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

#### File Upload

File Upload question statistics look just like the statistics for [Essays](#essay-question-stats).


#### Formula

Formula question statistics look just like the statistics for [Essays](#essay-question-stats).
