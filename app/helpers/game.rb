module Morris
   module Helpers
      class Game < Morris::Core::Game

         attr_accessor :title, :token, :host, :attendee, :attend_ability, :last_click

         alias :super_to_hash :to_hash

         def initialize title, com, host_name
            @title = title
            @com = com
            @host = {:name => host_name, :token => SecureRandom.hex}
            @attendee = nil
            @token = SecureRandom.hex
            @attend_ability = !com
            @last_click = {:code => ERROR, :error_message => 'The game has not yet begun.', :http_code => 403}
         end

         def attend name
            @attend_ability = false
            @attendee = {:name => name, :token => SecureRandom.hex}
            @last_click = {:code => ERROR, :error_message => 'The game has just begun.', :take_turn => true, :http_code => 403}
            init_game
         end

         def begin?
            !@status.nil?
         end

         def over?
            return !@status.nil? && @status == OVER
         end

         def has_player? token
            return true if @host[:token] == token
            return true if !@attendee.nil? && @attendee[:token] == token
            false
         end

         def my_turn? token
            return false if @status.nil?
            return true if @host[:token] == token && @mover == HOST
            return true if @attendee[:token] == token && @mover == ATTENDEE
            false
         end

         def click x, y, token
            return {:code => ERROR, :error_message => 'It\'s not your turn now.', :http_code => 403} unless my_turn? token
            result = super x, y
            if result[:code] == OK
               if @last_click[:take_turn]
                  @last_click = result
               else
                  changes = @last_click[:changes]
                  @last_click = result
                  @last_click[:changes] = changes + @last_click[:changes]
                  @last_click[:change_num] = @last_click[:changes].length
               end
            end
            result
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

         def to_private_hash
            hash = to_hash
            hash.merge! super_to_hash unless @status.nil?
            hash
         end
      end

      def new_game title, com, host_name
         Game.new title, com, host_name
      end
   end
end
