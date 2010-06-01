require 'ffi-inliner'

class Numrub
  TYPE = :float

  attr_accessor :pointer
  attr_accessor :size
  alias_method :length, :size

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

