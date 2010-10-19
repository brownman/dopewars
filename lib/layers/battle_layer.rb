
class BattleLayer < AbstractLayer
  include Rubygame
  include Rubygame::Events

  extend Forwardable
  def_delegators :@battle, :participants, :current_battle_participant_offset
  def_delegators :@game, :inventory
  attr_reader :battle
  include EventHandler::HasEventHandler
  def initialize(screen, game)
    super(screen, screen.w - 50, screen.h - 50)
    @layer.fill(:orange)
    @text_rendering_helper = TextRenderingHelper.new(@layer, @font)
    @battle = nil
    @menu_helper = nil
    @game = game
    @battle_hud = BattleHud.new(@screen, @text_rendering_helper, @layer)
    sections = [MenuSection.new("Exp",[EndBattleMenuAction.new("Confirm", self)]),
      MenuSection.new("Items", [EndBattleMenuAction.new("Confirm", self)])]
    @end_of_battle_menu_helper = MenuHelper.new(screen, @layer, @text_rendering_helper, sections, @@MENU_LINE_SPACING,@@MENU_LINE_SPACING)
    make_magic_hooks({ClockTicked => :update})
  end
  def update( event )
    return unless @battle and !@battle.over?
    dt = event.seconds # Time since last update
    @battle.accumulate_readiness(dt)
  end
  def start_battle(game, universe, player, monster)
    @active = true
    @battle = Battle.new(game, universe, player, monster, self)

    @menu_helper = BattleMenuHelper.new(@battle, @screen, @layer, @text_rendering_helper, [], @@MENU_LINE_SPACING,@@MENU_LINE_SPACING)

    sections = player.party.collect {|hero|  HeroMenuSection.new(hero, [AttackMenuAction.new("Attack", self, @menu_helper), ItemMenuAction.new("Item", self, @menu_helper, @game)])}
    @menu_helper.replace_sections(sections)
  end
  def end_battle
    @active = false
    @battle.end_battle
  end
  def menu_layer_config

    mlc = MenuLayerConfig.new
    mlc.main_menu_text = TextRenderingConfig.new(@@MENU_TEXT_INSET, @@MENU_TEXT_WIDTH, @layer.h - 125, 0)
    mlc.section_menu_text = TextRenderingConfig.new(@@MENU_TEXT_INSET, @@MENU_TEXT_WIDTH, @layer.h - 150, 0)
    mlc.in_section_cursor = TextRenderingConfig.new(@@MENU_TEXT_INSET , @@MENU_TEXT_WIDTH, @layer.h - 175, 0)
    mlc.in_subsection_cursor = BattleParticipantCursorTextRenderingConfig.new([AttackMenuAction], 2 * @@MENU_TEXT_INSET + 4*@@MENU_TEXT_WIDTH, 0, @@MENU_TEXT_INSET, @@MENU_LINE_SPACING)
    mlc.in_option_section_cursor = BattleParticipantCursorTextRenderingConfig.new([ItemMenuAction], 2 * @@MENU_TEXT_INSET + 4*@@MENU_TEXT_WIDTH, 0, @@MENU_TEXT_INSET, @@MENU_LINE_SPACING)
    mlc.main_cursor = TextRenderingConfig.new(@@MENU_TEXT_INSET , @@MENU_TEXT_WIDTH, @layer.h - 100, 0)
    mlc.layer_inset_on_screen = [@@LAYER_INSET,@@LAYER_INSET]
    mlc.details_inset_on_layer = [@@MENU_DETAILS_INSET_X, @@MENU_DETAILS_INSET_Y]
    mlc.options_inset_on_layer = [@@MENU_OPTIONS_INSET_X, @@MENU_OPTIONS_INSET_Y]

    mlc
  end
  def end_battle_menu_layer_config

    mlc = MenuLayerConfig.new
    mlc.main_menu_text = TextRenderingConfig.new(@@MENU_TEXT_INSET, @@MENU_TEXT_WIDTH, 50, 0)
    mlc.section_menu_text = TextRenderingConfig.new(@@MENU_TEXT_INSET, @@MENU_TEXT_WIDTH, 150, 0)
    mlc.in_section_cursor = TextRenderingConfig.new(@@MENU_TEXT_INSET , @@MENU_TEXT_WIDTH,200, 0)
    mlc.main_cursor = TextRenderingConfig.new(@@MENU_TEXT_INSET , @@MENU_TEXT_WIDTH,100, 0)
    mlc.layer_inset_on_screen = [@@LAYER_INSET,@@LAYER_INSET]
    mlc
  end
  def draw()
    @layer.fill(:orange)
    if @battle.over?
      if @battle.player_alive?
        @end_of_battle_menu_helper.draw(end_battle_menu_layer_config, @game)
      else
        puts "you died ... game should be over... whatever"
        @end_of_battle_menu_helper.draw(end_battle_menu_layer_config, @game)
      end
    else
      @battle.monster.draw_to(@layer)
      @menu_helper.draw(menu_layer_config, @game)
      @battle_hud.draw(menu_layer_config, @game, @battle)
    end
  end

  def enter_current_cursor_location(game)
    if @battle.over?
      @end_of_battle_menu_helper.enter_current_cursor_location(game)
    else
      @menu_helper.enter_current_cursor_location(game)
    end
  end

  def move_cursor_down
    send_action_to_target(:move_cursor_down)
  end
  def move_cursor_up
    send_action_to_target(:move_cursor_up)
  end

  def cancel_action
    send_action_to_target(:cancel_action)
  end

  def send_action_to_target(sym)
    target = @battle.over? ? @end_of_battle_menu_helper : @menu_helper
    target.send(sym)
  end
end