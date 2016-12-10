module GroupCategories

  class Params < Struct.new(:name, :group_limit)

    attr_reader :raw_params

    def initialize(args, opts={})
      super(args[:name], args[:group_limit])
      @boolean_translator = opts.fetch(:boolean_translator){ Canvas::Plugin }
      @raw_params = args
    end

    def self_signup
      return _self_signup if _self_signup
      return nil if !enable_self_signup
      return 'restricted' if restrict_self_signup
      'enabled'
    end

    def auto_leader
      return nil if !enable_auto_leader.nil? && !enable_auto_leader
      return _auto_leader unless enable_auto_leader
      return auto_leader_type if ['first', 'random'].include?(auto_leader_type)
      raise(ArgumentError, "Invalid AutoLeader Type #{auto_leader_type}")
    end

    def create_group_count
      return _create_group_count if self_signup
      return nil unless split_group_enabled?
      split_group_count
    end

    def assign_unassigned_members
      return false if self_signup
      split_group_enabled? && create_group_count && create_group_count > 0
    end

    def group_by_section
      value_to_boolean(raw_params[:group_by_section])
    end

    def assign_async
      value_to_boolean(raw_params[:assign_async])
    end

    private

    def value_to_boolean(value)
      @boolean_translator.value_to_boolean(value)
    end

    def split_group_enabled?
      raw_params[:split_groups] != '0'
    end

    def split_group_count
      if raw_params[:split_group_count]
        raw_params[:split_group_count].to_i
      else
        _create_group_count
      end
    end

    def _create_group_count
      raw_params[:create_group_count].to_i
    end

    def _self_signup
      raw_value = raw_params[:self_signup]
      return nil unless raw_value
      raw_value = raw_value.to_s.downcase
      %w(enabled restricted).include?(raw_value) ? raw_value : nil
    end

    def _auto_leader
      raw_value = raw_params[:auto_leader]
      return nil unless raw_value
      raw_value = raw_value.to_s.downcase
      %w(random first).include?(raw_value) ? raw_value : nil
    end

    def auto_leader_type
      raw_params[:auto_leader_type].downcase
    end

    def enable_self_signup
      value_to_boolean raw_params[:enable_self_signup]
    end

    def restrict_self_signup
      value_to_boolean raw_params[:restrict_self_signup]
    end

    def enable_auto_leader
      return nil if raw_params[:enable_auto_leader].nil?
      value_to_boolean raw_params[:enable_auto_leader]
    end

  end

end
