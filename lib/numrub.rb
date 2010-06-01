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
  inline %Q{
    #{TYPE} set(#{TYPE} *data, int n, #{TYPE} value) {
      data[n] = value;
      return value;
    }
  }

  def initialize(array)
    @pointer = FFI::MemoryPointer.new(:float, array.size).send("put_array_of_#{TYPE}", 0, array)
    @size = array.size
  end

  def [](*args)
    self.get(@pointer, args.first)
  end

  def []=(*args)
    self.set(@pointer, *args)
  end

  def to_a
    send("get_array_of_#{TYPE}", 0, @size)
  end
end

array = Array.new(5, 2.0)
x = Numrub.new array
p x[1]
p x[1]=75.0


# Extending the class

class MyNumrub < Numrub
  extend Inliner

  def method_missing(*args)
    orig_method = args.shift
    c_method = "c_#{orig_method}".to_sym
    if self.respond_to?(c_method)
      send(c_method, @pointer, @size, *args)
    else
      raise NoMethodError, "can't seem to locate #{orig_method} or even #{c_method}"
    end
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


end

class Array
  # a fast sum implementation for arrays, I believe
  def sum
    sm = 0
    self.each {|v| sm += v }
    sm
  end
end


x = MyNumrub.new array
p x.sum

require 'benchmark'

array_size = 10_000_000
array = Array.new(array_size, 2.0)
nar = MyNumrub.new(array)

Benchmark.bm do |bm|
  bm.report("Array#sum") { puts "SUM: #{array.sum}" }
  bm.report("(FFI based) MyNumrub#sum") { puts "SUM: #{nar.sum}" }
end



