class SisPseudonym
  def self.for(user, context, include_trusted = false)
    self.new(user, context, include_trusted).pseudonym
  end

  attr_reader :user, :context, :include_trusted

  def initialize(user, context, include_trusted)
    @user = user
    @context = context
    @include_trusted = include_trusted
  end

  def pseudonym
    result = find_in_home_account || find_in_other_accounts
    if result
      result.account = root_account if result.account_id == root_account.id
    end
    result
  end

  private
  def find_in_other_accounts
    return nil unless include_trusted
    Shard.partition_by_shard(root_account.trusted_account_ids) do |trusted_ids|
      result = find_in_trusted_accounts(trusted_ids)
      return result if result
    end
    nil
  end

  def find_in_trusted_accounts(account_ids)
    if use_loaded_collection?(Shard.current)
      pick_user_pseudonym(account_ids)
    else
      return nil unless user.associated_shards.include?(Shard.current)
      pick_pseudonym(account_ids)
    end
  end

  def find_in_home_account
    if use_loaded_collection?(root_account.shard)
      pick_user_pseudonym([root_account.id])
    else
      root_account.shard.activate do
        pick_pseudonym([root_account.id])
      end
    end
  end

  def use_loaded_collection?(shard)
    user.pseudonyms.loaded? && user.shard == shard
  end

  def root_account
    @root_account ||= begin
      account = context.root_account
      raise "could not resolve root account" unless account.is_a?(Account)
      account
     end
  end

  def pick_pseudonym(account_ids)
    Pseudonym.where(account_id: account_ids).active.order(:unique_id).
      where("sis_user_id IS NOT NULL AND user_id=?", user).first
  end

  def pick_user_pseudonym(account_ids)
    user.active_pseudonyms.order(:unique_id).detect do |p|
      p.sis_user_id && account_ids.include?(p.account_id)
    end
  end
end
