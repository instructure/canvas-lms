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

class AddLastCommentAtOnSubmissions < ActiveRecord::Migration[5.0]
  tag :predeploy

  def up
    add_column :submissions, :last_comment_at, :datetime

    execute("
      CREATE FUNCTION #{connection.quote_table_name("submission_comment_after_save_set_last_comment_at__tr_fn")} () RETURNS trigger AS $$
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
      CREATE FUNCTION #{connection.quote_table_name("submission_comment_after_delete_set_last_comment_at__tr_fn")} () RETURNS trigger AS $$
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

    execute("
      CREATE TRIGGER submission_comment_after_insert_set_last_comment_at__tr
        AFTER INSERT ON #{SubmissionComment.quoted_table_name}
        FOR EACH ROW
        WHEN (NEW.draft <> 't' AND NEW.provisional_grade_id IS NULL)
        EXECUTE PROCEDURE #{connection.quote_table_name("submission_comment_after_save_set_last_comment_at__tr_fn")}()")

    execute("
      CREATE TRIGGER submission_comment_after_update_set_last_comment_at__tr
        AFTER UPDATE OF draft, provisional_grade_id ON #{SubmissionComment.quoted_table_name}
        FOR EACH ROW
        EXECUTE PROCEDURE #{connection.quote_table_name("submission_comment_after_save_set_last_comment_at__tr_fn")}()")

    execute("
      CREATE TRIGGER submission_comment_after_delete_set_last_comment_at__tr
        AFTER DELETE ON #{SubmissionComment.quoted_table_name}
        FOR EACH ROW
        WHEN (OLD.draft <> 't' AND OLD.provisional_grade_id IS NULL)
        EXECUTE PROCEDURE #{connection.quote_table_name("submission_comment_after_delete_set_last_comment_at__tr_fn")}()")
  end

  def down
    execute("DROP TRIGGER IF EXISTS submission_comment_after_insert_set_last_comment_at__tr ON #{SubmissionComment.quoted_table_name}")
    execute("DROP TRIGGER IF EXISTS submission_comment_after_update_set_last_comment_at__tr ON #{SubmissionComment.quoted_table_name}")
    execute("DROP TRIGGER IF EXISTS submission_comment_after_delete_set_last_comment_at__tr ON #{SubmissionComment.quoted_table_name}")
    execute("DROP FUNCTION IF EXISTS #{connection.quote_table_name("submission_comment_after_saves_set_last_comment_at__tr_fn")}()")
    execute("DROP FUNCTION IF EXISTS #{connection.quote_table_name("submission_comment_after_delete_set_last_comment_at__tr_fn")}()")

    remove_column :submissions, :last_comment_at
  end
end
