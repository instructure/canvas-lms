define [
  'compiled/views/content_migrations/NavigationForTree'
  'jquery'
  'helpers/fakeENV'
  ], (NavigationForTree, $, fakeENV) ->

    module "Navigation: Click Tests",
      setup: ->
        $('#fixtures').html("<ul role='tree'>
          <li role='treeitem' id='42'>
            <div class='treeitem-heading'>Heading Text</div>
          </li>
        </ul>")

        @$tree = $('[role=tree]')
        @nft = new NavigationForTree(@$tree)

      teardown: ->
        $('#fixtures').html('')

    test "clicking treeitem heading selects that tree item", ->
      $heading = @$tree.find('.treeitem-heading')
      $treeitem = $heading.closest('[role=treeitem]')

      $heading.click()

      ok !!$treeitem.attr('aria-selected')
      equal @$tree.attr('aria-activedescendant'), $treeitem.attr('id')
