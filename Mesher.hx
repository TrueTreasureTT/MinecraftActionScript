package voxel;

import openfl.Vector;

/**
 * Builds render geometry for a Chunk. Strategy: naive per-face culling
 * (not full greedy meshing) -- for each solid block, emit a quad for each
 * of its 6 faces ONLY if the neighbor on that side is non-solid or
 * transparent. This is the standard first-pass voxel mesher: much cheaper
 * than rendering every block as a full cube, and simple enough to trust.
 *
 * Coordinate/face conventions:
 *   +X = east, -X = west, +Y = up, -Y = down, +Z = south, -Z = north
 * Each face's 4 vertices are wound counter-clockwise when viewed from
 * OUTSIDE the cube, which is Right-Hand-Rule / OpenGL standard winding.
 * Getting this backwards makes faces invisible (backface-culled) or
 * inside-out, which is the single easiest voxel mesher bug -- so each
 * face below is spelled out explicitly rather than derived generically.
 */
class MeshData
{
	public var vertices:Vector<Float>; // x,y,z triples
	public var uvs:Vector<Float>;      // u,v pairs (0..1, into atlas)
	public var indices:Vector<Int>;
	public var quadCount:Int = 0;

	public function new()
	{
		vertices = new Vector<Float>();
		uvs = new Vector<Float>();
		indices = new Vector<Int>();
	}
}

class Mesher
{
	public static inline var ATLAS_TILES:Int = 16; // 16x16 tiles in atlas.png
	public static inline var UV_STEP:Float = 1.0 / ATLAS_TILES;
	// Small inset from each tile edge to avoid texture bleeding from the
	// neighboring tile when mipmapping/filtering samples across the border.
	static inline var UV_INSET:Float = 0.001;

	public static function build(world:World, chunk:Chunk):MeshData
	{
		var md = new MeshData();
		var wx0 = chunk.worldX();
		var wz0 = chunk.worldZ();

		for (y in 0...Chunk.H)
		{
			for (z in 0...Chunk.D)
			{
				for (x in 0...Chunk.W)
				{
					var id = chunk.get(x, y, z);
					if (id == Block.AIR) continue;

					var wx = wx0 + x;
					var wz = wz0 + z;

					// TOP (+Y)
					if (faceVisible(world, id, wx, y + 1, wz))
						emitFace(md, id, 0, wx, y, wz);
					// BOTTOM (-Y)
					if (faceVisible(world, id, wx, y - 1, wz))
						emitFace(md, id, 1, wx, y, wz);
					// NORTH (-Z)
					if (faceVisible(world, id, wx, y, wz - 1))
						emitFace(md, id, 2, wx, y, wz);
					// SOUTH (+Z)
					if (faceVisible(world, id, wx, y, wz + 1))
						emitFace(md, id, 3, wx, y, wz);
					// EAST (+X)
					if (faceVisible(world, id, wx + 1, y, wz))
						emitFace(md, id, 4, wx, y, wz);
					// WEST (-X)
					if (faceVisible(world, id, wx - 1, y, wz))
						emitFace(md, id, 5, wx, y, wz);
				}
			}
		}

		return md;
	}

	static inline function faceVisible(world:World, ownId:Int, nx:Int, ny:Int, nz:Int):Bool
	{
		var neighbor = world.getBlockWorld(nx, ny, nz);
		if (neighbor == Block.AIR) return true;
		// Transparent neighbors (leaves/water) still show the face behind
		// them UNLESS it's the exact same block type (avoids z-fighting
		// sheets of leaf-on-leaf faces rendering pointlessly).
		if (Block.isTransparent(neighbor) && neighbor != ownId) return true;
		if (!Block.isSolid(neighbor)) return true;
		return false;
	}

