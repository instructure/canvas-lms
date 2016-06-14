module Exporters
  class SubmissionExporter

    def self.export_user_submissions(user, base_folder, zipfile, files_in_zip)
      user.submissions.shard(user).each do |main_sub|
        base_path = File.join(*[base_folder, main_sub.context.name.presence, main_sub.assignment.name.presence].compact)

        main_sub.versions.each do |version|
          submission = version.model
          if submission.submission_type == "online_upload"
            # NOTE: not using #versioned_attachments or #attachments because
            # they do not include submissions for group assignments for anyone
            # but the original submitter of the group submission
            attachment_ids = submission.attachment_ids.try(:split, ",")
            attachments = attachment_ids.present? ? Attachment.where(id: attachment_ids) : []
            attachments.each do |attachment|
              # TODO handle missing attachments
              path = File.join(base_path, attachment.display_name)
              ExporterHelper.add_attachment_to_zip(attachment, zipfile, path, files_in_zip)
            end
          elsif submission.submission_type == "online_url" && submission.url
            path = File.join(base_path, "submission_link_#{version.number}.html")
            content = "<a href=\"#{submission.url}\">#{submission.url}</a>"
            zipfile.get_output_stream(path) {|f| f.puts content }
          elsif submission.submission_type == "online_text_entry" && submission.body
            path = File.join(base_path, "submission_text_#{version.number}.html")
            zipfile.get_output_stream(path) {|f| f.puts submission.body }
          end
        end
      end
    end
  end
end