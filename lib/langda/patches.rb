module Langda
  #########################################################
  # BASE LOOP PATCH (Shared logic)
  #########################################################
  module BaseLoopPatch
    def _safe_loop(kind, args, block)
      return yield unless Langda.enabled? && block

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      count = 0

      begin
        inner = proc do |*yield_args|
          count += 1
          block.call(*yield_args)
        end

        result = yield(inner)
        _langda_log(kind, count, start)
        result

      rescue => e
        Langda::Log.warn("Langda fallback for #{kind}: #{e.class} #{e.message}")
        super(*args, &block) # correct fallback
      end
    end

    def _langda_log(kind, count, start)
      ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000
      return unless ms > Langda.threshold_ms

      Langda::Log.warn("#{kind} → #{count} iterations → #{ms.round(3)} ms")
    end
  end



  #########################################################
  # ARRAY PATCH
  #########################################################
  module ArrayPatch
    include BaseLoopPatch

    def each(*args, &block)
      _safe_loop(:each, args, block) { |inner| super(*args, &inner) }
    end
  end



  #########################################################
  # ENUMERABLE PATCH
  #########################################################
  module EnumerablePatch
    include BaseLoopPatch

    def map(*args, &block)
      _safe_loop(:map, args, block) { |inner| super(*args, &inner) }
    end

    def select(*args, &block)
      _safe_loop(:select, args, block) { |inner| super(*args, &inner) }
    end

    def reject(*args, &block)
      _safe_loop(:reject, args, block) { |inner| super(*args, &inner) }
    end

    def each_with_index(*args, &block)
      _safe_loop(:each_with_index, args, block) { |inner| super(*args, &inner) }
    end

    def each_with_object(obj, &block)
      _safe_loop(:each_with_object, [obj], block) { |inner| super(obj, &inner) }
    end
  end



  #########################################################
  # INTEGER PATCH
  #########################################################
  module IntegerPatch
    include BaseLoopPatch

    def times(&block)
      _safe_loop(:times, [], block) { |inner| super(&inner) }
    end

    def upto(limit, &block)
      _safe_loop(:upto, [limit], block) { |inner| super(limit, &inner) }
    end

    def downto(limit, &block)
      _safe_loop(:downto, [limit], block) { |inner| super(limit, &inner) }
    end

    # FIXED: supports any arity
    def step(*args, &block)
      _safe_loop(:step, args, block) { |inner| super(*args, &inner) }
    end
  end



  #########################################################
  # ENUMERATOR PATCH
  #########################################################
  module EnumeratorPatch
    include BaseLoopPatch

    def each(*args, &block)
      _safe_loop(:each, args, block) { |inner| super(*args, &inner) }
    end
  end



  #########################################################
  # RANGE PATCH
  #########################################################
  module RangePatch
    include BaseLoopPatch

    def each(*args, &block)
      _safe_loop(:each, args, block) { |inner| super(*args, &inner) }
    end
  end
end



#########################################################
# APPLY PATCHES
#########################################################

Array.prepend(Langda::ArrayPatch)
Hash.prepend(Langda::EnumerablePatch)
Enumerable.prepend(Langda::EnumerablePatch)
Integer.prepend(Langda::IntegerPatch)
Enumerator.prepend(Langda::EnumeratorPatch)
Range.prepend(Langda::RangePatch)
