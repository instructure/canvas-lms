module DataFixup::RemoveDuplicateCanvadocsSubmissions
  def self.run
    %w[crocodoc_document_id canvadoc_id].each do |column|
      duplicates = CanvadocsSubmission.
        select("#{column}, submission_id").
        group("#{column}, submission_id").
        having("count(*) > 1")

      duplicates.find_each do |dup|
        scope = CanvadocsSubmission.where(
          column => dup[column],
          submission_id: dup.submission_id
        )
        keeper = scope.first
        scope.where("id <> ?", keeper.id).delete_all
      end
    end
  end
end
