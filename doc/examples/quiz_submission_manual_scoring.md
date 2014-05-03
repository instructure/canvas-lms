**Parameter synopsis**

```javascript
{
  "quiz_submissions": [{
    "fudge_points": null, // null for no change, or a signed decimal
    "questions": {
      "QUESTION_ID": {
        "score": null, // null for no change, or an unsigned decimal
        "comment": null // null for no change, '' for no comment, or a string
      }
    }
  }]
}
```

### More example requests

**Fudging the score by a negative amount**

```javascript
{
  "quiz_submissions": [{
    "attempt": 1,
    "fudge_points": -2.4
  }]
}
```

**Removing an earlier comment on a question**

```javascript
{
  "quiz_submissions": [{
    "attempt": 1,
    "questions": {
      "1": {
        "comment": ""
      }
    }
  }]
}
```