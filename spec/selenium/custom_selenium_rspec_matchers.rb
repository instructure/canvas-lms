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

end
