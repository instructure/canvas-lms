module CustomSeleniumRspecMatchers

  class HasClass
    def initialize(class_name)
      @class_name = class_name
    end

    def matches?(element)
      @element = element
      !!@element.attribute('class').match(@class_name)
    end

    def failure_message
      "expected #{@element.inspect} to have class #{@class_name}, actual class names: #{@element.attribute('class')}"
    end

    def negative_failure_message
      "expected #{@element.inspect} to not have class #{@class_name}, actual class names: #{@element.attribute('class')}"
    end
  end

  def have_class(class_name)
    HasClass.new(class_name)
  end

  class IncludeText
    def initialize(text)
      @text = text
    end

    def matches?(element)
      @element = element
      if (@element.instance_of? String)
        @element.include?(@text)
      else
        @element.text.include?(@text)
      end
    end

    def failure_message
      "expected #{@element.inspect} text to include #{@text}, actual text was: #{@element.text}"
    end

    def negative_failure_message
      "expected #{@element.inspect} text to NOT include #{@text}, actual text was: #{@element.text}"
    end
  end

  def include_text(text)
    IncludeText.new(text)
  end
end
