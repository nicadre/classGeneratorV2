#!/usr/bin/env ruby
# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    classGenerator.rb                                  :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: niccheva <niccheva@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2015/09/29 17:07:44 by niccheva          #+#    #+#              #
#    Updated: 2015/11/13 01:49:55 by niccheva         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

BLANK_COMMENT_LINE = "/*#{" " * 76}*/"
COMMENT_LINE = "/* #{"*" * 74} */"

NL = "\n"
TAB = "\t"

def generate_comments(name)
  comment = "#{COMMENT_LINE}" + NL
  comment += "#{BLANK_COMMENT_LINE}" + NL
  spaces = (76 - name.length)
  comment += "/*#{" " * (spaces / 2)}#{name}#{" " * (spaces.odd? ? (spaces / 2 + 1) : spaces / 2)}*/" + NL
  comment += "#{BLANK_COMMENT_LINE}" + NL
  comment += "#{COMMENT_LINE}" + NL
end

CONSTRUCTORS_COMMENT = generate_comments "Constructors"
DESTRUCTORS_COMMENT = generate_comments "Destructors"
EXCEPTIONS_COMMENT = generate_comments "Exceptions"
GETTERS_COMMENT = generate_comments "Getters"
MEMBER_FUNCTIONS_COMMENT = generate_comments "Member Functions"
OPERATOR_OVERLOADS_COMMENT = generate_comments "Operator Overloads"
SETTERS_COMMENT = generate_comments "Setters"

