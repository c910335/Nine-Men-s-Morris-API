module Morris
   module Entities
      class BaseGame < Grape::Entity
         expose :title, documentation: {type: 'string', desc: 'Title of the game.', required: true}
         expose :token, documentation: {type: 'string', desc: 'Token of the game.', required: true}
      end

      class NewGame < BaseGame
         expose :player_token, documentation: {type: 'string', desc: 'Token of the player.', required: true}
      end

      class HostName < Grape::Entity
         expose :name, documentation: {type: 'string', desc: 'Name of the host.', required: true}
      end

      class AttendeeName < Grape::Entity
         expose :name, documentation: {type: 'string', desc: 'Name of the attendee.'}
      end

      class StatusGame < BaseGame
         expose :host, using: HostName, documentation: {required: true}
         expose :attendee, using: AttendeeName, documentation: {is_array: false}
         expose :attend_ability, documentation: {type: 'boolean', desc: 'True if there is no attendee yet.', required: true}
      end

      class GameList < Grape::Entity
         expose :list, using: StatusGame, documentation: {is_array: true, required: true}
      end
   end
end
