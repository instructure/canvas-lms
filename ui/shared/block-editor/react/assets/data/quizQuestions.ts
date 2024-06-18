/*
 * Copyright (C) 2024 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

export type QuestionChoice = {
  id: string
  position: number
  item_body: string
}

export const quizQuestions = JSON.parse(`{
  "total": 3,
  "entries": [
    {
      "id": "3",
      "entry_type": "Item",
      "updated_at": "2024-06-04T01:13:50.023Z",
      "created_at": "2024-06-04T01:13:50.346Z",
      "bank_id": "1",
      "entry": {
        "calculator_type": "none",
        "feedback": {},
        "id": "5",
        "interaction_data": {
          "answers": [
            "Bass",
            "Drums",
            "Vocals",
            "Guitar"
          ],
          "questions": [
            {
              "id": "16118",
              "item_body": "Pete Townsend"
            },
            {
              "id": "25705",
              "item_body": "Roger Daltry"
            },
            {
              "id": "8609",
              "item_body": "John Entwistle"
            },
            {
              "id": "44070",
              "item_body": "Keith Moon"
            }
          ]
        },
        "item_body": "<p>Who played what instruments in The Who</p>",
        "label": null,
        "outcome_alignment_set_guid": null,
        "properties": {
          "shuffle_rules": {
            "questions": {
              "shuffled": false
            }
          }
        },
        "status": "mutable",
        "title": null,
        "user_response_type": "HashOfTexts",
        "stimulus_id": "",
        "answer_feedback": {},
        "interaction_type": {
          "id": "7",
          "slug": "matching",
          "name": "Matching",
          "properties_schema": {
            "shuffle_rules": {
              "type": "object",
              "required": [
                "questions"
              ],
              "default": {
                "questions": {
                  "shuffled": false
                }
              },
              "properties": {
                "questions": {
                  "type": "object",
                  "required": [
                    "shuffled"
                  ],
                  "properties": {
                    "shuffled": {
                      "type": "boolean"
                    }
                  }
                }
              }
            }
          },
          "scoring_algorithm_options": [
            "DeepEquals",
            "PartialDeep"
          ],
          "scoring_algorithm_default": "PartialDeep",
          "user_response_type_options": [
            "HashOfTexts"
          ]
        },
        "scoring_data": {
          "value": {
            "8609": "Bass",
            "16118": "Guitar",
            "25705": "Vocals",
            "44070": "Drums"
          },
          "edit_data": {
            "matches": [
              {
                "answer_body": "Guitar",
                "question_id": "16118",
                "question_body": "Pete Townsend"
              },
              {
                "answer_body": "Vocals",
                "question_id": "25705",
                "question_body": "Roger Daltry"
              },
              {
                "answer_body": "Bass",
                "question_id": "8609",
                "question_body": "John Entwistle"
              },
              {
                "answer_body": "Drums",
                "question_id": "44070",
                "question_body": "Keith Moon"
              }
            ],
            "distractors": []
          }
        },
        "scoring_algorithm": "PartialDeep",
        "tag_associations": []
      },
      "archived": false
    },
    {
      "id": "2",
      "entry_type": "Item",
      "updated_at": "2024-06-03T22:48:04.809Z",
      "created_at": "2024-06-03T22:48:04.809Z",
      "bank_id": "1",
      "entry": {
        "calculator_type": "none",
        "feedback": {},
        "id": "4",
        "interaction_data": {
          "true_choice": "True",
          "false_choice": "False"
        },
        "item_body": "<p>The Beatles Abby Road finished a distant 2nd to Blood Sweat &amp; Tears self-titled debut album for the 1970 Grammy for Album of the Year.</p>",
        "label": null,
        "outcome_alignment_set_guid": null,
        "properties": {},
        "status": "mutable",
        "title": null,
        "user_response_type": "Boolean",
        "stimulus_id": "",
        "answer_feedback": {},
        "interaction_type": {
          "id": "3",
          "slug": "true-false",
          "name": "True or False",
          "properties_schema": {},
          "scoring_algorithm_options": [
            "Equivalence"
          ],
          "scoring_algorithm_default": "Equivalence",
          "user_response_type_options": [
            "Boolean"
          ]
        },
        "scoring_data": {
          "value": true
        },
        "scoring_algorithm": "Equivalence",
        "tag_associations": []
      },
      "archived": false
    },
    {
      "id": "1",
      "entry_type": "Item",
      "updated_at": "2024-06-03T21:03:20.827Z",
      "created_at": "2024-06-03T21:03:20.827Z",
      "bank_id": "1",
      "entry": {
        "calculator_type": "none",
        "feedback": {},
        "id": "3",
        "interaction_data": {
          "choices": [
            {
              "id": "e465166b-51ba-4b8d-a47f-4a5ff6eb7d23",
              "position": 1,
              "item_body": "<p>The Rolling Stones</p>"
            },
            {
              "id": "a5db8118-5687-49c7-81df-3c4b36e6581a",
              "position": 2,
              "item_body": "<p>The Who</p>"
            },
            {
              "id": "70bf3513-ff47-42bf-900a-5309adabd9b0",
              "position": 3,
              "item_body": "<p>The Kinks</p>"
            },
            {
              "id": "388591ae-897d-4f27-b5b6-210181b1a3bc",
              "position": 4,
              "item_body": "<p>Grand Funk Railroad</p>"
            }
          ]
        },
        "item_body": "<p>Which is the better rock and roll band?</p>",
        "label": null,
        "outcome_alignment_set_guid": null,
        "properties": {
          "shuffle_rules": {
            "choices": {
              "to_lock": [],
              "shuffled": false
            }
          },
          "vary_points_by_answer": false
        },
        "status": "mutable",
        "title": null,
        "user_response_type": "Uuid",
        "stimulus_id": "",
        "answer_feedback": {},
        "interaction_type": {
          "id": "1",
          "slug": "choice",
          "name": "Multiple Choice",
          "properties_schema": {
            "vary_points_by_answer": {
              "type": "boolean",
              "required": false,
              "default": false
            },
            "shuffle_rules": {
              "type": "object",
              "required": [
                "choices"
              ],
              "default": {
                "choices": {
                  "shuffled": false
                }
              },
              "properties": {
                "choices": {
                  "type": "object",
                  "required": [
                    "shuffled"
                  ],
                  "properties": {
                    "shuffled": {
                      "type": "boolean"
                    },
                    "to_lock": {
                      "type": "array"
                    }
                  }
                }
              }
            }
          },
          "scoring_algorithm_options": [
            "Equivalence",
            "VaryPointsByAnswer"
          ],
          "scoring_algorithm_default": "Equivalence",
          "user_response_type_options": [
            "Uuid"
          ]
        },
        "scoring_data": {
          "value": "e465166b-51ba-4b8d-a47f-4a5ff6eb7d23"
        },
        "scoring_algorithm": "Equivalence",
        "tag_associations": []
      },
      "archived": false
    }
  ],
  "filters": {
    "interaction_types": [
      {
        "interaction_type": {
          "id": "1",
          "slug": "choice",
          "name": "Multiple Choice"
        },
        "count": 1
      },
      {
        "interaction_type": {
          "id": "3",
          "slug": "true-false",
          "name": "True or False"
        },
        "count": 1
      },
      {
        "interaction_type": {
          "id": "7",
          "slug": "matching",
          "name": "Matching"
        },
        "count": 1
      }
    ],
    "tags": []
  }
}`)
