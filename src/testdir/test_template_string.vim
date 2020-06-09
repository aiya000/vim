" Test for template strings $'${x} ${y.z}' $"$var"

scriptencoding utf-8

func Test_template_string_basic()
  " Literals - (non string) literals will be applied by string()
  call assert_equal('I have 10', $'I have ${10}')
  call assert_equal('10!', $'${10}!')
  call assert_equal(string(function("function")), $'${function("function")}')
  call assert_equal(string([10, 20]), $'${[10, 20]}')
  call assert_equal(string({"x": 10}), $'${{"x": 10}}')
  call assert_equal(string(42.1), $'${42.1}')

  call assert_equal(string(v:false), $'${v:false}')
  call assert_equal(string(v:true), $'${v:true}')

  call assert_equal(string(v:null), $'${v:null}')
  call assert_equal(string(v:none), $'${v:none}')

  " string literals expanded directly without string()
  call assert_equal('I''m a vim', $'I''m a ${"vim"}')
  call assert_equal('You are a vim', $'You are a ${"vim"}')

  " Nested
  call assert_equal('x', $'${$'x'}')
  call assert_equal('10', $'${$'${10}'}')
  call assert_equal("x", $"${$"x"}")
  call assert_equal("10", $"${$"${10}"}")

  " Variables
  let x = 10
  call assert_equal('I have 10', $'I have ${x}')
  "" In Vim script, template string doesn't support the variable expansion by `$foo`
  let x = 10
  call assert_equal('$x', $'$x')

  " Environment variables
  call assert_equal($HOME, $'${$HOME}')
  call assert_equal($UNDEFINED_ENV_VAR, $'${$UNDEFINED_ENV_VAR}')

  " Another types (compound tests)
  if exists('*job_start')
    let x = job_start('ls', {})
    call assert_equal(string(x), $'${x}')
  endif

  if exists('*ch_open')
    let x = ch_open('localhost:25252')  " dummy
    call assert_equal(string(x), $'${x}')
  endif

  " Lambda
  let F = {x -> x}
  call assert_equal(string(F), $'${F}')

  " Partial
  call assert_equal(
    \ string(function("has_key", [{"x": 10}])),
    \ $'${function("has_key", [{"x": 10}])}'
  \ )

  " echo
  echo $'${10}'
  " let
  let _ = $'${10}'
endfunc

let s:count = [0, 0]

func s:increment_count0() abort
  let s:count[0] += 1
endfunc

func s:increment_count1() abort
  let s:count[1] += 1
endfunc

func s:throw_exception() abort
  throw 'exception'
endfunc

func Test_template_string_appendix()
  " Lambda scopes
  call assert_equal('10', call({ x -> $'${x}' }, [10]))

  " evaluate == 0
  if 0
    call assert_equal('10', $'${10}')
  endif

  " Catching exceptions in ${}
  try
    let _ = $'${s:throw_exception()}'
  catch
    call assert_exception('exception')
  endtry

  " Evaluate ${expressions} before an exception threw
  try
    let _ = $'${s:increment_count0()}, ${s:throw_exception()}, ${s:increment_count1()}'
  catch
    call assert_equal(s:count, [1, 0])
  endtry

  " Escaping of string
  call assert_equal("\\ \"", $"\\ \"")
  call assert_equal('''', $'''')

  " Quotes in quotes
  call assert_equal('', $'${''}')
  call assert_equal('x', $'${'x'}')
  call assert_equal('''', $'${''''}')
  call assert_equal("", $"${""}")
  call assert_equal("x", $"${"x"}")
  call assert_equal('a"b', $"${'a"b'}")
  call assert_equal("a'b", $"${"a'b"}")
  call assert_equal('a"b', $'${'a"b'}')
  call assert_equal("a'b", $'${"a'b"}')

  " Escaping '}'
  call assert_equal("}", $'${"}"}')
  call assert_equal('}', $'${'}'}')
  call assert_equal('}', $"${'}'}")
  call assert_equal("}", $"${"}"}")

  " Independent '${'
  call assert_equal('${', $'${'${'}')
  call assert_equal("${", $"${"${"}")
  call assert_equal('${', $'${"${"}')
  call assert_equal("${", $"${'${'}")

  " Multi byte strings
  call assert_equal('こんにちは Vim', $'こんにちは ${"Vim"}')
  call assert_equal('あ', $'${"あ"}')
endfunc

" These should be an exception, should not be a 'Segmentation fault'.
func Test_template_string_illformed()
  try
    let _ = $'missing closing quote
    call assert_report('Should throw an exception.')
  catch
    call assert_exception('E115:')
  endtry

  try
    let _ = $"missing closing double quote
    call assert_report('Should throw an exception.')
  catch
    call assert_exception('E115:')
  endtry

  try
    let _ = $'${10'
    call assert_report('Should throw an exception.')
  catch
    call assert_exception('E451:')
  endtry

  try
    let _ = $'---${}---'
    call assert_report('Should throw an exception.')
  catch
    call assert_exception('E452:')
  endtry

  try
    let _ = $'I have ${nothing}'
    call assert_report('Should throw an exception.')
  catch
    call assert_exception('E121:')
  endtry

  try
    " syntax error in a embedding
    let _ = $'missing closing of ${function(}'
    call assert_report('Should throw an exception.')
  catch
    call assert_exception('E116:')
  endtry
endfunc
