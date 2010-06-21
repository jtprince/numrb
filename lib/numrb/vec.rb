require 'ffi-inliner'
require 'set'


#$ALLOC_COUNT = 0


module Inliner
  C_TO_FFI.merge({ })
end



module Numrb

  #C_TO_FFI = {
  #  'void' => :void,
  #  'char' => :char,
  #  'unsigned char' => :uchar,
  #  'int' => :int,
  #  'unsigned int' => :uint,
  #  'long' => :long,
  #  'unsigned long' => :ulong,
  #  'float' => :float,
  #  'double' => :double,
  #}

  ADDITIONAL_C_TYPES = {
    'long long' => :long_long,
    'int32_t' => :int32,
  }

  Inliner::C_TO_FFI.merge!(ADDITIONAL_C_TYPES)

  class Vec


    TYPES = {:int => 'int32_t', :long_long => 'long long', :float => 'float', :double => 'double'}
    TYPES_AR = [:int, :long_long, :float, :double]
    STRIDES = {:int => 4, :long_long => 8, :float => 4, :double => 8}
    OPERATIONS =  {:add => '+', :multiply => '*', :subtract => '-', :divide => '/'}
    # bumps up to the higher number, higher value object
    BIGGER = {:int => 'long long', :long_long => 'long long', :float => 'double', :double => 'double'}
    ZERO = {:int => '0', :long_long => '0', :float => '0.f', :double => '0.0'}


    #TYPES = {:int => 'int32_t', :long_long => 'int64_t', :float => 'float', :double => 'double'}
    #TYPES_AR = [:int, :long_long, :float, :double]
    #STRIDES = {:int => 4, :long_long => 8, :float => 4, :double => 8}
    #OPERATIONS =  {:add => '+', :multiply => '*', :subtract => '-', :divide => '/'}
    ## bumps up to the higher number, higher value object
    #BIGGER = {:int => 'int64_t', :long_long => 'int64_t', :float => 'double', :double => 'double'}
    #ZERO = {:int => '0', :long_long => '0', :float => '0.f', :double => '0.0'}

    class Data < FFI::AutoPointer
      module LibC
        extend FFI::Library
        ffi_lib 'c'
        attach_function :malloc, [ :uint ], :pointer
        attach_function :free, [ :pointer ], :void
      end
      def self.release(ptr)
        #$ALLOC_COUNT -= 1
        #puts "RELEASING (CNT: #{$ALLOC_COUNT}"
        LibC.free(ptr)
      end
      def initialize(size, stride=8)
        #$ALLOC_COUNT += 1
        #puts "ALLOCATED (CNT: #{$ALLOC_COUNT}"
        # malloc(1) == 1 char [fundamental unit of C]
        super(LibC.malloc(size*stride))
      end
    end

    TYPES.each do |dtp, ctype|
      klass = Vec.const_set("Struct_#{dtp}", Class.new(FFI::Struct))
      klass.module_eval do
        first_other_output_vecs = %w(first other output).map {|v| "#{ctype} *#{v}_vec = #{v}->ptr;\n"}.join
        get_ptr = "#{ctype} *vec_ptr = vec->ptr;\n"
        extend Inliner
        layout :size, :int,  # total number of elements
          :dtype, :int,      # the data type
          :ptr, :pointer
        # right now just working for one dimension

        inline do |build|
          build.include 'sys/types.h'
          build.map "vec_struct_#{dtp} *" => 'pointer'
          build.c_raw %Q{
            typedef struct {
              int size;
              int dtype;
            #{ctype} *ptr;   
            } vec_struct_#{dtp};
          }

          build.c %Q{
            #{BIGGER[dtp]} c_sum(vec_struct_#{dtp} *vec) {
              #{get_ptr}
              #{BIGGER[dtp]} sum = #{ZERO[dtp]};
              int i;
              for (i=0; i < vec->size; ++i) {
                sum += vec_ptr[i];
              }
              return sum;
            }
          }
          build.c %Q{
            #{ctype} get(vec_struct_#{dtp} *vec, int index) {
                return vec->ptr[index];
              }
          }
          build.c %Q{
            #{ctype} set(vec_struct_#{dtp} *vec, int index, #{ctype} value) {
              vec->ptr[index] = value;
              return value;
            }
          }

          
          OPERATIONS.each do |op_name,operator|
            build.c %Q{
              void c_#{op_name}(vec_struct_#{dtp} *first, vec_struct_#{dtp} *other, vec_struct_#{dtp} *output) {
                int i;
                #{first_other_output_vecs}
                for (i=0; i < first->size; ++i) {
                  output_vec[i] = first_vec[i] #{operator} other_vec[i];
                }
              }
            }
          end

        end
      end

    end

    attr_reader :struct

    ##########################################################
    # INITIALIZATION
    ##########################################################
    # requires a symbol datatype
    def initialize(datatype, lngth, array=nil)
      @struct = Numrb::Vec.const_get("Struct_#{datatype}").new
      @struct[:dtype] = TYPES_AR.index(datatype)
      @struct[:size] = lngth
      @struct[:ptr] = Numrb::Vec::Data.new(lngth, STRIDES[datatype])
      if array
        @struct[:ptr].send("put_array_of_#{datatype}", 0, array)
      end
    end

    def self.[](*args)
      self.to_nr(args) 
    end

    def self.to_nr(array)
      self.new(Util.array_type(array), array.size, array)
    end

    ##########################################################
    # METHODS
    ##########################################################
    def dtype
      TYPES_AR[@struct[:dtype]]
    end

    def size ; @struct[:size] end
    alias_method :length, :size

    # this will be slow compared to array access
    def [](index)
      # this pure ruby call is 6X slower than doing the C call
      # of course, this is a *really* indirect method call
      #@struct[:ptr].send("get_#{dtype}".to_sym, index*STRIDES[dtype])
      @struct.get(@struct, index)
    end

    # this will be slow compared to array access
    def []=(index, val)
      #@struct[:ptr].send("put_#{dtype}".to_sym, index*STRIDES[dtype], val)
      @struct.set(@struct, index, val)
    end

    def sum
      @struct.c_sum(@struct)
    end

    def to_a
      @struct[:ptr].send("get_array_of_#{dtype}", 0, @struct[:size])
    end



    ##########################################################
    # MATH
    ##########################################################

    OPERATIONS.each do |name, operator|
      define_method(operator.to_sym) do |other|
        output = self.class.new(self.dtype, self.size)
        @struct.send("c_#{name}".to_sym, self.struct, other.struct, output.struct)
        output
      end
    end

    module Util
      # scans the array and returns the highest common type as an integer
      def self.array_type(array)
        if array.any? {|v| v.is_a?(Float) }
          :double
        else
          :long_long
        end
      end

    end
  end
end




