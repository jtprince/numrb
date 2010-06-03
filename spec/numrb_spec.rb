require 'spec_helper'

require 'numrb'
require 'benchmark'

class Array
  # a fast sum implementation for arrays, I believe
  def sum
    sm = 0
    self.each {|v| sm += v }
    sm
  end
end

describe "initializing a Numrub" do

  def properly_initialized(array)
    lambda do |obj|
      obj.is_a?(Numrb)
      obj.size.is @ar.size
    end
  end

  before do
    @ar = [10,20,30,40]
  end

  it 'takes a list in brackets' do
    Numrb[*@ar].should.be properly_initialized(@ar)
  end
end

describe 'casting' do
  it 'can be cast from a pointer' do
    FFI::Pointer.new 
  end
end

xdescribe "basic functions" do
  it 'can be passed out of a function as a pointer with FFI-Inliner' do
    array = [1,2,3,4,5,6,7]
    my_struct = Numrub::NumrubStruct.to_nr(array)
    Numrub.pass_out_as_pointer(my_struct).is my_struct.to_ptr
  end

  it 'must be cast after being passed out' do
    array = [1,2,3,4,5,6,7]
    my_struct = Numrub::NumrubStruct.to_nr(array)
    pointer = Numrub.pass_out_as_pointer(my_struct)
    object = Numrub::NumrubStruct.new(pointer)
    my_struct[:data].is object[:data]
    my_struct.class.is object.class
    my_struct.object_id.isnt object.object_id  # it is a new object (even though it points to the same data)
  end
end

xdescribe "Numrub with a simple numerical array" do
  before do
    @ar = [1,2,3,4,5]
    @nr = Numrub.new(@ar)  
  end

  it "sums" do
    @nr.sum.is 15
  end

  it "sums at least 50 times faster than a ruby array" do
    sz = 1000000
    ar = Array.new(sz, 2.0)
    nar = Numrub.new(ar) 
    (array_time, nub_time) = [ar, nar].map {|v| Timer.measure{ v.sum } }
    ok( (array_time / nub_time) > 50 )
  end

end




=begin
# File 'lib/ffi/pointer.rb', line 113

def write_array_of_type(type, writer, ary)
  size = FFI.type_size(type)
  tmp = self
  ary.each_with_index {|i, j|
    tmp.send(writer, i)
    tmp += size unless j == ary.length-1 # avoid OOB
  }
  self
end

# File 'lib/ffi/pointer.rb', line 102

def read_array_of_type(type, reader, length)
  ary = []
  size = FFI.type_size(type)
  tmp = self
  length.times { |j|
    ary << tmp.send(reader)
    tmp += size unless j == length-1 # avoid OOB
  }
  ary
end

=end


=begin
# these seem to be the available functions for getting things in/out
put_array_of_int8
put_array_of_int16
put_array_of_int32
put_array_of_int64
put_array_of_long

put_array_of_uint8
put_array_of_uint16
put_array_of_uint32
put_array_of_uint64
put_array_of_ulong

put_array_of_char       # -> int8
put_array_of_short      # -> int16
put_array_of_int        # -> int32
put_array_of_long_long  # -> int64

put_array_of_uchar       # -> uint8
put_array_of_ushort      # -> uint16
put_array_of_uint        # -> uint32
put_array_of_ulong_long  # -> uint64

put_array_of_float32
put_array_of_float     # ->   put_array_of_float32
put_array_of_float64
put_array_of_double    # ->   put_array_of_float64

put_array_of_pointer

get_array_of_string  # there is no put_array_of_string
=end
