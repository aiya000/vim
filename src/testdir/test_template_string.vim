" Test for template strings $'${x} ${y.z}' $"$var"

scriptencoding utf-8

func Test_template_string_basic()
  " Literals - (non string) literals will be applied by string()
  call assert_equal('I have 10', $'I have ${10}')
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

  " Variables
  let x = 10
  call assert_equal('I have 10', $'I have ${x}')
  "" Only variables can be ommt "{}"
  call assert_equal('I have 10', $'I have $x')
  call assert_equal('10 and me', $'$x and me')
  let x20 = 20
  call assert_equal('20', $'$x20')
  let Fo_O0O = 30
  call assert_equal('30', $'$Fo_O0O')

  " Another types (compound tests)
  if exists('*job_start')
    let x = job_start('ls', {})
    call assert_equal(string(x), $'${x}')  " About the variable expansion is belo, $'${x}'w
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
  let x = $'${10}'
endfunc

func Test_template_string_appendix()
  " Escape '$'
  call assert_equal('${10}', $'$${10}')

  " Escape '}'
  call assert_equal("}", $'${"}"}')

  " Independent '$'
  call assert_equal('$', $'$$')

  " Multi byte string
  call assert_equal('こんにちは Vim', $'こんにちは ${"Vim"}')

  " Double quoted
  call assert_equal("10 \\ \"", $"${10} \\ \"")
endfunc

" These should be an exception, should not be a 'Segmentation fault'.
func Test_template_string_illformed()
  try
    let _ = $'missing closing quote
    call assert_report('Should throw an exception.')
  catch /^Vim(let):E115:/
    " Good
  endtry

  try
    let _ = $"missing closing double quote
    call assert_report('Should throw an exception.')
  catch /^Vim(let):E115:/
    " Good
  endtry

  try
    let _ = $'$10'
    call assert_report('Should throw an exception.')
  catch /^Vim(let):E1000:/
    " Good
  endtry

  try
    let _ = $'${10'
    call assert_report('Should throw an exception.')
  catch /^Vim(let):E1000:/
    " Good
  endtry

  try
    let _ = $'---${}---'
    call assert_report('Should throw an exception.')
  catch /^Vim(let):E1000:/
    " Good
  endtry

  try
    let _ = $'I have ${nothing}'
    call assert_report('Should throw an exception.')
  catch /^Vim(let):E121:/
    " Good
  endtry

  try
    " syntax error in a embedding
    let _ = $'missing closing of ${function(}'
    call assert_report('Should throw an exception.')
  catch /^Vim(let):E119:/
    " Good
  endtry
endfunc
