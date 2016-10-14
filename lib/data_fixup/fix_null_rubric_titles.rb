module DataFixup
  module FixNullRubricTitles
    def self.run
      Rubric.find_ids_in_ranges(:batch_size => 10_000) do |min_id, max_id|
        Rubric.where(:id => min_id..max_id).where(:title => nil).each do |rubric|
          rubric.populate_rubric_title
          rubric.save
        end
      end
    end
  end
end
