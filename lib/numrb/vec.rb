require 'ffi-inliner'
require 'set'


module Numrb
  class Vec
    TYPES = [:int, :long_long, :float, :double]
    STRIDE = [4, 8, 4, 8]

    class Struct < FFI::Struct
      extend Inliner
      layout :size, :int,  # total number of elements
        :stride, :int,
        :dtype, :int,      # the data type
        :ptr, :pointer
      # right now just working for one dimension

      inline do |build|
        build.map 'vec_struct *' => 'pointer'
        build.c_raw %q{
          typedef struct {
            int size;
            int stride;
            int dtype;
            char *ptr;   
          } vec_struct;
        }
      end
    end

    attr_reader :struct

    def initialize
      @struct = Numrb::Vec::Struct.new
    end

    def dtype
      TYPES[@struct[:dtype]]
    end

    def self.to_nr(array)
      obj = self.new
      obj.struct[:size] = array.size
      obj.struct[:dtype] = Util.array_type(array)
      obj.struct[:stride] = STRIDE[obj.struct[:dtype]]
      obj.struct[:ptr] = 
        if obj.struct[:dtype] == 3
          FFI::MemoryPointer.new(:double, array.size).put_array_of_double(0, array)
        else
          FFI::MemoryPointer.new(:long_long, array.size).put_array_of_long_long(0, array)
        end
      obj
    end

    def size ; @struct[:size] end

    alias_method :length, :size

    def [](index)
      @struct[:ptr].send("get_#{dtype}".to_sym, index*@struct[:stride])
    end

    def []=(index, val)
      @struct[:ptr].send("put_#{dtype}".to_sym, index*@struct[:stride], val)
    end

    def self.[](*args)
      self.to_nr(args) 
    end
  end

  module Util
    # scans the array and returns the highest common type as an integer
    def self.array_type(array)
      if array.any? {|v| v.is_a?(Float) }
        3
      else
        1
      end
    end

  end
end





=begin
  extend Inliner
  inline %Q{
    #{TYPE} get(#{TYPE} *data, int n) {
      return data[n];
    }
  }

  def [](*args)
    self.get(@pointer, args.first)
  end

  inline %Q{
    #{TYPE} set(#{TYPE} *data, int n, #{TYPE} value) {
      data[n] = value;
      return value;
    }
  }

  def []=(*args)
    self.set(@pointer, *args)
  end

  inline %Q{
    double c_sum(#{Numrub::TYPE} *data, int length) { 
      int i;
      double sm;
      for (i=0; i<length; ++i) {
        sm += data[i];
      }
      return sm;
    }
  }

  def sum
    c_sum(@pointer, @size)
  end

  def initialize(array)
    @pointer = FFI::MemoryPointer.new(:float, array.size).send("put_array_of_#{TYPE}", 0, array)
    @size = array.size
  end

  def to_a
    send("get_array_of_#{TYPE}", 0, @size)
  end

  def method_missing(*args)
    orig_method = args.shift
    c_method = "c_#{orig_method}".to_sym
    if self.respond_to?(c_method)
      send(c_method, @pointer, @size, *args)
    else
      raise NoMethodError, "can't seem to locate #{orig_method} or even #{c_method}"
    end
  end
end

=end
