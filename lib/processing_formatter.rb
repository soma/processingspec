require 'rubygems'
require 'ruby-processing'
require 'spec/runner/formatter/base_formatter'

module Processing ; SKETCH_PATH = __FILE__ ; end

class SpecSketch < Processing::App
  attr_reader :number_of_examples
  load_libraries 'boids', 'opengl'
  import "processing.opengl" if library_loaded? "opengl"
  full_screen

  SpecFlock = Struct.new(:flocks, :color, :n, :flee)

  def setup
    library_loaded?(:opengl) ? setup_opengl : render_mode(P3D)
    sphere_detail 8
    color_mode RGB, 1.0
    no_stroke
    frame_rate 30
    shininess 1.0
    specular 0.3, 0.1, 0.1
    emissive 0.03, 0.03, 0.1

    reset_number_of_examples!(0)
  end
  
  def reset_number_of_examples!(num)
    @number_of_examples = num
    @flocks = {
      :passed => SpecFlock.new([Boids.flock(20, 0, 0, width, height)], color(0,255,0), 0, false),
      :failed => SpecFlock.new([Boids.flock(20, 0, 0, width, height)], color(255,0,0), 0, false),
      :pending => SpecFlock.new([Boids.flock(20, 0, 0, width, height)], color(255,255,0), 0, false)
    }
    @flocks.values.each do |sf|
      sf.flocks.each{|f|f.goal(width/2, height/2, 0); f.scatter(0)}
    end
  end

  def add_result!(result)
    @flocks.values.each {|f|f.flee = false}
    @flocks[result].n += 1
    @flocks[result].flee = true

    if @flocks[result].n % 20 == 0
      @flocks[result].flocks << Boids.flock(20, 0, 0, width, height)
    end

    @flocks.values.each do |sf|
      sf.flocks.each{|f|f.goal(width/2, height/2, 0); f.scatter(0)}
    end
    
  end

  def setup_opengl
    render_mode(OPENGL)
    hint ENABLE_OPENGL_4X_SMOOTH
  end

  def draw
    background 0.05
    ambient_light 0.01, 0.01, 0.01
    light_specular 0.4, 0.2, 0.2
    point_light 1.0, 1.0, 1.0, mouse_x, mouse_y, 190

    @flocks.values.each_with_index do |sflock, i|
      sflock.flocks.each do |flock|
        flock.goal mouse_x, mouse_y, 0, sflock.flee
        flock.update(:goal => 185, :limit => 13.5)
        flock.each do |boid|
          r = 20 + (boid.z * 0.15)
          alpha = (boid.z * 0.01) + sflock.n / @number_of_examples.to_f
          fill(sflock.color)
          push_matrix
          translate boid.x-r/2, boid.y-r/2, boid.z-r/2
          oval(0, 0, r, r)
          pop_matrix
        end
      end
    end
  end
end

class ProcessingFormatter < Spec::Runner::Formatter::BaseFormatter
  def initialize(options, output)
    @sketch = SpecSketch.new(:width => 800, :height => 800, :title => "Spec Sketch")
  end

  def start(example_count)
    @sketch.reset_number_of_examples!(example_count)
  end

  def example_group_started(example_group_proxy)
  end

  def example_started(example_proxy)
    sleep 0.1
  end

  def example_passed(example_proxy)
    @sketch.add_result! :passed
  end

  def example_failed(example_proxy, counter, failure)
    @sketch.add_result! :failed
  end

  def example_pending(example_proxy, message, deprecated_pending_location=nil)
    @sketch.add_result! :pending
  end

  def close
    @sketch.close
  end
end
