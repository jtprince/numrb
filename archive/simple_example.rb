require 'ffi-inliner'
require 'ffi'

class Vec

  TYPES = {:int => 'int', :long_long => 'long long', :float => 'float', :double => 'double'}
  TYPES_AR = [:int, :long_long, :float, :double]
  STRIDE = {:int => 4, :long_long => 8, :float => 4, :double => 8}

  class Data < FFI::AutoPointer
    module LibC
      extend FFI::Library
      ffi_lib 'c'
      attach_function :malloc, [ :uint ], :pointer
      attach_function :free, [ :pointer ], :void
    end
    extend Inliner
    def self.release(ptr)
      puts "RELEASING I THINK!"
      LibC.free(ptr)
    end
    def initialize(size, stride=8)
      puts "THINKING ABOUT ALLOCATING"
      # malloc(1) == 1 char [fundamental unit of C]
      super(LibC.malloc(size*stride))
    end
  end

  class Struct_double < FFI::Struct

    extend Inliner
    layout :size, :int,  # total number of elements
      :dtype, :int,      # the data type
      :ptr, :pointer
    inline do |build|
      build.map "vec_struct_{ctype} *" => 'pointer'
      build.c_raw %Q{
        typedef struct {
          int size;
          int dtype;
          double *ptr;   
        } vec_struct_double;
      }
    end

  end

  # requires a symbol datatype
  def initialize(datatype, lngth, array=nil)
    @struct = Vec.const_get("Struct_#{datatype}").new
    @struct[:dtype] = TYPES_AR.index(datatype)
    @struct[:size] = lngth
    @struct[:ptr] = Vec::Data.new(lngth, STRIDE[datatype])
    if array
      @struct[:ptr].send("put_array_of_#{datatype}", 0, array)
    end
  end

end

if $0 == __FILE__

  vec = Vec.new(:double, 10000000)
end
