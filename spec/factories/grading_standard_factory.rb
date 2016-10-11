module Factories
  def grading_standard_for(context, opts={})
    @standard = context.grading_standards.create!(
      :title => opts[:title] || "My Grading Standard",
      :standard_data => {
        "scheme_0" => {:name => "A", :value => "0.9"},
        "scheme_1" => {:name => "B", :value => "0.8"},
        "scheme_2" => {:name => "C", :value => "0.7"}
      })
  end
end