	/**
	 * Emits one quad (2 triangles, 4 shared vertices) for the given face of
	 * the block at world position (wx,wy,wz). `face` is 0..5 as documented
	 * in Block.tileFor: 0=top 1=bottom 2=north 3=south 4=east 5=west.
	 */
	static function emitFace(md:MeshData, blockId:Int, face:Int, wx:Int, wy:Int, wz:Int):Void
	{
		var x0 = wx + 0.0, x1 = wx + 1.0;
		var y0 = wy + 0.0, y1 = wy + 1.0;
		var z0 = wz + 0.0, z1 = wz + 1.0;

		// Each case lists 4 corners in CCW order as seen from outside the cube.
		var corners:Array<Array<Float>>;

		switch (face)
		{
			case 0: // TOP, viewed from above (+Y looking down): CCW is (x0,z0)->(x0,z1)->(x1,z1)->(x1,z0)
				corners = [
					[x0, y1, z0],
					[x0, y1, z1],
					[x1, y1, z1],
					[x1, y1, z0],
				];
			case 1: // BOTTOM, viewed from below (-Y looking up): CCW is (x0,z0)->(x1,z0)->(x1,z1)->(x0,z1)
				corners = [
					[x0, y0, z0],
					[x1, y0, z0],
					[x1, y0, z1],
					[x0, y0, z1],
				];
			case 2: // NORTH (-Z face), viewed from -Z looking toward +Z: CCW is (x1,y0)->(x0,y0)->(x0,y1)->(x1,y1)
				corners = [
					[x1, y0, z0],
					[x0, y0, z0],
					[x0, y1, z0],
					[x1, y1, z0],
				];
			case 3: // SOUTH (+Z face), viewed from +Z looking toward -Z: CCW is (x0,y0)->(x1,y0)->(x1,y1)->(x0,y1)
				corners = [
					[x0, y0, z1],
					[x1, y0, z1],
					[x1, y1, z1],
					[x0, y1, z1],
				];
			case 4: // EAST (+X face), viewed from +X looking toward -X: CCW is (z1,y0)->(z0,y0)->(z0,y1)->(z1,y1)
				corners = [
					[x1, y0, z1],
					[x1, y0, z0],
					[x1, y1, z0],
					[x1, y1, z1],
				];
			case 5: // WEST (-X face), viewed from -X looking toward +X: CCW is (z0,y0)->(z1,y0)->(z1,y1)->(z0,y1)
				corners = [
					[x0, y0, z0],
					[x0, y0, z1],
					[x0, y1, z1],
					[x0, y1, z0],
				];
			default:
				corners = [];
		}

		var baseIndex = Std.int(md.vertices.length / 3);

		for (c in corners)
		{
			md.vertices.push(c[0]);
			md.vertices.push(c[1]);
			md.vertices.push(c[2]);
		}

		var tile = Block.tileFor(blockId, face);
		var u0 = tile[0] * UV_STEP + UV_INSET;
		var v0 = tile[1] * UV_STEP + UV_INSET;
		var u1 = (tile[0] + 1) * UV_STEP - UV_INSET;
		var v1 = (tile[1] + 1) * UV_STEP - UV_INSET;

		// UVs correspond 1:1 with the 4 corners above, in the same CCW order:
		// corner0=(u0,v1) corner1 varies by face but the pattern below (a
		// standard quad UV wind) is correct because we defined corners
		// consistently as "bottom-left, bottom-right, top-right, top-left"
		// of the face as viewed from outside -- true for all 6 cases above.
		md.uvs.push(u0); md.uvs.push(v1);
		md.uvs.push(u1); md.uvs.push(v1);
		md.uvs.push(u1); md.uvs.push(v0);
		md.uvs.push(u0); md.uvs.push(v0);

		// Two triangles: (0,1,2) and (0,2,3), both CCW given CCW quad corners.
		md.indices.push(baseIndex + 0);
		md.indices.push(baseIndex + 1);
		md.indices.push(baseIndex + 2);
		md.indices.push(baseIndex + 0);
		md.indices.push(baseIndex + 2);
		md.indices.push(baseIndex + 3);

		md.quadCount++;
	}
}
