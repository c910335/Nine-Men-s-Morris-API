module Morris
   module Core
      class Game
         include Morris::Code::Status
         include Morris::Code::Man

         ERROR = 0
         OK = 1

         LAYER_BESIDE_LIST = [[1, 3],[ 0, 2], [1, 5], [0, 6], [-1, -1], [2, 8], [3, 7], [6, 8], [5, 7]]
         LAYER_MILL_LIST = [[0, 1, 2], [6, 7, 8], [0, 3, 6], [2, 5, 8]]

         attr_accessor :status, :board

         def init_game
            @status = PLACING
            @board = Array.new(3) { Array.new 9, NONE }
            @board.each { |layer| layer[4] = INVALID }
            @mover = ATTENDEE
            @waiter = HOST
            @to_place = { HOST => 9, ATTENDEE => 9}
            @on_board = { HOST => 0, ATTENDEE => 0}
            @man_to_move = nil
            @winner = nil
            self
         end

         def click x, y
            return {:code => ERROR, :error_massage => 'Out of board.', :http_code => 400} unless (0...3).include?(x) && (0...9).  include?(y)
            case @status
            when PLACING
               result = place x, y
            when PLACE_EATING
               result = eat x, y
               if result[:take_turn]
                  unless @to_place[HOST] > 0 || @to_place[ATTENDEE] > 0
                     result[:next_status] = MOVE_SELECTING
                  else
                     result[:next_status] = PLACING
                  end
               end
            when MOVE_SELECTING
               result = select x, y
            when MOVING
               result = move x, y
            when MOVE_EATING
               result = eat x, y
               result[:next_status] = MOVE_SELECTING if result[:take_turn]
            when OVER
               return {:code => ERROR, :error_message => 'This game is already over.', :http_code => 410}
            end
            if result[:code] == OK
               if result[:take_turn]
                  if win
                     result[:next_status] = OVER
                     result[:winner] = @mover
                     result[:take_turn] = false
                     @winner = @mover
                  else
                     take_turn
                  end
               end
               @status = result[:next_status]
            else
               result[:http_code] = 400
            end
            result
         end

         def place x, y
            return {:code => ERROR, :error_message => 'This man can\'t place here.'} if @board[x][y] != NONE
            result = {
               :code => OK,
               :changes => [{:x => x, :y => y, :z => @mover}],
               :change_num => 1
            }
            @board[x][y] = @mover
            @to_place[@mover] -= 1
            @on_board[@mover] += 1
            if mill?(x, y, @mover) && !all_mill?(@waiter)
               result.merge!({
                  :next_status => PLACE_EATING,
                  :take_turn => false
               })
            elsif @to_place[HOST] == 0 && @to_place[ATTENDEE] == 0
               result.merge!({
                  :next_status => MOVE_SELECTING,
                  :take_turn => true
               })
            else
               result.merge!({
                  :next_status => PLACING,
                  :take_turn => true
               })
            end
            result
         end

         def move x, y
            return select x, y if @board[x][y] == @mover
            return {:code => ERROR, :error_message => 'This man can\'t move here.'} unless @board[x][y] == NONE && beside(@man_to_move, {:x => x, :y => y})
            @man_to_move[:z] = NONE
            result = {
               :code => OK,
               :changes => [{:x => x, :y => y, :z => @mover}, @man_to_move],
               :change_num => 2
            }
            @board[x][y] = @mover
            @board[@man_to_move[:x]][@man_to_move[:y]] = NONE
            @man_to_move = nil
            if mill?(x, y, @mover) && !all_mill?(@waiter)
               result.merge!({
                  :next_status => MOVE_EATING,
                  :take_turn => false
               })
            else
               result.merge!({
                  :next_status => MOVE_SELECTING,
                  :take_turn => true
               })
            end
            result
         end

         def select x, y
            return {:code => ERROR, :error_message => 'This is not your man.'} unless @board[x][y] == @mover
            return {:code => ERROR, :error_message => 'This man can\'t move.'} unless can_move? x, y
            @man_to_move = {:x => x, :y => y, :z => @mover}
            {:code => OK, :take_turn => false, :next_status => MOVING}
         end

         def eat x, y
            return {:code => ERROR, :error_message => 'This is not your opponent\'s man.'} unless @board[x][y] == @waiter
            return {:code => ERROR, :error_message => 'You can\'t remove a man from a mill.'} if mill? x, y, @waiter
            @board[x][y] = NONE
            @on_board[@waiter] -= 1
            {:code => OK,
             :changes => [{:x => x, :y => y, :z => NONE}],
             :change_num => 1,
             :take_turn => true}
         end

         def win
            return false if @to_place[HOST] > 0 || @to_place[ATTENDEE] > 0
            return true if @on_board[@waiter] < 3 || !all_can_move?(@waiter)
            false
         end

         def beside man1, man2 
            return false if man1.nil? || man2.nil?
            return true if man1[:x] == man2[:x] && LAYER_BESIDE_LIST[man1[:y]].include?(man2[:y])
            return true if [1, 3, 5, 7].include?(man1[:y]) && man1[:y] == man2[:y] && (man1[:x] - man2[:x]).abs == 1
            false
         end

         def all_can_move? which
            @board.each_index do |i|
               @board[i].each_index do |j|
                  return true if @board[i][j] == which && can_move?(i, j)
               end
            end
            false
         end

         def can_move? x, y
            beside_list(x, y).each do |x, y|
               return true if @board[x][y] == NONE
            end
            false
         end

         def beside_list x, y
            list = Array.new
            LAYER_BESIDE_LIST[y].each do |yy|
               list.push( [x, yy] )
            end
            if [1, 3, 5, 7].include? y
               (0...3).each do |xx|
                  list.push( [xx, y] ) if (xx - x).abs == 1
               end
            end
            list
         end

         def all_mill? which
            @board.each_index do |i|
               @board[i].each_index do |j|
                  return false if @board[i][j] == which && !mill?(i, j, which)
               end
            end
            true
         end

         def mill? x, y, which
            mill_list(x, y).each do |mill|
               if mill.include? [x, y]
                  flag = true
                  mill.each do |x, y|
                     if @board[x][y] != which
                        flag = false
                        break
                     end
                  end
                  return true if flag
               end
            end
            false
         end

         def mill_list x, y
            list = Array.new
            LAYER_MILL_LIST.each do |men|
               if men.include? y
                  mill = Array.new
                  men.each do |y|
                     mill.push( [x, y] )
                  end
                  list.push mill
               end
            end
            if [1, 3, 5, 7].include? y
               mill = Array.new
               (0...3).each do |x|
                  mill.push( [x, y])   
               end
               list.push mill
            end
            list
         end

         def take_turn
            @mover, @waiter = @waiter, @mover
         end

         def to_hash
            hash = {
               :status => @status,
               :board => @board,
               :mover => @mover,
               :to_place => @to_place,
               :on_board => @on_board,
               :man_to_move => @man_to_move
            }
            hash[:winner] = @winner unless @winner.nil?
            hash
         end
      end
   end
end
