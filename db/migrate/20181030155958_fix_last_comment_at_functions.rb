#
# Copyright (C) 2018 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#
class FixLastCommentAtFunctions < ActiveRecord::Migration[5.1]
  tag :predeploy

  def up
    execute("
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("submission_comment_after_save_set_last_comment_at__tr_fn")} () RETURNS trigger AS $$
      BEGIN
        UPDATE submissions
        SET last_comment_at = (
           SELECT MAX(submission_comments.created_at) FROM submission_comments
            WHERE submission_comments.submission_id=submissions.id AND
            submission_comments.author_id <> submissions.user_id AND
            submission_comments.draft <> 't' AND
            submission_comments.provisional_grade_id IS NULL
        ) WHERE id = NEW.submission_id;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;")

    execute("
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("submission_comment_after_delete_set_last_comment_at__tr_fn")} () RETURNS trigger AS $$
      BEGIN
        UPDATE submissions
        SET last_comment_at = (
           SELECT MAX(submission_comments.created_at) FROM submission_comments
            WHERE submission_comments.submission_id=submissions.id AND
            submission_comments.author_id <> submissions.user_id AND
            submission_comments.draft <> 't' AND
            submission_comments.provisional_grade_id IS NULL
        ) WHERE id = OLD.submission_id;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;")

    set_search_path("submission_comment_after_save_set_last_comment_at__tr_fn", "()")
    set_search_path("submission_comment_after_delete_set_last_comment_at__tr_fn", "()")
  end

  def down
    execute("
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("submission_comment_after_save_set_last_comment_at__tr_fn")} () RETURNS trigger AS $$
      BEGIN
        UPDATE #{Submission.quoted_table_name}
        SET last_comment_at = (
           SELECT MAX(submission_comments.created_at) FROM #{SubmissionComment.quoted_table_name}
            WHERE submission_comments.submission_id=submissions.id AND
            submission_comments.author_id <> submissions.user_id AND
            submission_comments.draft <> 't' AND
            submission_comments.provisional_grade_id IS NULL
        ) WHERE id = NEW.submission_id;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;")

    execute("
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("submission_comment_after_delete_set_last_comment_at__tr_fn")} () RETURNS trigger AS $$
      BEGIN
        UPDATE #{Submission.quoted_table_name}
        SET last_comment_at = (
           SELECT MAX(submission_comments.created_at) FROM #{SubmissionComment.quoted_table_name}
            WHERE submission_comments.submission_id=submissions.id AND
            submission_comments.author_id <> submissions.user_id AND
            submission_comments.draft <> 't' AND
            submission_comments.provisional_grade_id IS NULL
        ) WHERE id = OLD.submission_id;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;")

    set_search_path("submission_comment_after_save_set_last_comment_at__tr_fn", "()", "DEFAULT")
    set_search_path("submission_comment_after_delete_set_last_comment_at__tr_fn", "()", "DEFAULT")
  end
end
