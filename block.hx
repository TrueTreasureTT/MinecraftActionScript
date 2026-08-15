package voxel;

import openfl.net.SharedObject;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.crypto.Base64;

/**
 * Persistence via openfl.net.SharedObject, which is the correct
 * cross-target choice here: on the HTML5 target it's backed by
 * localStorage automatically, and on other targets (AIR/native) it uses
 * the platform's local storage equivalent -- so this same code works
 * whether we're running in a browser or a standalone build, without an
 * #if html5 branch.
 *
 * Format: each chunk's block array (16*64*16 = 16384 ints, each 0-255)
 * is packed as raw bytes (1 byte per block id -- COUNT is well under 256)
 * then base64-encoded so it can live inside a SharedObject string field.
 */
class SaveSystem
{
	static inline var SO_NAME:String = "voxelpe_save";
	static inline var VERSION:Int = 1;

	public static function save(world:World):Bool
	{
		var so = SharedObject.getLocal(SO_NAME);
		if (so == null) return false;

		var chunkList:Array<Dynamic> = [];
		for (c in world.allChunks())
		{
			var buf = new BytesBuffer();
			for (b in c.blocks)
			{
				buf.addByte(b);
			}
			var bytes = buf.getBytes();
			chunkList.push({
				cx: c.cx,
				cz: c.cz,
				data: Base64.encode(bytes)
			});
		}

		so.data.version = VERSION;
		so.data.chunks = chunkList;
		so.data.savedAt = Date.now().getTime();

		try
		{
			so.flush();
			return true;
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	/**
	 * Also saves player camera state (position + look direction) so
	 * reloading drops the player back where they were, not back at spawn.
	 */
	public static function savePlayer(camera:Camera):Void
	{
		var so = SharedObject.getLocal(SO_NAME);
		if (so == null) return;
		so.data.playerX = camera.x;
		so.data.playerY = camera.y;
		so.data.playerZ = camera.z;
		so.data.playerYaw = camera.yaw;
		so.data.playerPitch = camera.pitch;
		try { so.flush(); } catch (e:Dynamic) {}
	}

	/** Returns true if a save exists to load. */
	public static function hasSave():Bool
	{
		var so = SharedObject.getLocal(SO_NAME);
		return so != null && so.data.chunks != null;
	}

	/**
	 * Loads all chunks from the save into the given World. Returns false
	 * (and leaves world untouched) if no valid save is present, so the
	 * caller knows to fall back to WorldGen instead.
	 */
	public static function load(world:World):Bool
	{
		var so = SharedObject.getLocal(SO_NAME);
		if (so == null || so.data.chunks == null) return false;

		var chunkList:Array<Dynamic> = so.data.chunks;
		for (entry in chunkList)
		{
			var cx:Int = entry.cx;
			var cz:Int = entry.cz;
			var bytes:Bytes = Base64.decode(entry.data);

			var c = new Chunk(cx, cz);
			var expected = Chunk.W * Chunk.H * Chunk.D;
			if (bytes.length != expected)
			{
				// Corrupt or version-mismatched entry; skip rather than
				// crash the whole load.
				continue;
			}
			for (i in 0...expected)
			{
				c.blocks[i] = bytes.get(i);
			}
			c.dirty = true;
			world.setChunk(c);
		}

		return true;
	}

	/** Returns [x,y,z,yaw,pitch] if saved player state exists, else null. */
	public static function loadPlayer():Null<Array<Float>>
	{
		var so = SharedObject.getLocal(SO_NAME);
		if (so == null || so.data.playerX == null) return null;
		return [so.data.playerX, so.data.playerY, so.data.playerZ, so.data.playerYaw, so.data.playerPitch];
	}

	public static function clear():Void
	{
		var so = SharedObject.getLocal(SO_NAME);
		if (so != null) so.clear();
	}
}
