require 'minitest/autorun'
require 'funfig/ini_parser'

describe Funfig::IniParser do
  let(:parser){ Funfig::IniParser.new }

  def parse(string)
    parser.parse(string)
  end

  it "should parse empty string as empty hash" do
    parse('').must_equal({})
  end

  it "should parse simple value" do
    parse('a=').must_equal(               {'a'=>nil}  )
    parse("a= \t ").must_equal(           {'a'=>nil}  )
    parse("a= \t # comment").must_equal(  {'a'=>nil}  )
    parse('a=1').must_equal(              {'a'=>1}    )
    parse('a=  1  ').must_equal(          {'a'=>1}    )
    parse('a=  1  # comment').must_equal( {'a'=>1}    )
    parse('a=1.0').must_equal(            {'a'=>1.0}  )
    parse('a=  1.0  ').must_equal(        {'a'=>1.0}  )
    parse('a= 1.0 # comment').must_equal( {'a'=>1.0}  )
    parse('a= "b"').must_equal(           {'a'=>'b'} )
    parse('a= a"b"').must_equal(          {'a'=>'ab'} )
    parse('a= a "b"').must_equal(         {'a'=>'a b'} )
    parse('a= a "\\nb"').must_equal(      {'a'=>"a \nb"} )
    parse("a= a '\\nb'").must_equal(      {'a'=>"a \\nb"} )
    parse("a= a \t '\nb'").must_equal(       {'a'=>"a \nb"} )
    parse("a= a \"sdf\nb\"").must_equal(  {'a'=>"a sdf\nb"} )
  end

  it 'should parse boolean value' do
    parse('a= true').must_equal(  {'a'=>true}  )
    parse('a= True').must_equal(  {'a'=>true}  )
    parse('a= TRUE').must_equal(  {'a'=>true}  )
    parse('a= Yes ').must_equal(  {'a'=>true}  )
    parse('a= yes ').must_equal(  {'a'=>true}  )
    parse('a= false').must_equal( {'a'=>false} )
    parse('a= False').must_equal( {'a'=>false} )
    parse('a= FALSE').must_equal( {'a'=>false} )
    parse('a= No   ').must_equal( {'a'=>false} )
    parse('a= no   ').must_equal( {'a'=>false} )
  end

  it "should parse couple of values" do
    parse("a = 1\n b = 3").must_equal(    {'a'=>1, 'b'=>3})
    parse("a=1 #comment\n  ; other comment;\n b = 3").must_equal(
      {'a'=>1, 'b'=>3}
    )
  end

  it "should parse nested value" do
    parse("a.x = 1").must_equal( {'a'=>{'x'=>1}} )
    parse("a.x.z = 1").must_equal( {'a'=>{'x'=>{'z'=>1}}} )
  end

  it "should consider section" do
    parse("[sec]\na.x = 1").must_equal( {'sec'=>{'a'=>{'x'=>1}}} )
    parse("[sec.a]\nx = 1").must_equal( {'sec'=>{'a'=>{'x'=>1}}} )
  end

  it "should consider 'global' section as empty" do
    parse("[global]\na.x = 1").must_equal( {'a'=>{'x'=>1}} )
    parse("[global.a]\nx = 1").must_equal( {'a'=>{'x'=>1}} )
  end

  it "should parse multiline value" do
    val = parse <<-EOF
      [section]
      my-value = <<EOV
                 hello
                   world!
               (and others)
               EOV
    EOF
    val.must_equal({'section'=>{
      'my-value'=>"  hello\n    world!\n(and others)"
    }})
    val = parse <<-EOF
      [section]
      first_value = No
      my-value = <<EOV
                 hello
                   world!
               EOV
      other_value = false
    EOF
    val.must_equal({'section'=>{
      'first_value' => false,
      'my-value' => "  hello\n    world!",
      'other_value' => false
    }})
  end

  it "should parse oneline yaml" do
    parse('a = YAML "hi"').must_equal('a'=>'hi')
    parse('a = YAML hi').must_equal('a'=>'hi')
    parse('a = YAML hi: ho').must_equal('a'=>{'hi'=>'ho'})
    parse('a = YAML {hi: ho}').must_equal('a'=>{'hi'=>'ho'})
    parse('a = YAML [hi, ho]').must_equal('a'=>['hi', 'ho'])
    parse('a = YAML 2011-01-01').must_equal('a'=>Date.new(2011, 1, 1))
  end

  it "should parse multiline yaml" do
    val = parse <<-EOF
      a = YAML <<EOV
        - b : 4.0
          c : Yes
        - x : {1 : 2012-06-09}
      EOV
    EOF
    val.must_equal({
      'a' => [
          { 'b' => 4.0, 'c' => true },
          { 'x' => {1 => Date.new(2012, 6, 9)} }
        ]
    })
  end
end
