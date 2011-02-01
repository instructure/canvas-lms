require 'cgi'
module Qti
class CalculatedInteraction < AssessmentItemConverter
  def initialize(opts)
    super(opts)
    @question[:answers] = []
    @question[:variables] = []
    @question[:question_type] = 'calculated_question'
  end

  def parse_question_data
    @question[:imported_formula] = CGI.unescape(@doc.at_css('calculated formula').text)
    get_calculated_property('answer_tolerance')
    get_calculated_property('unit_points_percent')
    get_calculated_property('unit_value')
    get_calculated_property('unit_required', true)
    get_calculated_property('unit_case_sensitive', true)
    get_calculated_property('partial_credit_points_percent')
    get_calculated_property('partial_credit_tolerance')

    get_variables()
    get_answer_sets()
    get_feedback()
    @question
  end

  def get_calculated_property(prop_name, is_true_false=false)
    @question[:"#{prop_name}"] = @doc.at_css("calculated #{prop_name}").text if @doc.at_css("calculated #{prop_name}")
    if is_true_false and @question[:"#{prop_name}"]
      @question[:"#{prop_name}"] = @question[:"#{prop_name}"] == 'true' ? true : false
    end
  end

  def get_variables
    @doc.css('calculated vars var').each do |v|
      var = {}
      @question[:variables] << var
      var[:name] = v['name']
      var[:scale] = v['scale']
      var[:min] = v.at_css('min').text if v.at_css('min')
      var[:max] = v.at_css('max').text if v.at_css('max')
    end
  end

  def get_answer_sets
    @doc.css('calculated var_sets var_set').each do |vs|
      set = {:variables=>[], :id=>unique_local_id}
      @question[:answers] << set
      set[:migration_id] = vs['ident']
      set[:answer] = vs.at_css('answer').text if vs.at_css('answer')
      
      vs.css('var').each do |v|
        var = {}
        set[:variables] << var
        var[:name] = v['name']
        var[:value] = v.text
      end
    end
  end

end
end
