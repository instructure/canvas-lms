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

import {isPostable, isHideable, extractSimilarityInfo, similarityIcon} from '../SubmissionHelper'

describe('SubmissionHelper', () => {
  let submission
  let snakeCasedSubmission

  beforeEach(() => {
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

  describe('isPostable', () => {
    describe('when submission is excused', () => {
      beforeEach(() => {
        submission.excused = true
      })

      it('returns true', () => {
        expect(isPostable(submission)).toBe(true)
      })
    })

    describe('when submission is not excused', () => {
      it('is true when submission workflow state is graded and score is present', () => {
        submission.score = 1
        submission.workflowState = 'graded'
        expect(isPostable(submission)).toBe(true)
      })

      it('is true when submission hasPostableComments is true', () => {
        submission.hasPostableComments = true
        expect(isPostable(submission)).toBe(true)
      })

      it('is false when workflow state is not graded and hasPostableComments is not true', () => {
        submission.score = 1
        expect(isPostable(submission)).toBe(false)
      })

      it('is false when score is not present and hasPostableComments is not true', () => {
        submission.workflowState = 'graded'
        expect(isPostable(submission)).toBe(false)
      })
    })

    it('handles snake_cased submission keys', () => {
      snakeCasedSubmission.score = 1
      snakeCasedSubmission.workflow_state = 'graded'
      expect(isPostable(snakeCasedSubmission)).toBe(true)
    })
  })

  describe('isHideable', () => {
    it('is true when submission is posted', () => {
      submission.postedAt = '2020-10-20T15:24:26Z'
      expect(isHideable(submission)).toBe(true)
    })

    it('is false when submission is not posted', () => {
      expect(isHideable(submission)).toBe(false)
    })

    it('handles snake_cased submission keys', () => {
      snakeCasedSubmission.posted_at = '2020-10-20T15:24:26Z'
      expect(isHideable(snakeCasedSubmission)).toBe(true)
    })
  })

  describe('extractSimilarityInfo', () => {
    describe('"type" return value', () => {
      it('returns "originality_report" if the submission has has_originality_report set to true', () => {
        const originalityReportSubmission = {
          has_originality_report: true,
          id: '1001',
          submission_type: 'online_text_entry',
          turnitinData: {
            submission_1001: {state: 'scored', similarity_score: 50.0},
          },
        }

        expect(extractSimilarityInfo(originalityReportSubmission).type).toBe('originality_report')
      })

      it('returns "turnitin" if the submission has turnitinData', () => {
        const turnitinSubmission = {
          id: '1001',
          submission_type: 'online_text_entry',
          turnitin_data: {
            submission_1001: {state: 'scored', similarity_score: 50.0},
          },
        }
        expect(extractSimilarityInfo(turnitinSubmission).type).toBe('turnitin')
      })

      it('returns "vericite" if the submission has vericite_data and the provider is "vericite"', () => {
        const vericiteSubmission = {
          id: '1001',
          submission_type: 'online_text_entry',
          vericite_data: {
            provider: 'vericite',
            submission_1001: {state: 'scored', similarity_score: 50.0},
          },
        }
        expect(extractSimilarityInfo(vericiteSubmission).type).toBe('vericite')
      })
    })

    describe('"entries" return value', () => {
      describe('for a submission that accepts online attachments', () => {
        let submissionWithAttachments
        let submissionWithNestedAttachment

        beforeEach(() => {
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

        it('returns an item for each attachment with plagiarism data', () => {
          expect(extractSimilarityInfo(submissionWithAttachments).entries.length).toBe(4)
        })

        it('sorts entries by status', () => {
          const entries = extractSimilarityInfo(submissionWithAttachments).entries
          const orderedStatuses = entries.map(entry => entry.data.status)
          expect(orderedStatuses).toEqual(['error', 'pending', 'scored', 'scored'])
        })

        it('sorts scored entries by decreasing similarity score', () => {
          const entries = extractSimilarityInfo(submissionWithAttachments).entries
          const scoredEntries = entries.filter(entry => entry.data.status === 'scored')
          expect(scoredEntries.map(entry => entry.data.similarity_score)).toEqual([75, 25])
        })

        it('sets the "id" field for each entry to the ID of the attachment for that entry', () => {
          const entries = extractSimilarityInfo(submissionWithAttachments).entries
          expect(entries.map(entry => entry.id)).toEqual([
            'attachment_2004',
            'attachment_2003',
            'attachment_2002',
            'attachment_2001',
          ])
        })

        it('uses data from the "attachment" field nested inside the attachment if present', () => {
          const entry = extractSimilarityInfo(submissionWithNestedAttachment).entries[0]
          expect(entry.id).toBe('attachment_3001')
        })
      })

      describe('for a text entry submission', () => {
        let unversionedSubmission
        let versionedSubmission
        let versionKey

        beforeEach(() => {
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

        it('returns plagiarism data for the current version of the submission if it exists', () => {
          const entry = extractSimilarityInfo(versionedSubmission).entries[0]
          expect(entry.data).toEqual({status: 'scored', similarity_score: 50.0})
        })

        it('returns an "id" field corresponding to the current version of the submission if it exists', () => {
          const entry = extractSimilarityInfo(versionedSubmission).entries[0]
          expect(entry.id).toBe(versionKey)
        })

        it('returns at most one plagiarism entry even if data exists for multiple versions', () => {
          expect(extractSimilarityInfo(versionedSubmission).entries.length).toBe(1)
        })

        it('returns plagiarism data for the base submission if no version-specific data exists', () => {
          const entry = extractSimilarityInfo(unversionedSubmission).entries[0]
          expect(entry.data).toEqual({status: 'error'})
        })

        it('returns an "id" field corresponding to the base submission if no version-specific data exists', () => {
          const entry = extractSimilarityInfo(unversionedSubmission).entries[0]
          expect(entry.id).toBe('submission_1001')
        })
      })
    })

    it('returns null if the submission has no turnitinData or vericiteData', () => {
      const submissionWithNoPlagiarismInfo = {
        id: '1001',
      }
      expect(extractSimilarityInfo(submissionWithNoPlagiarismInfo)).toBe(null)
    })

    it('returns null if the submission has no plagiarism data matching known attachments', () => {
      const submissionWithImmaterialPlagiarismInfo = {
        attachments: [{id: '2001'}],
        id: '1001',
        submission_type: 'online_upload',
        turnitin_data: {
          attachment_9999: {status: 'error'},
        },
      }
      expect(extractSimilarityInfo(submissionWithImmaterialPlagiarismInfo)).toBe(null)
    })

    it('returns null for a versioned text submission with only plagiarism data for older versions', () => {
      const otherVersionKey = 'submission_1001_1995-10-01T11:22:00Z'
      const submissionWithOldVersionInfo = {
        id: '1001',
        submission_type: 'online_text_entry',
        submitted_at: '01 October 1997 11:22 UTC',
        turnitinData: {},
      }
      submissionWithOldVersionInfo.turnitinData[otherVersionKey] = {status: 'error'}
      expect(extractSimilarityInfo(submissionWithOldVersionInfo)).toBe(null)
    })

    it('returns null if the submission is not an upload or text entry submission', () => {
      const submissionWithNoSubmissions = {
        id: '1001',
        submission_type: 'on_paper',
        turnitin_data: {
          submission_1001: {status: 'error'},
        },
      }
      expect(extractSimilarityInfo(submissionWithNoSubmissions)).toBe(null)
    })
  })

  describe('similarityIcon', () => {
    const domParser = new DOMParser()

    const icon = iconString =>
      domParser.parseFromString(similarityIcon(iconString), 'text/xml').documentElement

    const iconClasses = iconString => [...icon(iconString).classList]

    it('returns an <i> element', () => {
      expect(icon({status: 'scored', similarity_score: 50}).nodeName).toBe('i')
    })

    it('returns a warning icon if the passed item has an "error" status', () => {
      expect(iconClasses({status: 'error'})).toEqual(['icon-warning'])
    })

    it('returns a clock icon if the passed item has an "pending" status', () => {
      expect(iconClasses({status: 'pending'})).toEqual(['icon-clock'])
    })

    it('returns an empty-but-solid icon if the passed item is scored above 60', () => {
      expect(iconClasses({status: 'scored', similarity_score: 80})).toEqual([
        'icon-empty',
        'icon-Solid',
      ])
    })

    it('returns a solid half-oval icon if the passed item is scored betwen 20 and 60', () => {
      expect(iconClasses({status: 'scored', similarity_score: 40})).toEqual([
        'icon-oval-half',
        'icon-Solid',
      ])
    })

    it('returns a solid and certified icon if the passed item is scored up to 20', () => {
      expect(iconClasses({status: 'scored', similarity_score: 20})).toEqual([
        'icon-certified',
        'icon-Solid',
      ])
    })
  })
})
