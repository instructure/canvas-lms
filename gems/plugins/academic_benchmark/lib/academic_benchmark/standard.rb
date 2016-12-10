module AcademicBenchmark

class Standard
  def initialize(data, parent=nil)
    @data = data
    @parent = parent
    @children = []

    if has_items?
      items.each do |itm|
        Standard.new(itm, self)
      end
    end

    # ignore course types and leaves that don't have a num
    if num || @children.any?
      @parent.add_child(self) if parent
    end
  end

  def build_outcomes(ratings={})
    hash = {:migration_id => guid, :vendor_guid => guid, :low_grade => low_grade, :high_grade => high_grade, :is_global_standard => true}
    hash[:description] = description
    if is_leaf?
      # create outcome
      hash[:type] = 'learning_outcome'
      hash[:title] = build_num_title
      set_default_ratings(hash, ratings)
    else
      #create outcome group
      hash[:type] = 'learning_outcome_group'
      hash[:title] = build_title
      hash[:outcomes] = @children.map {|chld| chld.build_outcomes(ratings)}
    end

    hash
  end

  def add_child(itm)
    @children << itm
  end

  def has_items?
    !!(items && items.any?)
  end

  def items
    @data["itm"]
  end

  def guid
    @data["guid"]
  end

  def type
    @data["type"]
  end

  def title
    @data["title"]
  end

  # standards don't have titles so they are built from parent standards/groups
  # it is generated like this:
  # if I have a num, use it and all parent nums on standards
  # if I don't have a num, use my description (potentially truncated at 50)
  def build_num_title
    # when traversing AB data, "standards" will always be deeper in the data
    # hierarchy, so this code will always hit the else before a @parent is nil
    if @parent.is_standard?
      base = @parent.build_num_title
      if base && num
        num.include?(base) ? num : base + '.' + num
      elsif base
        base
      else
        num
      end
    else
      num
    end
  end

  def build_title
    if num
      build_num_title + " - " + (title || cropped_description)
    else
      title || cropped_description
    end
  end

  def num
    get_meta_field("num")
  end

  def description
    get_meta_field("descr")
  end

  def cropped_description
    # get the first 50 chars of description in a utf-8 friendly way
    description && description[/.{0,50}/u]
  end

  def name
    get_meta_field("name")
  end

  def high_grade
    if @data["meta"] && @data["meta"]["name"]
      @data["meta"]["hi"]
    else
      @parent && @parent.high_grade
    end
  end

  def low_grade
    if @data["meta"] && @data["meta"]["name"]
      @data["meta"]["lo"]
    else
      @parent && @parent.low_grade
    end
  end

  def get_meta_field(field)
    @data["meta"] && @data["meta"][field] && @data["meta"][field]["content"]
  end

  def is_standard?
    type == 'standard'
  end

  # it's only a leaf if it's a standard and has no children, or no children with a 'num'
  # having a num is to ignore extra description nodes that we want to ignore
  def is_leaf?
    num && @children.empty?
  end

  def set_default_ratings(hash, overrides={})
    hash[:ratings] = [{:description => "Exceeds Expectations", :points => 5},
                      {:description => "Meets Expectations", :points => 3},
                      {:description => "Does Not Meet Expectations", :points => 0}]
    hash[:mastery_points] = 3
    hash[:points_possible] = 5
    hash.merge!(overrides)
  end
end
end
