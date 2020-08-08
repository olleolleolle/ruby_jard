# frozen_string_literal: true

module RubyJard
  ##
  # Override Pry's pager system. Again, Pry doesn't support customizing pager. So...
  class Pager
    def initialize(pry_instance)
      @pry_instance = pry_instance
    end

    def page(text)
      open do |pager|
        pager << text
      end
    end

    def open(options = {})
      pager = LessPager.new(@pry_instance.output, **options)
      yield pager
    rescue Pry::Pager::StopPaging
      # Ignore
    ensure
      pager.close
      prompt = @pry_instance.prompt.wait_proc.call
      @pry_instance.output.puts "#{prompt}Tips: You can use `list` command to show back debugger screens"
    end

    private

    def enabled?
      !!@enabled
    end

    ##
    # Pager using GNU Less
    class LessPager < Pry::Pager::NullPager
      def initialize(out, force_open: false, pager_start_at_the_end: false)
        super(out)
        @buffer = ''

        @pager_start_at_the_end = pager_start_at_the_end

        @tracker = Pry::Pager::PageTracker.new(height, width)
        @pager = force_open ? open_pager : nil
      end

      def write(str)
        if invoked_pager?
          @pager.write str
        else
          @tracker.record str
          @buffer += str
          if @tracker.page?
            @pager = open_pager
            @pager.write(str)
          end
        end
      rescue Errno::EPIPE
        raise Pry::Pager::StopPaging
      end

      def close
        if invoked_pager?
          @pager.close
        else
          @out.write @buffer
        end
      end

      def invoked_pager?
        @pager
      end

      def open_pager
        less_command = ['less', '-R', '-X', '-F', '-J']
        less_command << '+G' if @pager_start_at_the_end
        IO.popen(less_command.join(' '), 'w')
      end
    end
  end
end
