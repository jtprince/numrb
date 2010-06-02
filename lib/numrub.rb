require 'ffi-inliner'

module Numrub
  class NumrubStruct < FFI::Struct
    layout :rank, :int,  #  # of dimensions
      :total, :int,  # total number of elements
      :type, :int,  # the data type
      :shape, :pointer, 
      :data, :pointer
    # right now just working for one dimension
    def self.to_nr(array)
      obj = self.new
      obj[:total] = array.size
      obj[:rank] = 1
      obj[:type] = 9990  # update
      obj[:shape] = FFI::MemoryPointer.new(:int, 1).put_array_of_int(0, [array.size])
      obj[:data] = FFI::MemoryPointer.new(:double, array.size).put_array_of_int(0, array)
      obj
    end
  end

  extend Inliner

  inline do |build|
    build.map 'numrub_struct *' => 'pointer'
    build.c_raw %q{
      typedef struct {
        int rank;
        int total;
        int type;
        int *shape;   
        char *data;   
      } numrub_struct;
    }
    build.c %q{
      numrub_struct* pass_out_as_pointer(numrub_struct *my_struct) { 
        return my_struct; 
      }
    }
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
