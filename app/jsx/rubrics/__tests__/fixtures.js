/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import _ from 'lodash'
import { fillAssessment } from '../helpers'

export const rubric = {
  "id": "7",
  "context_id": "1",
  "context_type": "Account",
  "points_possible": 11,
  "title": "Point Rubric",
  "reusable": false,
  "public": false,
  "read_only": true,
  "free_form_criterion_comments": false,
  "hide_score_total": false,
  "criteria": [
    {
      "description": "Description of criterion",
      "long_description": "",
      "points": 8,
      "id": "_1384",
      "criterion_use_range": false,
      "ratings": [
        {
          "description": "Full Marks",
          "long_description": "",
          "points": 8,
          "criterion_id": "_1384",
          "id": "blank"
        },
        {
          "description": "bleh",
          "long_description": "blah",
          "points": 3,
          "criterion_id": "_1384",
          "id": "7_4778"
        },
        {
          "description": "No Marks",
          "long_description": "",
          "points": 0,
          "criterion_id": "_1384",
          "id": "blank_2"
        }
      ]
    },
    {
      "description": "Javel, Isak hadde ogsaa lauvet kraftig og hadde nu en Mængde Lauv av bedste Slag.",
      "long_description": "sa Sivert.",
      "points": 3,
      "id": "7_391",
      "criterion_use_range": false,
      "learning_outcome_id": "612",
      "mastery_points": 3,
      "ignore_for_scoring": false,
      "ratings": [
        {
          "description": "Naturligvis hadde han ogsaa længe forstaat hvorfor Inger hadde ordet om.",
          "long_description": "",
          "points": 3,
          "criterion_id": "7_391",
          "id": "7_6639"
        },
        {
          "description": "De levet tæt hos hverandre som Dyr i Skogen, de sov og spiste, det lidde saa.",
          "long_description": "",
          "points": 2,
          "criterion_id": "7_391",
          "id": "7_194"
        },
        {
          "description": "Et graat og rødt Uldtørklæde med Frynser var pragtfuldt paa hendes mørke Haar.",
          "long_description": "",
          "points": 1,
          "criterion_id": "7_391",
          "id": "7_8479"
        }
      ]
    }
  ]
}

const pointsAssessment = {
  "id": "2",
  "rubric_id": "7",
  "rubric_association_id": "8",
  "score": 6,
  "artifact_id": "11",
  "artifact_type": "Submission",
  "assessment_type": "grading",
  "assessor_id": "3",
  "artifact_attempt": 1,
  "data": [
    {
      "points": 3.2,
      "criterion_id": "_1384",
      "learning_outcome_id": null,
      "description": "bleh",
      "comments_enabled": true,
      "comments": "i'd like to say some things",
      "id": "7_4778"
    },
    {
      "points": 3,
      "criterion_id": "7_391",
      "learning_outcome_id": "612",
      "description": "Naturligvis hadde han ogsaa længe forstaat hvorfor Inger hadde.",
      "comments_enabled": true,
      "comments": "here too",
      "above_threshold": false,
      "id": "7_6639"
    }
  ],
  rubric_association: {
    "id": "8",
    "rubric_id": "7",
    "association_id": "2",
    "association_type": "Assignment",
    "use_for_grading": false,
    "created_at": "2018-04-27T17:50:19Z",
    "updated_at": "2018-04-27T17:59:39Z",
    "title": "Example Assignment",
    "summary_data": null,
    "purpose": "grading",
    "url": null,
    "context_id": "6",
    "context_type": "Course",
    "hide_score_total": false,
    "bookmarked": true,
    "context_code": "course_6",
    "hide_points": false,
    "hide_outcome_results": false
  }
}

const freeFormAssessment = {
  "id": "3",
  "rubric_id": "8",
  "rubric_association_id": "9",
  "score": 0,
  "artifact_id": "12",
  "artifact_type": "Submission",
  "assessment_type": "grading",
  "assessor_id": "3",
  "artifact_attempt": null,
  "data": [
    {
      "points": 0,
      "criterion_id": "_1384",
      "learning_outcome_id": null,
      "description": "No Marks",
      "comments_enabled": true,
      "comments": "",
      "id": "blank_2"
    },
    {
      "points": 0,
      "criterion_id": "7_391",
      "learning_outcome_id": "612",
      "description": "No details",
      "comments_enabled": true,
      "comments": "I award you no points, and may God have mercy on your soul.",
      "above_threshold": false,
      "comments_html": "I award you <b>no</b> points, and may God have mercy on your soul."
    }
  ],
  rubric_association: {
    "id": "8",
    "rubric_id": "7",
    "association_id": "2",
    "association_type": "Assignment",
    "use_for_grading": false,
    "created_at": "2018-04-27T17:50:19Z",
    "updated_at": "2018-04-27T17:59:39Z",
    "title": "Example Assignment",
    "summary_data": null,
    "purpose": "grading",
    "url": null,
    "context_id": "6",
    "context_type": "Course",
    "hide_score_total": false,
    "bookmarked": true,
    "context_code": "course_6",
    "hide_points": false,
    "hide_outcome_results": false
  }
}

export const rubrics = {
  points: rubric,
  freeForm: {
    ...(_.cloneDeep(rubric)),
    "title": "Free-form Rubric",
    "free_form_criterion_comments": true
  }
}

export const assessments = {
  points: fillAssessment(rubric, pointsAssessment),
  freeForm: fillAssessment(rubrics.freeForm, freeFormAssessment),
  server: {
    points: pointsAssessment,
    freeForm: freeFormAssessment
  }
}