USAGE = "Usage: class_name [-public \"type/param_name\"...]
                  [-private \"type/param_name\"...]
                  [-protected \"type/param_name\"...]
                  [-inherit class_name...] (soon)
                  [-s [param_name...]]
                  [-g [param_name...]]
                  [-interface \"type/method_name(type param_name...)\"...] (soon)
                  [-abstract \"type/method_name(type param_name...)\"...] (soon)
                  [-member \"type/method_name(type param_name...)\"...] (soon)
                  [-exception name...] (soon)"

KEYWORDS = ["-public", "-protected", "-private", "-inherit", "-s", "-g", "-interface", "-abstract", "-member", "-exception"]

class Var

  attr_reader :type, :name

  def initialize(var)
    ary = var.split "/"
    abort USAGE if ary == nil || ary.length != 2
    @type = ary.first
    @name = ary.last
    @is_ref = @type.include? "&"
    @is_pointer = @type.include? "*"
    @is_function = @name.include? "("
    @type.delete! "*" if @is_pointer
    @type.delete! "&" if @is_ref
  end

  def get_type_length
    @type.length
  end

  def pointer_or_ref
    return "*" if @is_pointer == true
    return "&" if @is_ref == true
    return ""
  end

end

class Array

  def longest_type
    sorted = self
    sorted.sort_by! {|x| x.type.length}
    sorted.reverse!
    sorted.first.type
  end

  def include_name?(name)
    self.each do |v|
      return v if v.name == name
    end
    false
  end

end

def create_operator(name)
  ary = Array.new
  ary << Var.new("#{name}&/operator=(#{name} const & rhs)")
  ary
end

def get_all_vars(name)
  hash = Hash.new
  hash[:public] = get_vars "-public"
  hash[:protected] = get_vars "-protected"
  hash[:private] = get_vars "-private"
  hash[:operator] = create_operator name
  hash
end

def hash_to_a(hash)
  ary = Array.new
  hash.each do |_, v|
    ary += v
  end
  ary
end

def get_setters
  ary = Array.new
  is_setter = false
  ARGV.each do |arg|
    if arg == "-s"
      is_setter = true
      next
    end
    is_setter = false if KEYWORDS.include? arg
    if is_setter == true
      ary << arg
    end
  end
  if ARGV.include? "-s"
    return ary
  else
    return nil
  end
end

def get_getters
  ary = Array.new
  is_getter = false
  ARGV.each do |arg|
    if arg == "-g"
      is_getter = true
      next
    end
    is_getter = false if KEYWORDS.include? arg
    if is_getter == true
      ary << arg
    end
  end
  if ARGV.include? "-g"
    return ary
  else
    return nil
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
    if is_visible == true
      ary << Var.new(arg)
    end
  end
  ary
end

def define_number_of_tab(longest, word)
  return 1 if longest == word
  diff = (longest.length / 4) - (word.length / 4)
  longest.length % 4 ? diff + 1: diff + 2
end

def vars_from_name(names, vars)
  ary = Array.new
  names.each do |name|
    var = vars.include_name? name
    if !!var == true
      ary << var
    else
      abort(name + " is not defined.")
    end
  end
  ary
end

def gen_getters_hpp(f, name, vars)
  longest = hash_to_a(get_all_vars(name)).longest_type

  vars.each do |var|
    f.puts TAB + var.type + (TAB * define_number_of_tab(longest, var.type)) + var.pointer_or_ref + var.name + "() const;" + NL
  end
end

def gen_setters_hpp(f, name, vars)
  longest = hash_to_a(get_all_vars(name)).longest_type

  vars.each do |var|
    f.puts TAB + name + (TAB * define_number_of_tab(longest, name)) + "&" + var.name + "(" + var.type + " " + var.pointer_or_ref + var.name + ");" + NL
  end
end

def gen_getters_cpp(f, name, vars)
  longest = hash_to_a(get_all_vars(name)).longest_type

  vars.each do |var|
    f.puts var.type + (TAB * define_number_of_tab(longest, var.type)) + var.pointer_or_ref + "#{name}::" + var.name + "() const { return this->_#{var.name}; }" + NL
  end
end

def gen_setters_cpp(f, name, vars)
  longest = hash_to_a(get_all_vars(name)).longest_type

  vars.each do |var|
    f.puts name + (TAB * define_number_of_tab(longest, name)) + "&#{name}::" + var.name + "(" + var.type + " " + var.pointer_or_ref + var.name + ") {" + NL
    f.puts TAB + "this->_#{var.name} = #{var.name};"
    f.puts NL + TAB + "return *this;"
    f.puts "}" + NL * 2
  end
end

def generate_private_hpp(f, name)
  if ARGV.include? "-private"
    f.puts "private:"
    vars = get_all_vars name
    longest = hash_to_a(vars).longest_type
    vars[:private].each do |v|
      f.puts TAB + v.type + (TAB * define_number_of_tab(longest, v.type)) + v.pointer_or_ref + "_" + v.name + ";"
    end
    f.puts NL
  end
end

def generate_protected_hpp(f, name)
  if ARGV.include? "-protected"
    f.puts "protected:"
    vars = get_all_vars name
    longest = hash_to_a(vars).longest_type
    vars[:protected].each do |v|
      f.puts TAB + v.type + (TAB * define_number_of_tab(longest, v.type)) + v.pointer_or_ref + "_" + v.name + ";"
    end
    f.puts NL
  end
end

def generate_public_hpp(f, name)
  f.puts "public:"
  vars = get_all_vars name
  if ARGV.include? "-public"
    longest = hash_to_a(vars).longest_type
    vars[:public].each do |v|
      f.puts TAB + v.type + (TAB * define_number_of_tab(longest, v.type)) + v.pointer_or_ref + v.name + ";"
    end
    f.puts NL
  end
  f.puts TAB + "#{name}();"
  f.puts TAB + "#{name}(#{name} const & src);" + NL * 2

  f.puts TAB + vars[:operator].first.type + TAB * define_number_of_tab(longest, vars[:operator].first.type) + vars[:operator].first.pointer_or_ref + vars[:operator].first.name + ";" + NL * 2

  f.puts TAB + "virtual ~#{name}();"

  getters = get_getters
  setters = get_setters

  if getters
    f.puts NL
    if getters.empty?
      gen_getters_hpp f, name, (vars[:private] + vars[:protected])
    else
      gen_getters_hpp f, name, vars_from_name(getters, (vars[:private] + vars[:protected]))
    end
  end

  if setters
    f.puts NL
    if setters.empty?
      gen_setters_hpp f, name, (vars[:private] + vars[:protected])
    else
      gen_setters_hpp f, name, vars_from_name(setters, (vars[:private] + vars[:protected]))
    end
  end
end

abort USAGE if ARGV.length.zero?

name = ARGV[0]

abort "The file already exist" if File.exist? (name + ".class.hpp") or File.exist? (name + ".class.cpp")

File.open name + ".class.hpp", "w" do |f|
  f.puts "#ifndef" + TAB * 2 + "#{name.upcase}_CLASS_HPP"
  f.puts "# define" + TAB + "#{name.upcase}_CLASS_HPP" + NL * 2

  hash_to_a(get_all_vars(name)).each do |var|
    if var.type.include? "std::string"
      f.puts "# include <string>" + NL * 2
      break
    end
  end

  f.puts "class #{name} {" + NL * 2

  generate_private_hpp(f, name)
  generate_protected_hpp(f, name)
  generate_public_hpp(f, name)

  f.puts NL + "};" + NL * 2

  f.puts "#endif" + TAB + "//" + TAB + "#{name.upcase}_CLASS_HPP"
end

File.open name + ".class.cpp", "w" do |f|
  vars = get_all_vars(name)

  f.puts "#include \"#{name}.class.hpp\"" + NL * 2
  f.puts CONSTRUCTORS_COMMENT + NL

  f.puts "#{name}::#{name}() {}" + NL * 2

  f.puts "#{name}::#{name}(#{name} const & src) {" + NL
  begin
    vars[:private].each do |var|
      f.puts TAB + "this->_" + var.name + " = src." + var.name + "();"
    end
    vars[:protected].each do |var|
      f.puts TAB + "this->_" + var.name + " = src." + var.name + "();"
    end
    vars[:public].each do |var|
      f.puts TAB + "this->" + var.name + " = src." + var.name + ";"
    end
  end
  f.puts "}" + NL * 2

  f.puts OPERATOR_OVERLOADS_COMMENT + NL
  f.puts vars[:operator].first.type + (TAB * define_number_of_tab(hash_to_a(vars).longest_type, vars[:operator].first.type)) + vars[:operator].first.pointer_or_ref + name + "::" + vars[:operator].first.name + "{" + NL
  begin
    vars[:private].each do |var|
      f.puts TAB + "this->_" + var.name + " = rhs." + var.name + "();"
    end
    vars[:protected].each do |var|
      f.puts TAB + "this->_" + var.name + " = rhs." + var.name + "();"
    end
    vars[:public].each do |var|
      f.puts TAB + "this->" + var.name + " = rhs." + var.name + ";"
    end

    f.puts NL + TAB + "return *this;"
  end
  f.puts "}" + NL * 2

  f.puts DESTRUCTORS_COMMENT + NL
  f.puts name + "::~" + name + "() {}" + NL

  getters = get_getters
  if getters
    f.puts NL
    f.puts GETTERS_COMMENT + NL
    if getters.empty? == true
      gen_getters_cpp f, name, (vars[:private] + vars[:protected])
    else
      gen_getters_cpp f, name, vars_from_name(getters, (vars[:private] + vars[:protected]))
    end
  end

  setters = get_setters
  if setters
    f.puts NL
    f.puts SETTERS_COMMENT + NL
    if setters.empty? == true
      gen_setters_cpp f, name, (vars[:private] + vars[:protected])
    else
      gen_setters_cpp f, name, vars_from_name(setters, (vars[:private] + vars[:protected]))
    end
  end

end
