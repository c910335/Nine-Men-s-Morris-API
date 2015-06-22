module Morris
   module Helpers
      class Game
         attr_accessor :title, :token, :host, :attendee, :attend_ability
         def initialize title, com, host_name
            @title = title
            @com = com
            @host = {:name => host_name, :token => SecureRandom.hex}
            @attendee = nil
            @token = SecureRandom.hex
            @attend_ability = !com
         end

         def attend name
            @attend_ability = false
            @attendee = {:name => name, :token => SecureRandom.hex}
         end

         def to_hash
            hash = {
               :title => @title,
               :token => @token,
               :host => {:name => @host[:name]}
            }
            hash[:attendee] = {:name => @attendee[:name]} unless @attendee.nil?
            hash[:attend_ability] = @attend_ability
            hash
         end
      end

      def new_game title, com, host_name
         Game.new title, com, host_name
      end
   end
end
