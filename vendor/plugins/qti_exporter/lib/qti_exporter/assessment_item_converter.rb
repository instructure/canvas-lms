module Qti
class AssessmentItemConverter
  include Canvas::XMLHelper
  DEFAULT_CORRECT_WEIGHT = 100
  DEFAULT_INCORRECT_WEIGHT = 0
  DEFAULT_POINTS_POSSIBLE = 1
  UNSUPPORTED_TYPES = ['File Upload', 'Hot Spot', 'Quiz Bowl', 'WCT_JumbledSentence', 'file_upload_question']

  attr_reader :base_dir, :identifier, :href, :interaction_type, :title, :question

  def initialize(opts)
    @log = Canvas::Migration::logger
    reset_local_ids
    @manifest_node = opts[:manifest_node]
    @migration_type = opts[:interaction_type]
    @doc = nil

    if @manifest_node
      @base_dir = opts[:base_dir]
      @identifier = @manifest_node['identifier']
      @href = File.join(@base_dir, @manifest_node['href'])
      if title = @manifest_node.at_css('title langstring')
        @title = title.text
      end
    else
      @qti_data = opts[:qti_data]
    end

    @question = {:answers=>[],
                 :correct_comments=>"",
                 :incorrect_comments=>"",
                 :points_possible=>AssessmentItemConverter::DEFAULT_POINTS_POSSIBLE,
                 :question_text=>""}
  end

  #This should be implemented in the children classes to do the type-specific parsing
  def parse_question_data
    @log.error "No question type used..."
    raise "No question type used when trying to parse a qti question"
  end

  def create_doc
    if @manifest_node
      @doc = Nokogiri::HTML(open(@href))
    else
      @doc = Nokogiri::HTML(@qti_data)
    end
  end

  def create_xml_doc
    if @manifest_node
      @doc = Nokogiri::XML(open(@href))
    else
      @doc = Nokogiri::XML(@qti_data)
    end
  end

  def create_instructure_question
    begin
      create_doc
      @question[:question_name] = @title || @doc.at_css('assessmentitem @title').text
      # The colons are replaced with dashes in the conversion from QTI 1.2
      @question[:migration_id] = @doc.at_css('assessmentitem @identifier').text.gsub(/:/, '-')
      if @doc.at_css('itembody').children.first.name == 'div' #because the selector 'itembody + div' doesn't work...
        @question[:question_text] = @doc.at_css('itembody div').inner_html
      elsif @doc.at_css('itembody p')
        @question[:question_text] = @doc.at_css('itembody p').inner_html
      elsif @doc.at_css('itembody')
        @question[:question_text] = @doc.at_css('itembody').inner_html
      end
      parse_instructure_metadata

      if @migration_type and UNSUPPORTED_TYPES.member?(@migration_type)
        @question[:question_type] = @migration_type
        @question[:unsupported] = true
      else
        self.parse_question_data
      end
    rescue => e
      message = "There was an error exporting an assessment question"
      @question[:qti_error] = "#{message} - #{e.to_s}"
      @question[:question_type] = "Error"
      @log.error "#{e.to_s}: #{e.backtrace}"
    end
    
    @question
  end
  
  def parse_instructure_metadata
    if bank = @doc.at_css('instructuremetadata instructurefield[name=question_bank] @value')
      @question[:question_bank_name] = bank.text
    end
    if bank = @doc.at_css('instructuremetadata instructurefield[name=question_bank_iden] @value')
      @question[:question_bank_id] = bank.text
    end
    if score = @doc.at_css('instructuremetadata instructurefield[name=max_score] @value')
      @question[:points_possible] = score.text.to_f
    end
    if type = @doc.at_css('instructuremetadata instructurefield[name=bb_question_type] @value')
      @migration_type = type.text
      case @migration_type
        when 'True/False'
          @question[:question_type] = 'true_false_question'
        when 'Short Response'
          @question[:question_type] = 'essay_question'
        when 'Fill in the Blank Plus'
          @question[:question_type] = 'fill_in_multiple_blanks_question'
        when 'WCT_FillInTheBlank'
          @question[:question_type] = 'fill_in_multiple_blanks_question'
          @question[:is_vista_fib] = true
        when 'Jumbled Sentence'
          @question[:question_type] = 'multiple_dropdowns_question'
        when 'Essay'
          @question[:question_type] = 'essay_question'
      end
    end
    if type = @doc.at_css('instructuremetadata instructurefield[name=question_type] @value')
      @migration_type = type.text
      case @migration_type
        when /matching/i
          @question[:question_type] = 'matching_question'
      end
    end
  end

  def unique_local_id
    @@ids ||= {}
    id = rand(10000)
    while @@ids[id]
      id = rand(10000)
    end
    @@ids[id] = true
    id
  end

  def reset_local_ids
    @@ids = {}
  end
  
  def get_feedback
    @doc.search('modalfeedback[outcomeidentifier=FEEDBACK]').each do |f|
      id = f['identifier']
      feedback = clear_html(f.text.strip.gsub(/\s+/, " "))
      if id =~ /general|all/i
        @question[:general_comments] = feedback
      elsif id =~ /wrong|incorrect/i
        @question[:incorrect_comments] = feedback
      elsif id =~ /correct/i
        if f.at_css('div.solution')
          @question[:example_solution] = feedback
        else
          @question[:correct_comments] = feedback
        end
      elsif id =~ /solution/i
        @question[:example_solution] = feedback
      end
    end
  end
  
  def clear_html(text)
    text.gsub(/<\/?[^>\n]*>/, "").gsub(/&#\d+;/) {|m| m[2..-1].to_i.chr rescue '' }.gsub(/&\w+;/, "").gsub(/(?:\\r\\n)+/, "\n")
  end

  def sanitize_html!(node)
    # root may not be an html element, so we just sanitize its children so we
    # don't blow away the whole thing
    node.children.each do |child|
      Sanitize.clean_node!(child, Sanitize::Config::RELAXED)
    end

    while true
      node.children.each do |child|
        break unless child.text? && child.text =~ /\A\s+\z/ || child.element? && child.name.downcase == 'br'
        child.remove
      end

      node.children.reverse.each do |child|
        break unless child.text? && child.text =~ /\A\s+\z/ || child.element? && child.name.downcase == 'br'
        child.remove
      end
      break unless node.children.size == 1 && node.child.element?
      node = node.child
    end
    node
  end

  def self.create_instructure_question(opts)
    q = nil
    manifest_node = opts[:manifest_node]

    if manifest_node
      if type = manifest_node.at_css('interactiontype')
        opts[:interaction_type] ||= type.text.downcase
      end
      if type = manifest_node.at_css('instructuremetadata instructurefield[name=bb_question_type] @value')
        opts[:custom_type] ||= type.text.downcase
      end
      if type = manifest_node.at_css('instructuremetadata instructurefield[name=question_type] @value')
        opts[:custom_type] ||= type.text.downcase
        if opts[:custom_type] == 'matching'
          opts[:custom_type] = 'respondus_matching'
        end
      end
    end

    unless opts[:interaction_type]
      guesser = QuestionTypeEducatedGuesser.new(opts)
      opts[:interaction_type], opts[:custom_type] = guesser.educatedly_guess_type
    end

    case opts[:interaction_type]
      when /choiceinteraction|multiple_choice_question|multiple_answers_question|true_false_question|stupid_likert_scale_question/i
        if opts[:custom_type] and opts[:custom_type] == "matching"
          q = AssociateInteraction.new(opts)
        elsif opts[:custom_type] and opts[:custom_type] == "respondus_matching"
          q = AssociateInteraction.new(opts)
        else
          q = ChoiceInteraction.new(opts)
        end
      when /associateinteraction|matching_question/i
        q = AssociateInteraction.new(opts)
      when /extendedtextinteraction|essay_question|short_answer_question/i
        if opts[:custom_type] and opts[:custom_type] == "calculated"
          q = CalculatedInteraction.new(opts)
        elsif opts[:custom_type] and opts[:custom_type] == "numeric"
          q = NumericInteraction.new(opts)
        else
          q = ExtendedTextInteraction.new(opts)
        end
      when /orderinteraction|ordering_question/i
        q = OrderInteraction.new(opts)
      when /fill_in_multiple_blanks_question/i
        q = FillInTheBlank.new(opts)
      when nil
        q = AssessmentItemConverter.new(opts)
      else
        Canvas::Migration::logger.warn "Unknown QTI question type: #{opts[:interaction_type]}"
        q = AssessmentItemConverter.new(opts)
    end

    q.create_instructure_question if q
  end

end
end
