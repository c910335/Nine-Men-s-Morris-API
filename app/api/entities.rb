module Morris
   module Entities
      class BaseGame < Grape::Entity
         expose :title, documentation: {type: 'string', desc: 'Title of the game', required: true}
         expose :token, documentation: {type: 'string', desc: 'Token of the game', required: true}
      end

      class Name < Grape::Entity
         expose :name, documentation: {type: 'string', desc: 'Name of the player'}
      end

      class NewGame < BaseGame
         expose :player_token, documentation: {type: 'string', desc: 'Token of the player', required: true}
      end

      class LeftMen < Grape::Entity
         expose '1', documentation: {type: 'string', desc: 'Left men of host', required: true}
         expose '2', documentation: {type: 'string', desc: 'Left men of attendee', required: true} 
      end

      class Man < Grape::Entity
         expose :x, documentation: {type: 'integer', desc: 'X coordinate', required: true}
         expose :y, documentation: {type: 'integer', desc: 'Y coordinate', required: true}
         expose :z, documentation: {type: 'integer', desc: 'Status code of the man', required: true}
      end

      class Game < BaseGame
         expose :host, using: Name, documentation: {required: true, desc: 'Host Player'}
         expose :attendee, using: Name, documentation: {desc: 'Attendee player'}
         expose :attend_ability, documentation: {type: 'boolean', desc: 'True if there is no attendee yet', required: true}
      end

      class PrivateGame < Game
         expose :attendee, using: Name, documentation: {desc: 'Attendee player', required: true}
         expose :status, documentation: {type: 'integer', desc: 'Status code', required: true}
         expose :board, documentation: {type: 'integer', is_array: true, desc: '3x9 Board', required: true}
         expose :mover, documentation: {type: 'integer', desc: 'Mover\'s player code', required: true}
         expose :to_place, using: LeftMen, documentation: {desc: 'Men which is not placed yet', required: true}
         expose :on_board, using: LeftMen, documentation: {desc: 'Men on board', required: true}
         expose :man_to_move, using: Man, documentation: {desc: 'Man selected', required: true}
      end

      class GameList < Grape::Entity
         expose :list, using: Game, documentation: {is_array: true, desc: 'List of all games', required: true}
      end

      class MyTurn < Grape::Entity
         expose :my_turn, documentation: {type: 'boolean', desc: 'True if it\'s your turn', required: true}
      end

      class Result < Grape::Entity
         expose :next_status,  documentation: {type: 'integer', desc: 'Next status code', required: true}
         expose :take_turn, documentation: {type: 'boolean', desc: 'True if it need to take turn', required: true}
         expose :changes, using: Man, documentation: {is_array: true, desc: 'Men which should be change'}
         expose :change_num, documentation: {type: 'integer', desc: 'Length of changes'}
         expose :winner, documentation: {type: 'integer', desc: 'Player code of winner'}
      end

   end
end
