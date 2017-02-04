define ['compiled/util/deparam'], (deparam) ->

  params_str = 'a[0]=4&a[1]=5&a[2]=6&b[x][]=7&b[y]=8&b[z][0]=9&b[z][1]=0&b[z][2]=true&b[z][3]=false&b[z][4]=undefined&b[z][5]=&c=1'
  params_obj = { a:['4','5','6'], b:{x:['7'], y:'8', z:['9','0','true','false','undefined','']}, c:'1' }
  params_obj_coerce = { a:[4,5,6], b:{x:[7], y:8, z:[9,0,true,false,undefined,'']}, c:1 }

  QUnit.module "deparam"

  test "deparam", ->
    deepEqual deparam(), {}, "deparam()"
    deepEqual deparam(params_str), params_obj, "deparam( String )"
    deepEqual deparam(params_str, true), params_obj_coerce, "deparam( String, true )"
