class BreakDownDetailedReportSnapshots < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.do_report_type(scope)
    detailed = scope.where(:account_id => nil).last
    return unless detailed
    detailed.data['detailed'].each do |(account_id, data)|
      new_detailed = detailed.clone
      new_detailed.account_id = account_id
      data['generated_at'] = detailed.data['generated_at']
      new_detailed.data = data
      new_detailed.save!
    end
  end

  def self.up
    do_report_type(ReportSnapshot.detailed)
    do_report_type(ReportSnapshot.progressive)
  end

  def self.down
  end
end
