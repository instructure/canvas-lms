<style>
  .appendix_entry th { text-align: left; }
  .appendix_entry th,
  .appendix_entry td {
    padding: 10px;
    border: 1px solid #ccc;
  }

  .appendix_entry div.syntaxhighlighter {
    border: none;
    padding: 0;
  }

  .appendix_entry div.syntaxhighlighter table {
    width: 100%;
  }

  .appendix_entry h4 {
    color: green;
  }
</style>

#### Essay Questions

- Question parametric type: `essay_question`
- Parameter type: **`Text`**
- Parameter synopsis: `{ "answer": "Answer text." }`

**Example request**

```javascript
{
  "answer": "<h2>My essay</h2>\n\n<p>This is a long article.</p>"
}
```

**Possible errors**

<table>
  <thead>
    <tr>
      <th>HTTP RC</th>
      <th>Error Message</th>
      <th>Cause</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>400 Bad Request</td>
      <td><code>Text is too long.</code></td>
      <td>The answer text is larger than the allowed limit of 16 kilobytes.</td>
    </tr>
  </tbody>
</table>


#### Fill In Multiple Blanks Questions

- Question parametric type: `fill_in_multiple_blanks_question`
- Parameter type: **`Hash{String => String}`**
- Parameter synopsis: `{ "answer": { "variable": "Answer string." } }`

**Example request**

Given that the question accepts answers to two variables, `color1` and `color2`:

```javascript
{
  "answer": {
    "color1": "red",
    "color2": "green"
  }
}
```

**Possible errors**

<table>
  <thead>
    <tr>
      <th>HTTP RC</th>
      <th>Error Message</th>
      <th>Cause</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>400 Bad Request</td>
      <td><code>Unknown variable 'var'.</code></td>
      <td>The answer map contains a variable that is not accepted by the question.</td>
    </tr>
    <tr>
      <td>400 Bad Request</td>
      <td><code>Text is too long.</code></td>
      <td>The answer text is larger than the allowed limit of 16 kilobytes.</td>
    </tr>
  </tbody>
</table>


#### Fill In The Blank Questions

- Question parametric type: `short_answer_question`
- Parameter type: **`String`**
- Parameter synopsis: `{ "answer": "Some sentence." }`

**Example request**

```javascript
{
  "answer": "Hello World!"
}
```

**Possible errors**

