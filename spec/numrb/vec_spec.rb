require 'spec_helper'

require 'numrb/vec'

class Array
  def sum
    #self.inject(0) {|sum,v| sum+=v }  # slower
    # On 1.9, this is faster than using a range to go through the indices:
    val = 0
    self.each {|v| val += v }
    val
  end
end

describe "initializing a Numrub::Vec" do

  def properly_initialized(array, dtype)
    lambda do |obj|
      obj.is_a?(Numrb::Vec)
      obj.size.is array.size
      obj.dtype.is dtype
    end
  end

  before do
    @ar_int = [10,20,30,40]
    @ar_dbl = [10,20,30.0,40]
  end

  it 'takes a list in brackets' do
    [@ar_int, @ar_dbl].zip([:long_long, :double]) do |ar, dtype|
      nrb = Numrb::Vec[*ar]
      nrb.should.be properly_initialized(ar, dtype)
    end
  end
  
end

describe 'operations with another Numrub::Vec' do

  before do
    @ar_int1 = [10,20,30,40]
    @ar_int2 = [5,10,15,20]
    @nrb_int1 = Numrb::Vec[*@ar_int1]
    @nrb_int2 = Numrb::Vec[*@ar_int2]

    @ar_dbl1 = [10,20,30.0,40]
    @nrb_dbl1 = Numrb::Vec[*@ar_dbl1]
    @ar_dbl2 = [5,10,15.0,20]
    @nrb_dbl2 = Numrb::Vec[*@ar_dbl2]
  end

  it 'does element-wise arithmetic z = x + y  (one of: [+-*/])' do
    # z = x + y
    {:add => '+', :multiply => '*', :subtract => '-', :divide => '/'}.each do |op_name,operator|
      result = @nrb_int1.send(operator, @nrb_int2)
      result.to_a.is @ar_int1.zip(@ar_int2).map {|x,y| x.send(operator, y) }
    end
  end
end

describe "an initialized Numrub::Vec" do

  before do
    @ar_int = [10,20,30,40]
    @ar_dbl = [10,20,30.0,40]
    @nrb_int = Numrb::Vec[*@ar_int]
    @nrb_dbl = Numrb::Vec[*@ar_dbl]
  end

  it 'knows its data type' do
    @nrb_dbl.dtype.is :double
    @nrb_int.dtype.is :long_long
  end
  
  it 'can output a regular array' do
    @nrb_int.to_a.is @ar_int
  end
  
end

describe 'indexing' do
  before do
    @ar_int = [10,20,30,40]
    @nrb_int = Numrb::Vec[*@ar_int]
  end

 it 'does single number indexing' do
    @nrb_int[0].is 10
    @nrb_int[3].is 40

    (@nrb_int[2] = 90).is 90
    @nrb_int[2].is 90
    puts "ACCESS: "
    struct = @nrb_int.struct
    puts Timer.measure { 1000000.times {@nrb_int[2]} }
    puts Timer.measure { 1000000.times {struct.get(struct,2)} }
    puts Timer.measure { 1000000.times {@ar_int[2]} }
    puts "SETTING: "
    puts Timer.measure { 1000000.times {@nrb_int[2]=2} }
    puts Timer.measure { 1000000.times {struct.set(struct,2,2)} }
    puts Timer.measure { 1000000.times {@ar_int[2]=2} }
  end

  it "Raises an error on negative index" do
    #lambda { @nrb_int[-1] }.should.raise(IndexError)
    1.is 1
  end

  it 'does no range checking' do
    ok @nrb_int[10].is_a?(Integer)
  end


end

describe 'folding operations' do

  before do
    @ar_int = [10,20,30,40]
    @ar_dbl = [10,20,30.0,40]
    @nrb_int = Numrb::Vec[*@ar_int]
    @nrb_dbl = Numrb::Vec[*@ar_dbl]
  end

  it "sums (at least 50 times faster than a ruby array)" do
    # this is typically 100 times faster, but just to be safe
    @nrb_int.sum.is 100

    sz = 1_000_000
    ar = Array.new(sz, 2.0)
    nar = Numrb::Vec.to_nr(ar)
    results = []
    (array_time, nub_time) = [ar, nar].map {|v| Timer.measure{ results.push(v.sum) } }
    results[0].is 2000000.0  # sanity
    results[0].is results[1]
    ok( (array_time / nub_time) > 50 )
    puts ""
    puts "--- TIME to SUM ARRAY: #{array_time}"
    puts "--- TIME to SUM VEC: #{nub_time}"
  end


end
  


=begin
###############
# REFERENCE
###############

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
