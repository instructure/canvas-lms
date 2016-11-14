module Gradebook
  class MultipleGradingPeriods
    include SeleniumDriverSetup
    include OtherHelperMethods
    include CustomSeleniumActions
    include CustomAlertActions
    include CustomPageLoaders
    include CustomScreenActions
    include CustomValidators
    include CustomWaitMethods
    include CustomDateHelpers
    include LoginAndSessionMethods
    include SeleniumErrorRecovery

    private
      def gp_dropdown() f(".grading-period-select-button") end

      def gp_menu_list() ff("#grading-period-to-show-menu li") end

      def grade_input(cell) f(".grade", cell) end

      def grading_cell(x=0, y=0)
        cell = f(".container_1")
        cell = f(".slick-row:nth-child(#{y+1})", cell)
        f(".slick-cell:nth-child(#{x+1})", cell)
      end

    public
      def visit_gradebook(course)
        get "/courses/#{course.id}/gradebook2"
      end

      def select_grading_period(grading_period_id)
        gp_dropdown.click
        period = gp_menu_list.find do |item|
          f('label', item).attribute("for") == "period_option_#{grading_period_id}"
        end
        period.click
      end

      def enter_grade(grade, x_coordinate, y_coordinate)
        cell = grading_cell(x_coordinate, y_coordinate)
        cell.click
        set_value(grade_input(cell), grade)
        grade_input(cell).send_keys(:return)
      end

      def cell_graded?(grade, x_coordinate, y_coordinate)
        cell = grading_cell(x_coordinate, y_coordinate)
        if (cell.text == grade)
          return true
        else
          return false
        end
      end
  end
end