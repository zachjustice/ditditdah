class GeoCalculations
  def self.calculate_current_position(start_time, start_point, bearing, speed_mps, max_distance_meters)
    elapsed_time_seconds = Time.now - Time.parse(start_time.to_s)
    distance_traveled_meters = elapsed_time_seconds * speed_mps

    current_position = nil
    if distance_traveled_meters < max_distance_meters
      current_position = start_point.endpoint(bearing, distance_traveled_meters)
    end

    current_position
  end

  def self.intersects?(start_line_lat, start_line_long, end_line_lat, end_line_long, point_lat, point_long)
  end

  def self.nearest_point_on_line(start_line_lat, start_line_long, end_line_lat, end_line_long, point_lat, point_long)
    # Taken from: https://groups.google.com/g/rgeo-users/c/e1FgzpPISs8

    # Create a Geos factory that uses the ffi interface
    factory = RGeo::Geos.factory(native_interface: :ffi)

    # Create your polyline and point A using that ffi-backed factory.
    # You can create the objects directly using the factory, or cast objects to the
    # factory, whatever is the easiest way for you to get objects that are attached
    # to the ffi factory.
    polyline = factory.line_string([
      factory.point(start_line_long, start_line_lat),
      factory.point(end_line_long, end_line_lat)
    ])
    point = factory.point(point_long, point_lat)

    # Objects that are attached to an ffi-geos factory provide access, via the
    # fg_geom method, to low-level objects that understand the ffi-geos api.
    # This is not really documented well, but it's a stable api that you can use.
    low_level_polyline = polyline.fg_geom
    low_level_point = point.fg_geom

    # Now invoke the low-level libgeos calls.
    # This first method, "project", gives you the distance "along" the linestring
    # where it comes closest to the given point.
    dist = low_level_polyline.project(low_level_point)
    # This second method, "interpolate", takes a distance "along" the linestring,
    # and returns the actual point on the linestring.
    low_level_closest_point = low_level_polyline.interpolate(dist)

    # Finally, wrap the low-level result in an RGeo point object
    factory.wrap_fg_geom(low_level_closest_point)
  end
end
