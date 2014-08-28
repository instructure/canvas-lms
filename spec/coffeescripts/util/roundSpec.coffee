require ['compiled/util/round'], (round) ->

  module "round"

  x = 1234.56789

  test "round", ->
    ok round(x, 6) == x
    ok round(x, 5) == x
    ok round(x, 4) == 1234.5679
    ok round(x, 3) == 1234.568
    ok round(x, 2) == 1234.57
    ok round(x, 1) == 1234.6
    ok round(x, 0) == 1235

  test "round without a digits argument rounds to 0", ->
    ok round(x) == 1235

  test "round.DEFAULT is 2", ->
    ok round.DEFAULT == 2

  test "round will convert non-numbers to a Number and round it", ->
    equal round("#{x}"), 1235
