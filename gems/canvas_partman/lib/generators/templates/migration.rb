class <%= migration_class_name %> < CanvasPartman::Migration
  self.master_table = '<%= master_table || "name_of_master_table" %>'

  # If the base class can not be infered from the master table name because, for
  # example, it is namespaced, you may explicitly specify it here:
  #
  # self.base_class = Quizzes::QuizSubmissionEvent

  def self.up
    with_each_partition do |partition|
      # add_column partition, :name, :string
    end
  end

  def self.down
    with_each_partition do |partition|
      # remove_column partition, :name
    end
  end
end
