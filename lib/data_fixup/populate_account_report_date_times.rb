module DataFixup::PopulateAccountReportDateTimes

  def self.run
    AccountReport.find_in_batches do |batch|
      AccountReport.where(id: batch).update_all("start_at = created_at, end_at = updated_at")
    end
  end

end
