require 'ffi-inliner'

class Numrb < FFI::Struct
  TYPES = [:float, :double, :int, :long]
  alias_method :cast, :initialize
  alias_method :bitsize, :size

  layout :ndim, :int,  #  # of dimensions
    :size, :int,  # total number of elements
    :dtype, :int,  # the data type
    :shape, :pointer, 
    :ptr, :pointer
  # right now just working for one dimension
  def self.to_nr(array)
    obj = self.new
    obj[:size] = array.size
    obj[:ndim] = 1
    obj[:dtype] = 9990  # update
    obj[:shape] = FFI::MemoryPointer.new(:int, 1).put_array_of_int(0, [array.size])
    obj[:ptr] = FFI::MemoryPointer.new(:double, array.size).put_array_of_int(0, array)
    obj
  end

  def size ; self[:size] end
  def ndim ; self[:ndim] end
  def dtype; self[:dtype] end

  alias_method :length, :size

  extend Inliner

  inline do |build|
    build.map 'numrb_struct *' => 'pointer'
    build.c_raw %q{
      typedef struct {
        int ndim;
        int size;
        int dtype;
        int *shape;   
        char *ptr;   
      } numrb_struct;
    }
    build.c %q{
      numrb_struct* pass_out_as_pointer(numrb_struct *my_struct) { 
        return my_struct; 
      }
    }
    #TYPES.each do |tp|
    #build.c %Q{
    #  #{tp}* get(numrb_struct* strct, *ar) {
    #    
    #  }
    #}
  end

  def self.[](*args)
    self.to_nr(args) 
  end

  module Util
    # scans the array and returns the highest common type as a symbol
    def array_type
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
