module DamageControl
  module Publisher
    class Sound < Base

      ::Build::STATES.each do |state|
        attr_accessor state.attr_sym("", "sound")
      end

      # Load platform-specific sound player
      @@sound_player = File.expand_path(File.dirname(__FILE__) + "/sound/" + DamageControl::Platform.family + "/sound_player.rb")
      def self.supported?
        File.exist? @@sound_player
      end
      require @@sound_player if supported?

      # Finds all sound files.
      def self.files
        Dir["#{RAILS_ROOT}/sound/*"].collect{|f| File.basename(f)}
      end

      def initialize
        @requested_sound             = "hal_nothing.wav"
        @synching_working_copy_sound = "hal_moment.wav"
        @executing_sound             = "hal_decision.wav"
        @successful_sound            = "hal_well.wav"
        @fixed_sound                 = "hal_better.wav"
        @broken_sound                = "hal_fault.wav"
        @repeatedly_broken_sound     = "hal_error.wav"
      end

      def publish(build)
        sound = build_state_attr(build.state, "sound")
        # TODO: use DC_DATA_DIR (we must copy sounds out)
        sound_path = File.expand_path("#{RAILS_ROOT}/sound/#{sound}")
        raise "File not found: #{sound_path}" unless File.exist?(sound_path)
        SoundPlayer.play(sound_path)
      end
      
    end
  end
end
