
#TODO rename this to process
class ReloaderHelper
  def replace(game, json_player)
    puts "player is at #{game.player.px} and #{game.player.py} at load time"
    uni = json_player.universe
    orig_uni = game.universe
    universe = Universe.new(uni.current_world_idx, uni.worlds, orig_uni.game_layers, orig_uni.sound_effects)

    puts "universe has current world: #{universe.current_world_idx}"
    universe.replace_world_pallettes(orig_uni)
    universe.replace_world_bgsurfaces(orig_uni)
    universe.replace_world_bgmusics(orig_uni)

    universe.reblit_backgrounds
    puts "backgrounds rebuilt"
    player = Player.new(json_player.px, json_player.py,  universe, json_player.party, json_player.filename, json_player.hero_x_dim, json_player.hero_y_dim, game.screen.w/2, game.screen.h/2)
    #TODO update tile coords for player
    game.universe = universe
    game.player = player
    game.update_player_tile_coords
    game.remove_all_hooks
    game.rebuild_event_hooks
    game.universe.menu_layer.toggle_activity
    game.rebuild_hud
    game.reset_menu_positions
    puts "reloading should be done"
  end
end