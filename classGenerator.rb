#!/usr/bin/env ruby
# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    classGenerator.rb                                  :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: niccheva <niccheva@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2015/11/20 15:29:59 by niccheva          #+#    #+#              #
#    Updated: 2015/11/23 17:46:21 by niccheva         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NL = "\n"
TAB = "\t"

BLANK_COMMENT_LINE = "/*#{" " * 76}*/"
COMMENT_LINE = "/* #{"*" * 74} */"

def generate_comments(name)
  comment = COMMENT_LINE + NL
  comment += BLANK_COMMENT_LINE + NL
  spaces = 76 - name.length
  end_spaces = spaces.odd? ? (spaces / 2 + 1) : spaces / 2
  comment += "/*#{" " * (spaces / 2)}#{name}#{" " * end_spaces}*/" + NL
  comment += BLANK_COMMENT_LINE + NL
  comment += COMMENT_LINE + NL
end

CONSTRUCTORS_COMMENT = generate_comments "Constructors"
DESTRUCTORS_COMMENT = generate_comments "Destructors"
EXCEPTIONS_COMMENT = generate_comments "Exceptions"
GETTERS_COMMENT = generate_comments "Getters"
MEMBER_FUNCTIONS_COMMENT = generate_comments "Member Functions"
NON_MEMBER_FUNCTIONS_COMMENT = generate_comments "Non Member Functions"
NON_MEMBER_ATTRIBUTES_COMMENT = generate_comments "Non Member Attributes"
OPERATOR_OVERLOADS_COMMENT = generate_comments "Operator Overloads"
SETTERS_COMMENT = generate_comments "Setters"
TEMPLATE_DECLARATIONS_COMMENT = generate_comments "Template Declarations"

