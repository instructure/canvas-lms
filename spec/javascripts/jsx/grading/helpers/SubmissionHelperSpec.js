/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {
  isPostable,
  isHideable,
  extractSimilarityInfo,
  similarityIcon,
} from '@canvas/grading/SubmissionHelper'

QUnit.module('SubmissionHelper', suiteHooks => {
  let submission
  let snakeCasedSubmission

  suiteHooks.beforeEach(() => {
    submission = {
      excused: false,
      hasPostableComments: false,
      score: null,
      submissionComments: [],
      workflowState: 'unsubmitted',
      postedAt: null,
    }

    snakeCasedSubmission = {
      excused: false,
      has_postable_comments: false,
      score: null,
      submission_comments: [],
      workflow_state: 'unsubmitted',
      posted_at: null,
    }
  })

  QUnit.module('.isPostable', () => {
    QUnit.module('when submission is excused', excusedHooks => {
      excusedHooks.beforeEach(() => {
        submission.excused = true
      })

      test('returns true', () => {
        strictEqual(isPostable(submission), true)
      })
    })

    QUnit.module('when submission is not excused', () => {
      test('is true when submission workflow state is graded and score is present', () => {
        submission.score = 1
        submission.workflowState = 'graded'
        strictEqual(isPostable(submission), true)
      })

      test('is true when submission hasPostableComments is true', () => {
        submission.hasPostableComments = true
        strictEqual(isPostable(submission), true)
      })

      test('is false when workflow state is not graded and hasPostableComments is not true', () => {
        submission.score = 1
        strictEqual(isPostable(submission), false)
      })

      test('is false when score is not present and hasPostableComments is not true', () => {
        submission.workflowState = 'graded'
        strictEqual(isPostable(submission), false)
      })
    })

    test('handles snake_cased submission keys', () => {
      snakeCasedSubmission.score = 1
      snakeCasedSubmission.workflow_state = 'graded'
      strictEqual(isPostable(snakeCasedSubmission), true)
    })
  })

  QUnit.module('.isHideable', () => {
    test('is true when submission is posted', () => {
      submission.postedAt = '2020-10-20T15:24:26Z'
      strictEqual(isHideable(submission), true)
    })

    test('is false when submission is not posted', () => {
      strictEqual(isHideable(submission), false)
    })

    test('handles snake_cased submission keys', () => {
      snakeCasedSubmission.posted_at = '2020-10-20T15:24:26Z'
      strictEqual(isHideable(snakeCasedSubmission), true)
    })
  })

  QUnit.module('.extractSimilarityInfo', () => {
    QUnit.module('"type" return value', () => {
      test('returns "originality_report" if the submission has hasOriginalityReport set to true', () => {
        const originalityReportSubmission = {
          has_originality_report: true,
          id: '1001',
          submission_type: 'online_text_entry',
          turnitinData: {
            submission_1001: {state: 'scored', similarity_score: 50.0},
          },
        }

        strictEqual(extractSimilarityInfo(originalityReportSubmission).type, 'originality_report')
      })

      test('returns "turnitin" if the submission has turnitinData', () => {
        const turnitinSubmission = {
          id: '1001',
          submission_type: 'online_text_entry',
          turnitin_data: {
            submission_1001: {state: 'scored', similarity_score: 50.0},
          },
        }
        strictEqual(extractSimilarityInfo(turnitinSubmission).type, 'turnitin')
      })

      test('returns "vericite" if the submission has vericiteData and the provider is "vericite"', () => {
        const vericiteSubmission = {
          id: '1001',
          submission_type: 'online_text_entry',
          vericite_data: {
            provider: 'vericite',
            submission_1001: {state: 'scored', similarity_score: 50.0},
          },
        }
        strictEqual(extractSimilarityInfo(vericiteSubmission).type, 'vericite')
      })
    })

    QUnit.module('"entries" return value', () => {
      QUnit.module('for a submission that accepts online attachments', attachmentHooks => {
        let submissionWithAttachments
        let submissionWithNestedAttachment

        attachmentHooks.beforeEach(() => {
          submissionWithAttachments = {
            attachments: [{id: '2001'}, {id: '2002'}, {id: '2003'}, {id: '2004'}, {id: '9999'}],
            id: '1001',
            submission_type: 'online_upload',
            turnitin_data: {
              attachment_2001: {status: 'scored', similarity_score: 25},
              attachment_2002: {status: 'scored', similarity_score: 75},
              attachment_2003: {status: 'pending'},
              attachment_2004: {status: 'error'},
            },
          }

          submissionWithNestedAttachment = {
            attachments: [{attachment: {id: '3001'}}],
            id: '1001',
            submission_type: 'online_upload',
            turnitin_data: {
              attachment_3001: {status: 'scored', similarity_score: 40},
            },
          }
        })

        test('returns an item for each attachment with plagiarism data', () => {
          strictEqual(extractSimilarityInfo(submissionWithAttachments).entries.length, 4)
        })

        test('sorts entries by status', () => {
          const entries = extractSimilarityInfo(submissionWithAttachments).entries
          const orderedStatuses = entries.map(entry => entry.data.status)
          deepEqual(orderedStatuses, ['error', 'pending', 'scored', 'scored'])
        })

        test('sorts scored entries by decreasing similarity score', () => {
          const entries = extractSimilarityInfo(submissionWithAttachments).entries
          const scoredEntries = entries.filter(entry => entry.data.status === 'scored')
          deepEqual(
            scoredEntries.map(entry => entry.data.similarity_score),
            [75, 25]
          )
        })

        test('sets the "id" field for each entry to the ID of the attachment for that entry', () => {
          const entries = extractSimilarityInfo(submissionWithAttachments).entries
          deepEqual(
            entries.map(entry => entry.id),
            ['attachment_2004', 'attachment_2003', 'attachment_2002', 'attachment_2001']
          )
        })

        test('uses data from the "attachment" field nested inside the attachment if present', () => {
          const entry = extractSimilarityInfo(submissionWithNestedAttachment).entries[0]
          strictEqual(entry.id, 'attachment_3001')
        })
      })

      QUnit.module('for a text entry submission', textEntryHooks => {
        let unversionedSubmission
        let versionedSubmission
        let versionKey

        textEntryHooks.beforeEach(() => {
          unversionedSubmission = {
            id: '1001',
            submission_type: 'online_text_entry',
            turnitinData: {
              submission_1001: {status: 'error'},
            },
          }

          versionKey = 'submission_1001_1997-10-01T11:22:00Z'
          versionedSubmission = {
            id: '1001',
            submission_type: 'online_text_entry',
            submitted_at: '01 October 1997 11:22 UTC',
            turnitinData: {
              submission_1001: {status: 'pending'},
            },
          }
          versionedSubmission.turnitinData[versionKey] = {
            status: 'scored',
            similarity_score: 50.0,
          }
        })

        test('returns plagiarism data for the current version of the submission if it exists', () => {
          const entry = extractSimilarityInfo(versionedSubmission).entries[0]
          deepEqual(entry.data, {status: 'scored', similarity_score: 50.0})
        })

        test('returns an "id" field corresponding to the current version of the submission if it exists', () => {
          const entry = extractSimilarityInfo(versionedSubmission).entries[0]
          strictEqual(entry.id, versionKey)
        })

        test('returns at most one plagiarism entry even if data exists for multiple versions', () => {
          strictEqual(extractSimilarityInfo(versionedSubmission).entries.length, 1)
        })

        test('returns plagiarism data for the base submission if no version-specific data exists', () => {
          const entry = extractSimilarityInfo(unversionedSubmission).entries[0]
          deepEqual(entry.data, {status: 'error'})
        })

        test('returns an "id" field corresponding to the base submission if no version-specific data exists', () => {
          const entry = extractSimilarityInfo(unversionedSubmission).entries[0]
          strictEqual(entry.id, 'submission_1001')
        })
      })
    })

    test('returns null if the submission has no turnitinData or vericiteData', () => {
      const submissionWithNoPlagiarismInfo = {
        id: '1001',
      }
      strictEqual(extractSimilarityInfo(submissionWithNoPlagiarismInfo), null)
    })

    test('returns null if the submission has no plagiarism data matching known attachments', () => {
      const submissionWithImmaterialPlagiarismInfo = {
        attachments: [{id: '2001'}],
        id: '1001',
        submission_type: 'online_upload',
        turnitin_data: {
          attachment_9999: {status: 'error'},
        },
      }
      strictEqual(extractSimilarityInfo(submissionWithImmaterialPlagiarismInfo), null)
    })

    test('returns null for a versioned text submission with only plagiarism data for older versions', () => {
      const otherVersionKey = 'submission_1001_1995-10-01T11:22:00Z'
      const submissionWithOldVersionInfo = {
        id: '1001',
        submission_type: 'online_text_entry',
        submitted_at: '01 October 1997 11:22 UTC',
        turnitinData: {},
      }
      submissionWithOldVersionInfo.turnitinData[otherVersionKey] = {status: 'error'}
      strictEqual(extractSimilarityInfo(submissionWithOldVersionInfo), null)
    })

    test('returns null if the submission is not an upload or text entry submission', () => {
      const submissionWithNoSubmissions = {
        id: '1001',
        submission_type: 'on_paper',
        turnitin_data: {
          submission_1001: {status: 'error'},
        },
      }
      strictEqual(extractSimilarityInfo(submissionWithNoSubmissions), null)
    })
  })

  QUnit.module('.similarityIcon', () => {
    const domParser = new DOMParser()
    const icon = iconString =>
      domParser.parseFromString(similarityIcon(iconString), 'text/xml').documentElement

    const iconClasses = iconString => [...icon(iconString).classList]

    test('returns an <i> element', () => {
      strictEqual(icon({status: 'scored', similarity_score: 50}).nodeName, 'i')
    })

    test('returns a warning icon if the passed item has an "error" status', () => {
      deepEqual(iconClasses({status: 'error'}), ['icon-warning'])
    })

    test('returns a clock icon if the passed item has an "pending" status', () => {
      deepEqual(iconClasses({status: 'pending'}), ['icon-clock'])
    })

    test('returns an empty-but-solid icon if the passed item is scored above 60', () => {
      deepEqual(iconClasses({status: 'scored', similarity_score: 80}), ['icon-empty', 'icon-Solid'])
    })

    test('returns a solid half-oval icon if the passed item is scored betwen 20 and 60', () => {
      deepEqual(iconClasses({status: 'scored', similarity_score: 40}), [
        'icon-oval-half',
        'icon-Solid',
      ])
    })

    test('returns a solid and certified icon if the passed item is scored up to 20', () => {
      deepEqual(iconClasses({status: 'scored', similarity_score: 20}), [
        'icon-certified',
        'icon-Solid',
      ])
    })
  })
})
