#!/usr/bin/env ruby
# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    classGenerator.rb                                  :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: niccheva <niccheva@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2015/09/29 17:07:44 by niccheva          #+#    #+#              #
#    Updated: 2015/11/09 11:55:27 by niccheva         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

BLANK_COMMENT_LINE = "/*#{" " * 76}*/"
COMMENT_LINE = "/* #{"*" * 74} */"

def generate_comments(name)
  comment = "#{COMMENT_LINE}\n"
  comment += "#{BLANK_COMMENT_LINE}\n"
  spaces = (76 - name.length)
  comment += "/*#{" " * (spaces / 2)}#{name}#{" " * (spaces.odd? ? (spaces / 2 + 1) : spaces / 2)}*/\n"
  comment += "#{BLANK_COMMENT_LINE}\n"
  comment += "#{COMMENT_LINE}\n"
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
                  [-inherit class_name...]
                  [-s [param_name...]]
                  [-g [param_name...]]
                  [-interface \"type/method_name(type param_name...)\"...]
                  [-abstract \"type/method_name(type param_name...)\"...]
                  [-member \"type/method_name(type param_name...)\"...]
                  [-exception name...]"

NL = "\n"
TAB = "\t"

KEYWORDS = ["-public", "-protected", "-private", "-inherit", "-s", "-g", "-interface", "-abstract", "-member", "-exception"]

class Var

  attr_reader :type, :name, :is_ref_or_pointer

  def initialize(var)
    ary = var.split "/"
    abort USAGE if ary == nil || ary.length != 2
    @type = ary.first
    @name = ary.last
    @is_ref_or_pointer = (@type.include? "*") || (@type.include? "&")
    @is_function = @name.include? "("
    if @is_ref_or_pointer
      @type.delete! "*", "&"
    end
  end

  def get_type_length
    @type.length
  end

end

class Array

  def longest_type
    sorted = self
    sorted.sort_by! {|x| x.type.length}
    sorted.reverse!
    puts sorted.to_s
    sorted.first
  end

=begin
  def longest_word
#    self.max_by(&:length)
    group_by(&:size).max.last.to_s
  end
=end

end

def get_all_vars
  hash = Hash.new
  hash[:public] = get_vars "-public"
  hash[:protected] = get_vars "-protected"
  hash[:private] = get_vars "-private"
  hash
end

def hash_to_a(hash)
  ary = Array.new
  hash.each do |_, v|
    ary += v
  end
  ary
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
    if is_visible
      ary << Var.new(arg)
    end
  end
  ary
end

def define_number_of_tab(longest, word)
  return 1 if longest == word
  diff = (longest.length / 4) - (word.length / 4)
  longest.length % 4 ? diff : diff + 1
end

def generate_private_hpp(f, name)
  if ARGV.include? "-private"
    f.puts "private:"
    types = get_types name
    longest = types.longest_word
    get_var("private").each do |k, v|
      f.puts TAB + k + (TAB * define_number_of_tab(longest, k)) + "_" + v + ";"
    end
    f.puts NL
  end
end

def generate_protected_hpp(f, name)
  if ARGV.include? "-protected"
    f.puts "protected:"
    types = get_types name
    longest = types.longest_word
    get_var("protected").each do |k, v|
      f.puts TAB + k + (TAB * define_number_of_tab(longest, k)) + "_" + v + ";"
    end
    f.puts NL
  end
end

def generate_public_hpp(f, name)
  f.puts "public:"
  if ARGV.include? "-public"
    types = get_types name
    longest = types.longest_word
    get_var("public").each do |k, v|
      f.puts TAB + k + (TAB * define_number_of_tab(longest, k)) + v + ";"
    end
    f.puts NL
  end
  f.puts TAB + "#{name}();"
  f.puts TAB + "#{name}(#{name} const & src);" + NL * 2

  f.puts TAB + "#{name}" + TAB * define_number_of_tab(longest, name) + "&operator=(#{name} const & rhs);" + NL * 2

  f.puts TAB + "virtual ~#{name}();"
end

abort USAGE if ARGV.length.zero?

name = ARGV[0]

abort "The file already exist" if File.exist? (name + ".class.hpp") or File.exist? (name + ".class.cpp")

File.open name + ".class.hpp", "w" do |f|
  f.puts "#ifndef" + TAB * 2 + "#{name.upcase}_CLASS_HPP"
  f.puts "# define" + TAB + "#{name.upcase}_CLASS_HPP" + NL * 2

  f.puts "class #{name} {" + NL * 2

  generate_private_hpp(f, name)
  generate_protected_hpp(f, name)
  generate_public_hpp(f, name)

  f.puts NL + "};" + NL * 2

  f.puts "#endif" + TAB + "//" + TAB + "#{name.upcase}_CLASS_HPP"
end

File.open name + ".class.cpp", "w" do |f|
  f.puts "#include \"#{name}.class.hpp\"" + NL * 2
  f.puts CONSTRUCTORS_COMMENT + NL

  f.puts "#{name}::#{name}() {}" + NL

  f.puts "#{name}::#{name}(#{name} const & src) {" + NL
  begin
    get_names.each do |v|
      f.puts "this->#{v}(src.#{v}());"
    end
  end
  f.puts "}"
end
