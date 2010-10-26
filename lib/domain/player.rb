
class Player
  include Rubygame
  include Rubygame::Events
  include Sprites::Sprite
  include EventHandler::HasEventHandler

  attr_accessor :universe, :party

  extend Forwardable

  def_delegators :@interaction_helper, :facing
  def_delegators :@animated_sprite_helper, :image, :rect
  def_delegators :@coordinate_helper, :update_tile_coords, :px, :py, :get_position
  def_delegators :@weapon_helper, :use_weapon, :using_weapon?, :draw_weapon
  def_delegators :@party, :add_readiness, :gain_experience, :gain_inventory,
    :inventory, :dead?, :inventory_info, :inventory_item_at, :world_weapon,
    :inventory_count
  def_delegators :@keys, :clear_keys
  def_delegator :@party, :add_item, :add_inventory
  def_delegator :@party, :members, :party_members

  attr_reader :filename, :hero_x_dim, :hero_y_dim
  def initialize( px, py,  universe, party, filename, hx, hy, sx, sy)
    @universe = universe
    @filename = filename
    @hero_x_dim = hx
    @hero_y_dim = hy
    @interaction_helper = InteractionHelper.new(self, @universe, InteractionPolicy.immediate_return)
    @keys = KeyHolder.new
    @coordinate_helper = CoordinateHelper.new(px, py, @keys, @universe, @hero_x_dim, @hero_y_dim)
    @animation_helper = AnimationHelper.new(@keys)
    @weapon_helper = WorldWeaponHelper.new(self, @universe)
    @animated_sprite_helper = AnimatedSpriteHelper.new(filename, sx, sy, @hero_x_dim, @hero_y_dim)
    @party = party

    make_magic_hooks(
      KeyPressed => :key_pressed,
      KeyReleased => :key_released,
      ClockTicked => :update
    )
  end

  def set_key_pressed_for(key, ticks)
    update_facing_if_key_matches(key)
    @keys.set_timed_keypress(key, ticks)
  end


  def interact_with_facing(game)
    @interaction_helper.interact_with_facing( game, @coordinate_helper.px , @coordinate_helper.py)
  end
  def set_position(px, py)
    @coordinate_helper.px = px
    @coordinate_helper.py = py
  end
  include JsonHelper
  def json_params
    [ @coordinate_helper.px, @coordinate_helper.py, @universe, @party, @filename,@hero_x_dim, @hero_y_dim, @animated_sprite_helper.px, @animated_sprite_helper.py]
  end


  private

  def update_facing_if_key_matches(newkey)
    if [:down, :left,:up, :right].include?(newkey)
      @interaction_helper.facing = newkey
      @weapon_helper.facing = newkey
    end

  end

  def key_pressed( event )
    newkey = event.key
    update_facing_if_key_matches(newkey)
    
    if event.key == :down
      @animated_sprite_helper.set_frame(0)
    elsif event.key == :left
      @animated_sprite_helper.set_frame(@hero_y_dim)
    elsif event.key == :right
      @animated_sprite_helper.set_frame(2 * @hero_y_dim)
    elsif event.key == :up
      @animated_sprite_helper.set_frame(3 * @hero_y_dim)
    end
    @animated_sprite_helper.replace_avatar(@animation_helper.current_frame)

    @keys.add_key(event.key)
  end

  def key_released( event )
    @keys.delete_key(event.key)
  end

  def update( event )
    dt = event.seconds # Time since last update
    @animation_helper.update_animation(dt) { |frame| @animated_sprite_helper.replace_avatar(frame) }
    @coordinate_helper.update_accel
    @coordinate_helper.update_vel( dt )
    @coordinate_helper.update_pos( dt )
    @weapon_helper.update_weapon_if_active
    @keys.update_timed_keys(dt)
  end

  def x_ext
    @hero_x_dim/2
  end
  def y_ext
    @hero_y_dim/2
  end

end
