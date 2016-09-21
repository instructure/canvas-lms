module DataFixup::CreateCanvadocsSubmissionsRecords

  def self.run
    Shackles.activate(:slave) do
      %w(canvadocs crocodoc_documents).each do |table|
        association = table.singularize
        column = "#{association}_id"
        AttachmentAssociation
        .joins(attachment: association)
        .where(context_type: "Submission")
        .select("attachment_associations.context_id AS submission_id, #{table}.id AS #{column}")
        .find_in_batches do |chunk|
          canvadocs_submissions = chunk.map do |aa|
            {:submission_id => aa.submission_id,
             column         => aa[column]}
          end
          Shackles.activate(:master) do
            CanvadocsSubmission.bulk_insert canvadocs_submissions
          end
        end
      end
    end
  end

end
