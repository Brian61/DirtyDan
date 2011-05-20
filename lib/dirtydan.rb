#!/usr/bin/env ruby
# dirtydan
# --------
# Provides overide of attr_xxx accessors to automate change tracking
#
# Author: Brian Lee Price
# Date: 5/20/2011
# Copyright (C) 2011 all rights reserved
# Released under the MIT License <http://www.opensource.org/licenses/mit-license.php>
#
# Documentation
# ----------------
# Including the DirtyDan module in a class creates custom attr_writer and
# attr_accessor methods in the class's metaclass.  When an attribute declared
# by either of those methods is changed, an instance variable named @dirty
# will be created and set true.  
#
# DirtyDan provides the following methods in addition to the dynamically 
# created attr_xxx methods:
# 
# mark_dirty() - sets @dirty to true
#
# is_dirty?() - returns true if and only if @dirty exists and is true
#
# clean_dirty() - removes the @dirty instance variable.
#   The reason for removal of the variable instead of merely setting
#    it false is to avoid unnecessary inclusion in dumps.
#
# Usage
# -------
# class Simple
#   include DirtyDan
#   attr_accessor :somevar
#   attr_writer :a_write_only_var
#   
#   def a_custom_var=( val )
#      mark_dirty() if @a_custom_var != val
#      val = @a_custom_var
#   end
#   
#   def save
#      if is_dirty?
#        clean_dirty()
#        ... code saving object state somewhere ...
#       end
#    end
#  end
#

module DirtyDan
  def DirtyDan.included(mod)
    class << mod
      instance_eval do
        define_method( :attr_writer ) do |*syms|
          syms.each do |sym|
            class_eval <<-THECODE
              def #{sym}= (val)
                mark_dirty() if @#{sym} != val
                @#{sym} = val
              end
            THECODE
          end
        end
      end
      instance_eval do
        define_method( :attr_accessor ) do |*syms|
          attr_writer *syms
          attr_reader *syms
        end
      end
    end
  end
  def mark_dirty; @dirty = true; end
  def is_dirty?; !!@dirty; end
  def clean_dirty; remove_instance_variable(:@dirty); end
end

# Unit tests
if __FILE__ == $0
  require 'test/unit'
  
  class TestClass
    include DirtyDan
    attr_reader :test1
    attr_writer :test1
    attr_accessor :test2, :test3
  end
  
  class DirtyDanTest < Test::Unit::TestCase
    def setup
      @tobj = TestClass.new
    end
    
    def test_attr_writer_creates_working_method
      expected = 5
      @tobj.test1 = expected
      assert_equal(expected, @tobj.test1)
    end
    
    def test_attr_accessor_creates_working_methods
      expected = "mememe"
      @tobj.test2 = expected
      assert_equal(expected, @tobj.test2)
    end
    
    def test_dirty_variable_does_not_exist_before_marking
      assert(!@tobj.methods.include?(:@dirty))
    end
    
    def test_initial_object_is_not_dirty
      assert(!@tobj.is_dirty?)
    end
    
    def test_is_dirty_method_does_not_create_variable
      @tobj.is_dirty?
      assert(!@tobj.methods.include?(:@dirty))
    end
    
    def test_first_write_to_attr_writer_created_method_marks_dirty
      @tobj.test1 = "any"
      assert(@tobj.is_dirty?)
    end
    
    def test_first_write_to_attr_accessor_created_write_method_marks_dirty
      @tobj.test3 = "any"
      assert(@tobj.is_dirty?)
    end
    
    def test_is_dirty_is_false_after_clean_dirty
      @tobj.test1 = "any"
      @tobj.clean_dirty
      assert(!@tobj.is_dirty?)
    end
    
    def test_clean_dirty_removes_dirty_variable
      @tobj.test1 = "any"
      @tobj.clean_dirty
      assert(!@tobj.methods.include?(:@dirty))
    end
    
    def test_write_of_equal_data_does_not_mark_dirty
      data = "something"
      @tobj.test1 = data
      @tobj.clean_dirty
      @tobj.test1 = data
      assert(!@tobj.is_dirty?)
    end
  end
end