Similar to the errors produced by [Essay Questions](#essay-questions).

<a class="bookmark" id="formula-questions"></a>

#### Formula Questions

- Question parametric type: `calculated_question`
- Parameter type: **`Decimal`**
- Parameter synopsis: `{ "answer": decimal }` where `decimal` is either a rational
  number, or a literal version of it (String)

**Example request**

With an exponent:

```javascript
{
  "answer": 2.3e-6
}
```

With a string for a number:

```javascript
{
  "answer": "13.4"
}
```

**Possible errors**

<table>
  <thead>
    <tr>
      <th>HTTP RC</th>
      <th>Error Message</th>
      <th>Cause</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>400 Bad Request</td>
      <td><code>Parameter must be a valid decimal.</code></td>
      <td>The specified value could not be processed as a decimal.</td>
    </tr>
  </tbody>
</table>



#### Matching Questions

- Question parametric type: `matching_question`
- Parameter type: **`Array<Hash>`**
- Parameter synopsis: `{ "answer": [{ "answer_id": id, "match_id": id }] }` where
  the IDs must identify answers and matches accepted by the question.

**Example request**

Given that the question accepts 3 answers with IDs `[ 3, 6, 9 ]` and 6 matches
with IDs: `[ 10, 11, 12, 13, 14, 15 ]`:

```javascript
{
  "answer": [{
    "answer_id": 6,
    "match_id": 10
  }, {
    "answer_id": 3,
    "match_id": 14
  }]
}
```

The above request:

  - pairs `answer#6` with `match#10`
  - pairs `answer#3` with `match#14`
  - leaves `answer#9` *un-matched*

**Possible errors**

<table>
  <thead>
    <tr>
      <th>HTTP RC</th>
      <th>Error Message</th>
      <th>Cause</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>400 Bad Request</td>
      <td><code>Answer must be of type Array.</code></td>
      <td>The match-pairings set you supplied is not an array.</td>
    </tr>

    <tr>
      <td>400 Bad Request</td>
      <td><code>Answer entry must be of type Hash, got '...'.</code></td>
      <td>One of the entries of the match-pairings set is not a valid hash.</td>
    </tr>

    <tr>
      <td>400 Bad Request</td>
      <td><code>Missing parameter 'answer_id'.</code></td>
      <td>One of the entries of the match-pairings does not specify an <code>answer_id</code>.</td>
    </tr>

    <tr>
      <td>400 Bad Request</td>
      <td><code>Missing parameter 'match_id'.</code></td>
      <td>One of the entries of the match-pairings does not specify an <code>match_id</code>.</td>
    </tr>


    <tr>
      <td>400 Bad Request</td>
      <td><code>Parameter must be of type Integer.</code></td>
      <td>
        One of the specified <code>answer_id</code> or <code>match_id</code>
        is not an integer.
      </td>
    </tr>

    <tr>
      <td>400 Bad Request</td>
      <td><code>Unknown answer '123'.</code></td>
      <td>An <code>answer_id</code> you supplied does not identify a valid answer
      for that question.</td>
    </tr>

    <tr>
      <td>400 Bad Request</td>
      <td><code>Unknown match '123'.</code></td>
      <td>A <code>match_id</code> you supplied does not identify a valid match
      for that question.</td>
    </tr>
  </tbody>
</table>






<a class="bookmark" id="multiple-choice-questions"></a>


#### Multiple Choice Questions

- Question parametric type: `multiple_choice_question`
- Parameter type: **`Integer`**
- Parameter synopsis: `{ "answer": answer_id }` where `answer_id` is an ID of
  one of the question's answers.

**Example request**

Given an answer with an ID of 5:

```javascript
{
  "answer": 5
}
```

**Possible errors**

<table>
  <thead>
    <tr>
      <th>HTTP RC</th>
      <th>Error Message</th>
      <th>Cause</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>400 Bad Request</td>
      <td><code>Parameter must be of type Integer.</code></td>
      <td>The specified `answer_id` is not an integer.</td>
    </tr>
    <tr>
      <td>400 Bad Request</td>
      <td><code>Unknown answer '123'</code></td>
      <td>The specified `answer_id` is not a valid answer.</td>
    </tr>
  </tbody>
</table>

#### Multiple Dropdowns Questions

- Question parametric type: `multiple_dropdowns_question`
- Parameter type: **`Hash{String => Integer}`**
- Parameter synopsis: `{ "answer": { "variable": answer_id } }` where the keys
  are variables accepted by the question, and their values are IDs of answers
  provided by the question.

**Example request**

Given that the question accepts 3 answers to a variable named `color` with the
ids `[ 3, 6, 9 ]`:

```javascript
{
  "answer": {
    "color": 6
  }
}
```

**Possible errors**

<table>
  <thead>
    <tr>
      <th>HTTP RC</th>
      <th>Error Message</th>
      <th>Cause</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>400 Bad Request</td>
      <td><code>Unknown variable 'var'.</code></td>
      <td>The answer map you supplied contains a variable that is not accepted
        by the question.</td>
    </tr>
    <tr>
      <td>400 Bad Request</td>
      <td><code>Unknown answer '123'.</code></td>
      <td>An <code>answer_id</code> you supplied does not identify a valid answer
      for that question.</td>
    </tr>
  </tbody>
</table>

#### Multiple Answers Questions

- Question parametric type: `multiple_answers_question`
- Parameter type: **`Array<Integer>`**
- Parameter synopsis: `{ "answer": [ answer_id ] }` where the array items are
  IDs of answers accepted by the question.

**Example request**

Given that the question accepts 3 answers with the ids `[ 3, 6, 9 ]` and we
want to select the answers `3` and `6`:

```javascript
{
  "answer": [ 3, 6 ]
}
```

**Possible errors**

<table>
  <thead>
    <tr>
      <th>HTTP RC</th>
      <th>Error Message</th>
      <th>Cause</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>400 Bad Request</td>
      <td><code>Selection must be of type Array.</code></td>
      <td>The selection set you supplied is not an array.</td>
    </tr>
    <tr>
      <td>400 Bad Request</td>
      <td><code>Parameter must be of type Integer.</code></td>
      <td>One of the answer IDs you supplied is not a valid ID.</td>
    </tr>

    <tr>
      <td>400 Bad Request</td>
      <td><code>Unknown answer '123'.</code></td>
      <td>An answer ID you supplied in the selection set does not identify a
        valid answer for that question.</td>
    </tr>
  </tbody>
</table>

#### Numerical Questions

- Question parametric type: `numerical_question`

This is similar to [Formula Questions](#formula-questions).

<a class="bookmark" id="essay-questions"></a>

#### True/False Questions

- Question parametric type: `true_false_question`

The rest is similar to [Multiple Choice questions](#multiple-choice-questions).