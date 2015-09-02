module AcademicBenchmark

class CliTools

  def self.delete_imported_outcomes(parent_group_title, no_prompt: false, override_shard_restriction: false)
    unless no_prompt
      return unless warn_shard
      return unless warn_deleting(parent_group_title)
    end
    Rails.logger.warn("AcademicBenchmark::CliTools - deleting outcomes under #{parent_group_title}")
    delete_with_children(LearningOutcomeGroup.where(title: parent_group_title).first)
    Rails.logger.warn("AcademicBenchmark::CliTools - finished deleting outcomes under #{parent_group_title}")
  end

  # Make sure this account is on its own shard
  # If it is not, then we could affect other schools
  def self.own_shard
    Account.root_accounts.count <= 1
  end

  private
  def self.warn_deleting(title)
    print "WARNING:  You are about to delete all imported outcomes under #{title} for this shard.  Proceed?  (Y/N): "
    return false unless STDIN.gets.chomp.downcase == "y"
    return true
  end

  private
  def self.warn_shard
    unless own_shard
      print "WARNING:  This shard has more than one account on it!  This means you will affect multiple customers with your actions.  Proceed?  (Y/N): "
      return false unless STDIN.gets.chomp.downcase == "y"
    end
    true
  end

  private
  def self.delete_with_children(item, no_prompt: false, override_shard_restriction: false)
    expected_types = [LearningOutcomeGroup, ContentTag]
    if !no_prompt && !expected_types.include?(item.class)
      puts "Expected #{expected_types.map{|t| t.to_s}.join(" or ") } but received a '#{item.class.to_s}'"
      return
    end

    if item.is_a?(LearningOutcomeGroup)
      # These two queries can be combined when we hit rails 4
      # and have multi-column pluck
      child_outcome_links = ContentTag.where(
        tag_type: 'learning_outcome_association',
        content_type: 'LearningOutcome',
        context_id: item.id
      ).pluck(:id)
      child_outcome_ids = ContentTag.where(
        tag_type: 'learning_outcome_association',
        content_type: 'LearningOutcome',
        context_id: item.id
      ).pluck(:content_id)

      # delete all links to our children
      ContentTag.destroy(child_outcome_links)
      # delete all of our children
      LearningOutcome.destroy(child_outcome_ids)

      item.child_outcome_groups.each do |child|
        delete_with_children(child)
      end
      item.destroy!
    else
      item.destroy!
    end
  end
end # class CliTools

end # module AcademicBenchmark
