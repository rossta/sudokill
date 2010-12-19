module Sudocoup
  class Controller
    attr_accessor :game, :queue, :max_time, :channel
    def initialize(opts = {})
      @opts = opts
      initialize_game

      @queue  = []
      @max_time = (opts[:max_time]).to_i if opts[:max_time]
    end

    def players
      @game.players
    end

    def close
      players.map(&:close)
      queue.map(&:close)
    end

    def broadcast(msg, name = nil)
      return if @channel.nil?
      msg = "#{name}: #{msg}" unless name.nil?
      @channel.push msg
    end

    def send_players(msg)
      players.each { |player| player.send_command(msg) }
    end

    def time_left?(player = game.current_player)
      player.time_left?(max_time)
    end

    def call(command, opts = {})
      command_class = self.class.const_get "#{command.to_s.split("_").map(&:capitalize).join}Command"
      command_class.call(self, opts)
    end

    def time_check
      # TODO test
      if game.in_progress?
        if !time_left?
          call :end_game, :msg => game.times_up_violation(game.current_player)
        end
        broadcast(PlayerJSON.to_json(players, max_time)) if players.any?
      end
    end

    def initialize_game
      @game = Game.new(:size => @opts[:size], :file => @opts[:file])
    end

    protected

    def defer(&block)
      deferable = EM::DefaultDeferrable.new
      deferable.callback &block
      deferable.succeed
    end

    class Command
      attr_reader :controller
      def initialize(controller, opts = {})
        @controller = controller
        opts.each do |k,v|
          self.instance_variable_set("@#{k}", v)  ## create and initialize an instance variable for this key/value pair
          self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})  ## create the getter that returns the instance variable
        end
      end

      def self.call(controller, opts = {})
        new(controller, opts).call
      end

      def delegate_call(*args)
        controller.call(*args)
      end

      def self.delegate_to_controller(*methods)
        methods.each do |method|
          method_s = method.to_s
          class_eval <<-SRC
            def #{method_s}(*args)
              controller.#{method_s}(*args)
            end
          SRC
        end
      end
      delegate_to_controller :game, :broadcast, :queue, :players, :max_time, :send_players, :call

      def defer(&block)
        deferable = EM::DefaultDeferrable.new
        deferable.callback &block
        deferable.succeed
      end
    end

    class JoinGameCommand < Command
      def call
        joined = game.join_game(player)
        if joined
          player.reset
          player.send_command "READY"
          broadcast("Ready to begin", SUDOKOUP) if game.ready?
        end
        joined
      end
    end

    class JoinQueueCommand < Command
      def call
        queue << player
        player.send_command "WAIT"
      end
    end

    class NewVisitorCommand < Command
      def call
        visitor.send StatusJSON.to_json(game.sudocoup_state, "Welcome to Sudocoup, #{visitor.name}")
        visitor.send BoardJSON.to_json(game.board)
        visitor.send PlayerJSON.to_json(players, max_time)
        visitor.send QueueJSON.to_json(players)
        msg = "#{visitor.name} just joined the game room"
        broadcast msg, SUDOKOUP
        log msg, SUDOKOUP
      end
    end

    class NewPlayerCommand < Command
      def call
        if game.available?
          delegate_call :join_game, :player => player
        else
          delegate_call :join_queue, :player => player
        end
      end
    end

    class RemoveVisitorCommand < Command
      def call
        visitor.send "Bye!"
        msg = "#{visitor.name} just left the game room"
        broadcast msg, SUDOKOUP
        log msg, SUDOKOUP
      end
    end

    class RemovePlayerCommand < Command
      def call
        if game.players.delete(player)
          case game.sudocoup_state
          when :in_progress
            delegate_call :end_game, :msg => "#{player.name} left the game"
            return
          when :waiting, :ready
            game.waiting!        if game.ready?
            AddPlayerFromQueueCommand.call(controller) if queue.any?
          end
          broadcast "#{player.name} left the game", SUDOKOUP
        elsif queue.delete(player)
          broadcast("#{player.name} left the On Deck circle", SUDOKOUP)
        end
        broadcast PlayerJSON.to_json(players, max_time)
        broadcast QueueJSON.to_json(players)
        log "#{player.name} disconnected", SUDOKOUP
      end
    end

    class AnnouncePlayerCommand < Command
      def call
        if game.has_player? player
          broadcast("#{player.name} is now in the game", SUDOKOUP)
        elsif queue.include? player
          broadcast("#{player.name} is now waiting On Deck", SUDOKOUP)
        end
        broadcast PlayerJSON.to_json(players, max_time)
        broadcast QueueJSON.to_json(players)
      end
    end

    class AddPlayerFromQueueCommand < Command
      def call
        player = queue.shift
        JoinGameCommand.call(controller, :player => player)
        AnnouncePlayerCommand.call(controller, :player => player)
      end
    end

    class EndGameCommand < Command
      def call
        game.over!
        send_players MessagePipe.game_over(msg)
        broadcast msg
        broadcast StatusJSON.to_json(game.sudocoup_state, msg)
        NewGameCommand.call(controller)
      end
    end

    class NewGameCommand < Command
      def call
        controller.initialize_game
        while game.available? && queue.any?
          AddPlayerFromQueueCommand.call(controller)
        end
      end
    end

    class RequestAddMoveCommand < Command
      def call
        # TODO test
        status, msg = game.add_player_move(player, move)
        played_move = Move.build(move, player.number)
        case status
        when :ok
          broadcast MoveJSON.to_json(played_move, status.to_s)
          broadcast msg, SUDOKOUP
          send_players(move)
          # sleep 1.0
          delegate_call :request_next_player_move
        when :reject
          player.send_command MessagePipe.reject(msg)
          broadcast msg, SUDOKOUP
        when :violation
          broadcast MoveJSON.to_json(played_move, status.to_s)
          EndGameCommand.call(controller, msg)
        end
      end
    end

    class RequestNextPlayerMoveCommand < Command
      def call
        # TODO test
        defer do
          game.next_player_request do |player|
            player.send_command MessagePipe.add_move(game)
          end
          broadcast StatusJSON.to_json(game.sudocoup_state, "#{game.current_player.name}'s turn!")
        end

      end
    end

    class StopGameCommand < Command
      def call
        # TODO test
        defer do
          if game.in_progress?
            delegate_call :end_game, :msg => "Game stopped!"
          else
            broadcast StatusJSON.to_json(game.sudocoup_state, game.status)
          end
        end
      end
    end

    class PlayGameCommand < Command
      def call
        defer do
          if game.players.any? && game.ready?
            broadcast BoardJSON.to_json(game.board)
            broadcast StatusJSON.to_json(game.sudocoup_state, "New game about to begin!")
            game.play! do |player|
              player.send_command MessagePipe.start(player, game)
            end
            delegate_call :request_next_player_move
          else
            broadcast StatusJSON.to_json(game.sudocoup_state, game.status)
          end
        end
      end
    end

    class ConnectOpponentCommand < Command
      def call
        defer do
          player_name = "#{name}#{rand(100)}"
          case name.downcase.to_sym
          when :naive
            EM.connect(@host, @port, Player::Naive, :name => name)
          when :easy, :medium, :hard
            pid = fork do
              system("cd bin/Vincent/; java Sudokill_#{name} #{host_name(@host)} #{@port} #{player_name}")
            end
          when :angjoo
            pid = fork do
              system("cd bin/Angjoo/; java -jar angjooPlayer.jar #{host_name(@host)} #{@port} #{player_name}")
            end
          when :simon
            pid = fork do
              system("cd bin/Simon/; java Main")
            end
          else
            visitor.send("Didn't recognize opponent, #{name}")
          end
          Process.detach pid unless pid.nil?
          pid
        end
      end
    end

  end
end