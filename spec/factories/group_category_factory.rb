module Factories
  def group_category(opts = {})
    context = opts[:context] || @course
    @group_category = context.group_categories.create!(name: opts[:name] || 'foo')
  end
end
