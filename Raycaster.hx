package voxel;

import openfl.geom.Vector3D;

/**
 * Result of a raycast: the hit block's world coords, and the face that was
 * hit (needed so "place block" knows to place adjacent to that face, not
 * inside the hit block itself).
 */
class RayHit
{
	public var bx:Int;
	public var by:Int;
	public var bz:Int;
	public var face:Int; // 0=top 1=bottom 2=north 3=south 4=east 5=west
	public function new(bx:Int, by:Int, bz:Int, face:Int)
	{
		this.bx = bx; this.by = by; this.bz = bz; this.face = face;
	}
}

class Raycaster
{
	// Small-step marching raycast: simple and reliable at these ranges
	// (max 6 blocks), avoids the edge cases of a full DDA/voxel-traversal
	// implementation for this scale of project.
	static inline var STEP:Float = 0.02;
	static inline var MAX_DIST:Float = 6.0;

	public static function cast(world:World, originX:Float, originY:Float, originZ:Float, dir:Vector3D):Null<RayHit>
	{
		var lastAirX = Math.floor(originX);
		var lastAirY = Math.floor(originY);
		var lastAirZ = Math.floor(originZ);

		var t = 0.0;
		while (t < MAX_DIST)
		{
			var px = originX + dir.x * t;
			var py = originY + dir.y * t;
			var pz = originZ + dir.z * t;

			var bx = Math.floor(px);
			var by = Math.floor(py);
			var bz = Math.floor(pz);

			var id = world.getBlockWorld(Std.int(bx), Std.int(by), Std.int(bz));
			if (Block.isSolid(id))
			{
				// Determine which face was entered by comparing to the last
				// known air-space cell: the axis that changed between
				// lastAir and this hit is the face we crossed through.
				var face = faceFromDelta(Std.int(lastAirX), Std.int(lastAirY), Std.int(lastAirZ), Std.int(bx), Std.int(by), Std.int(bz));
				return new RayHit(Std.int(bx), Std.int(by), Std.int(bz), face);
			}

			lastAirX = bx; lastAirY = by; lastAirZ = bz;
			t += STEP;
		}

		return null;
	}

	/**
	 * Returns which face of the HIT block the ray crossed to get inside it.
	 * This is the face on the side the ray approached FROM -- e.g. a ray
	 * traveling east (+X) that steps from air at x=4 into a solid block at
	 * x=5 crossed that block's WEST face (its -X side, facing back toward
	 * the ray's origin). Verified against all 6 travel directions.
	 */
	static function faceFromDelta(ax:Int, ay:Int, az:Int, bx:Int, by:Int, bz:Int):Int
	{
		if (bx > ax) return 5; // traveling +X: hit block's west face faces the ray
		if (bx < ax) return 4; // traveling -X: hit block's east face faces the ray
		if (by > ay) return 1; // traveling +Y: hit block's bottom face faces the ray
		if (by < ay) return 0; // traveling -Y: hit block's top face faces the ray
		if (bz > az) return 2; // traveling +Z: hit block's north face faces the ray
		if (bz < az) return 3; // traveling -Z: hit block's south face faces the ray
		return 0; // degenerate (origin already inside a block); default top
	}
}