USAGE = "Usage: class_name [-public \"type/param_name\"...]
                  [-private \"type/param_name\"...]
                  [-protected \"type/param_name\"...]
                  [-inherit class_name...] (soon)
                  [-s [param_name...]]
                  [-g [param_name...]]
                  [-interface \"type/method_name(type param_name...)\"...] (soon)
                  [-abstract \"type/method_name(type param_name...)\"...] (soon)
                  [-template]
                  [-namespace \"namespace(s*)\" (*only on c++1z)]
                  [-member \"type/method_name(type param_name...)\"...] (soon)
                  [-exception name...] (soon)"

KEYWORDS = ["-public", "-protected", "-private", "-inherit", "-s", "-g", "-interface", "-abstract", "-template", "-member", "-namespace", "-exception"]

TEMPLATE = "template< typename T >" + NL

class Var

  attr_reader :type, :name, :is_const

  def initialize(var)
    ary = var.split "/"
    abort USAGE if ary == nil or ary.length != 2
    @type = ary.first
    @name = ary.last
    @is_ref = @type.include? "&"
    @is_pointer = @type.include? "*"
    @is_function = @name.include? "("
    @is_const = @type.include? "const"
    @type.slice! "const" if @is_const
    @type.delete! "*" if @is_pointer
    @type.delete! "&" if @is_ref
    @type.strip!
  end

  def pointer_or_ref
    return "*" if @is_pointer == true
    return "&" if @is_ref == true
    ""
  end

  def const
    return "const" if @is_const == true
    TAB
  end

end

class Array

  def longest_type
    self.sort_by! { |x| x.type.length }
    self.reverse!
    self.first.type
  end

  def include_name?(name)
    self.each do |v|
      return v if v.name == name
    end
    false
  end

  def types
    self.collect do |v|
      v.type
    end
  end

  def names
    self.collect do |v|
      v.name
    end
  end

end

def get_vars(visibility)
  ary = Array.new
  is_visible = false
  ARGV.each do |arg|
    if arg == visibility
      is_visible = true
      next
    end
    is_visible = false if KEYWORDS.include? arg
    ary << Var.new(arg) if is_visible == true
  end
  ary
end

def get_attributes(attributes)
  ary = Array.new
  is_attribute = false
  ARGV.each do |arg|
    if arg == attributes
      is_attribute = true
      next
    end
    is_attribute = false if KEYWORDS.include? arg
    ary << arg if is_attribute == true
  end
  if ARGV.include? attributes
    return ary
  else
    return nil
  end
end

def get_namespace
  index = ARGV.index("-namespace")
  return "" until index
  ns = ARGV[index + 1]
  if KEYWORDS.include?(ns) == true
    ""
  else
    ns ? ns : ""
  end
end

def number_of_tab(longest, word)
  return 1 if longest == word
  diff = (longest.length / 4) - (word.length / 4) + 1
  longest.length % 4 ? diff : diff + 1
end

def tab_for_namespace
  return TAB unless $namespace.empty?
  ""
end

def generate_constructors(f)
  namespace = $namespace.empty? ? $namespace : $namespace + "::"

  f.puts TEMPLATE if $is_template
  f.puts namespace + $name_templated + "::" + $name + "() {}" + NL * 2
  f.puts TEMPLATE if $is_template
  f.puts namespace + $name_templated + "::" + $name + "(#{$name_templated} const & src) {" + NL * 2
  f.puts TAB + "*this = src;" + NL * 2
  f.puts "}" + NL
end

def generate_operator_overload(f)
  namespace = $namespace.empty? ? $namespace : $namespace + "::"

  f.puts TEMPLATE if $is_template
  f.puts $operators.type + (TAB * number_of_tab($vars.longest_type, $operators.type)) + TAB + $operators.const + TAB + $operators.pointer_or_ref + TAB + namespace + $name_templated + "::" + $operators.name + " {" + NL * 2
  begin
    vars = $private + $protected
    vars.each do |v|
      f.puts TAB + "this->_" + v.name + " = rhs." + v.name + "();"
    end
    $public.each do |v|
      f.puts TAB + "this->" + v.name + " = rhs." + v.name + ";"
    end

    f.puts NL + TAB + "return *this;" + NL * 2
  end
  f.puts "}" + NL
end

def generate_destructor(f)
  namespace = $namespace.empty? ? $namespace : $namespace + "::"

  f.puts TEMPLATE if $is_template
  f.puts namespace + $name_templated + "::~" + $name + "() {}"
end

def generate_getters_cpp(f)
  namespace = $namespace.empty? ? $namespace : $namespace + "::"
  vars = $private.names + $protected.names if $getters.empty?
  vars = $getters unless $getters.empty?

  vars.each do |v|
    var = $vars.include_name? v
    if var
      f.puts TEMPLATE if $is_template
      f.puts var.type + (TAB * number_of_tab($vars.longest_type, var.type)) + TAB + "const" + TAB + (var.pointer_or_ref.empty? ? "&" : var.pointer_or_ref) + TAB + namespace + $name_templated + "::" + var.name + "() const { return this->_#{var.name}; }" + NL * 2
    else
      abort(v + " is not defined.")
    end
  end
end

def generate_setters_cpp(f)
  namespace = $namespace.empty? ? $namespace : $namespace + "::"
  vars = $private.names + $protected.names if $setters.empty?
  vars = $setters unless $setters.empty?

  vars.each do |v|
    var = $vars.include_name? v
    if var
      f.puts TEMPLATE if $is_template
      f.puts $name_templated + (TAB * number_of_tab($vars.longest_type, $name_templated)) + TAB * 3 + "&" + TAB + namespace + $name_templated + "::" + var.name + "(#{var.type} const & #{var.name}) {" + NL * 2
      begin
        f.puts TAB + "this->_#{var.name} = #{var.name};" + NL * 2
        f.puts TAB + "return *this;" + NL * 2
      end
      f.puts "}" + NL * 2
    else
      abort(v + " is not defined.")
    end
  end
end

def generate_exception_cpp(f)
  namespace = $namespace.empty? ? $namespace : $namespace + "::"

  $exceptions.each do |e|
    e += "Exception"
    f.puts TEMPLATE if $is_template
    f.puts namespace + $name_templated + "::" + e + "::#{e}() {}" + NL * 2

    f.puts TEMPLATE if $is_template
    f.puts namespace + $name_templated + "::" + e + "::#{e}(#{e} const & src) : std::exception(src) {}" + NL * 2

    f.puts TEMPLATE if $is_template
    f.puts "char" + TAB + "const" + TAB + "*" + TAB + namespace + $name_templated + "::" + e + "::what() const throw() {" + NL * 2
    begin
      f.puts TAB + "return \"\";" + NL * 2
    end
    f.puts "}" + NL * 2

    f.puts TEMPLATE if $is_template
    f.puts namespace + $name_templated + "::" + e + "::~#{e}() throw() {}" + NL * 2

    f.write TEMPLATE + "typename " if $is_template
    f.puts namespace + $name_templated + "::" + e + TAB * 3 + "&" + TAB + namespace + $name_templated + "::" + e + "::operator=(#{e} const & rhs) {" + NL * 2
    begin
      f.puts TAB + "std::exception::operator=(rhs);" + NL * 2
      f.puts TAB + "return *this;" + NL * 2
    end
    f.puts "}" + NL * 2
  end
end

def generate_cpp
  File.open $cpp, "w" do |f|
    f.puts "#include \"#{$hpp}\"" + NL * 2

    f.puts CONSTRUCTORS_COMMENT + NL
    generate_constructors f
    f.puts NL + MEMBER_FUNCTIONS_COMMENT + NL
    f.puts NL + NON_MEMBER_FUNCTIONS_COMMENT + NL
    f.puts NL + OPERATOR_OVERLOADS_COMMENT + NL
    generate_operator_overload f
    f.puts NL + DESTRUCTORS_COMMENT + NL
    generate_destructor f
    if $exceptions and $exceptions.empty? == false
      f.puts NL + EXCEPTIONS_COMMENT + NL
      generate_exception_cpp f
    end
    if $setters
      f.puts NL unless (@exceptions and $exceptions.empty? == false)
      f.puts SETTERS_COMMENT + NL
      generate_setters_cpp f
    end
    if $getters
      f.puts NL unless $setters or (@exceptions and $exceptions.empty? == false)
      f.puts GETTERS_COMMENT + NL
      generate_getters_cpp f
    end
    f.puts NL unless $setters or $getters or (@exceptions and $exceptions.empty? == false)
    f.puts NON_MEMBER_ATTRIBUTES_COMMENT + NL
    f.puts NL + TEMPLATE_DECLARATIONS_COMMENT + NL if $is_template

    f.puts NL + COMMENT_LINE
  end
end

def generate_exceptions_hpp(f)
  $exceptions.each do |e|
    e += "Exception"
    f.puts tab_for_namespace + TAB + "class" + TAB + e + " : public std::exception {" + NL * 2
    begin
      f.puts tab_for_namespace + TAB + "public:" + NL * 2
      f.puts tab_for_namespace + TAB * 2 + e + "();"
      f.puts tab_for_namespace + TAB * 2 + e + "(#{e} const & src);"
      f.puts tab_for_namespace + TAB * 2 + "virtual" + TAB + "char" + TAB + "const" + TAB + "*" + TAB + "what() const throw();"
      f.puts tab_for_namespace + TAB * 2 + "virtual" + TAB * (e.length / 4 + 3) + "~" + e + "() throw();"
      f.puts tab_for_namespace + TAB * 2 + e + TAB * 3 + "&" + TAB + "operator=(#{e} const & rhs);" + NL * 2
    end
    f.puts tab_for_namespace + TAB + "};" + NL * 2
  end
end

def generate_setters_hpp(f)
  namespace = $namespace.empty? ? $namespace : $namespace + "::"
  vars = $private.names + $protected.names if $setters.empty?
  vars = $setters unless $setters.empty?

  vars.each do |v|
    var = $vars.include_name? v
    if var
      f.puts tab_for_namespace + TAB + $name_templated + (TAB * (number_of_tab($vars.longest_type, $name_templated) + 2)) + TAB * 2 + "&" + TAB + var.name + "(#{var.type} const & #{var.name});"
    else
      abort(v + " is not defined.")
    end
  end
end

def generate_getters_hpp(f)
  namespace = $namespace.empty? ? $namespace : $namespace + "::"
  vars = $private.names + $protected.names if $getters.empty?
  vars = $getters unless $getters.empty?

  vars.each do |v|
    var = $vars.include_name? v
    if var
      f.puts tab_for_namespace + TAB + var.type + (TAB * (number_of_tab($vars.longest_type, var.type) + 2)) + "const" + TAB + (var.pointer_or_ref.empty? ? "&" : var.pointer_or_ref) + TAB + var.name + "() const;"
    else
      abort(v + " is not defined.")
    end
  end
end

def generate_private(f)
  f.puts tab_for_namespace + "private:" + NL * 2 unless $private.empty?
  longest = $vars.longest_type
  $private.each do |v|
    f.puts tab_for_namespace + TAB + v.type + (TAB * (number_of_tab(longest, v.type) + 2)) + v.const + TAB + v.pointer_or_ref + TAB + "_" + v.name + ";"
  end
  f.puts NL unless $private.empty?
end

def generate_protected(f)
  f.puts tab_for_namespace + "protected:" + NL * 2 unless $protected.empty?
  longest = $vars.longest_type
  $protected.each do |v|
    f.puts tab_for_namespace + TAB + v.type + (TAB * (number_of_tab(longest, v.type) + 2)) + v.const + TAB + v.pointer_or_ref + TAB + "_" + v.name + ";"
  end
  f.puts NL unless $protected.empty?
end

def generate_public(f)
  f.puts tab_for_namespace + "public:" + NL * 2
  longest = $vars.longest_type
  $public.each do |v|
    f.puts tab_for_namespace + TAB + v.type + (TAB * (number_of_tab(longest, v.type) + 2)) + v.const + TAB + v.pointer_or_ref + TAB + v.name + ";"
  end
  f.puts NL unless $public.empty?

  f.puts tab_for_namespace + TAB + $name_templated + "();" + NL
  f.puts tab_for_namespace + TAB + $name_templated + "(#{$name_templated} const & src);" + NL * 2

  f.puts tab_for_namespace + TAB + $operators.type + (TAB * (number_of_tab(longest, $operators.type) + 2)) + $operators.const + TAB + $operators.pointer_or_ref + TAB + $operators.name + ";" + NL * 2

  f.puts tab_for_namespace + TAB + "virtual" + TAB + (TAB * number_of_tab(longest, "")) + TAB * 3 + "~#{$name_templated}();"

  if $exceptions and $exceptions.empty? == false
    f.puts NL
    generate_exceptions_hpp f
  end

  if $setters
    f.puts NL
    generate_setters_hpp f
  end
  if $getters
    f.puts NL
    generate_getters_hpp f
  end
end

def generate_hpp
  File.open $hpp, "w" do |f|
    f.puts "#ifndef" + TAB * 2 + "#{$name.upcase}_#{$extension.upcase}_HPP"
    f.puts "# define" + TAB + "#{$name.upcase}_#{$extension.upcase}_HPP" + NL * 2

    f.puts "# include <stdexcept>" + NL * 2 if $exceptions and $exceptions.empty? == false
    f.puts "# include <string>" + NL * 2 if $vars.types.include? "std::string"

    f.puts "namespace" + TAB + $namespace + "{" + NL * 2 unless $namespace.empty?
    f.puts tab_for_namespace + "template< typename T >" if $is_template
    f.puts tab_for_namespace + "class#{TAB + $name} {" + NL * 2

    generate_private f
    generate_protected f
    generate_public f

    f.puts NL + tab_for_namespace + "};"
    f.puts NL + "};" unless $namespace.empty?

    f.puts NL + "#endif" + TAB + "//" + TAB + "#{$name.upcase}_#{$extension.upcase}_HPP"
  end
end

abort USAGE if ARGV.length.zero? == true || ARGV[0].start_with?("-") == true

$name = ARGV[0]
$is_interface = ARGV.include? "-interface"
$is_template = ARGV.include? "-template"
$namespace = get_namespace

abort "This class can't be a templated interface. This is possible available soon." if $is_interface and $is_template

if $is_interface
  $extension = "interface"
elsif $is_template
  $extension = "template"
else
  $extension = "class"
end

$hpp = $name + "." + $extension + ".hpp"
$cpp = $name + "." + $extension + ".cpp"

$name_templated = $is_template ? $name + "< T >" : $name

$private = get_vars "-private"
$protected = get_vars "-protected"
$public = get_vars "-public"
$operators = Var.new("#{$name_templated}&/operator=(#{$name_templated} const & rhs)")
$vars = $private + $protected + $public + [$operators]

$exceptions = get_attributes "-exception"
$setters = get_attributes "-s"
$getters = get_attributes "-g"

if File.exist? $hpp or File.exist? $cpp
  abort "The file already exist"
end

generate_hpp
generate_cpp
