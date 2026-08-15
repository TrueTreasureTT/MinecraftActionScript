package voxel;

import openfl.display.Sprite;
import openfl.display.Stage3D;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DClearMask;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.Texture;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.ui.Keyboard;
import openfl.Vector;
import openfl.Assets;

/**
 * Owns the whole game: world state, camera, per-chunk GPU buffers, and the
 * input->action mapping. Deliberately a single class rather than an
 * ECS/entity framework -- for a project this size that would be more
 * ceremony than value; the systems (World, Mesher, Camera, Raycaster,
 * SaveSystem) are already separated out, this class just orchestrates them.
 */
class Game extends Sprite
{
	var context:Context3D;
	var stage3D:Stage3D;
	var shader:ShaderProgram;
	var atlasTexture:Texture;

	var world:World;
	var camera:Camera;

	// GPU buffers per chunk, rebuilt when a chunk's `dirty` flag is set.
	var chunkVBuffers:Map<String, VertexBuffer3D>;
	var chunkIBuffers:Map<String, IndexBuffer3D>;
	var chunkIndexCounts:Map<String, Int>;

	// Input state
	var keysDown:Map<Int, Bool>;
	var mouseLookActive:Bool = false;
	var lastMouseX:Float = 0;
	var lastMouseY:Float = 0;
	static inline var MOUSE_SENSITIVITY:Float = 0.0025;
	static inline var MOVE_SPEED:Float = 6.0; // blocks per second, fly mode
	static inline var FOV:Float = 1.13; // ~65 degrees, in radians

	// Hotbar: which block the player currently has selected to place.
	var hotbar:Array<Int> = [Block.GRASS, Block.DIRT, Block.STONE, Block.COBBLESTONE, Block.WOOD_LOG, Block.PLANK, Block.LEAVES, Block.SAND, Block.WATER];
	var selectedSlot:Int = 0;

	var ui:GameUI;

	public function new()
	{
		super();
		world = new World();
		camera = new Camera(32, 12, 32);
		keysDown = new Map();
		chunkVBuffers = new Map();
		chunkIBuffers = new Map();
		chunkIndexCounts = new Map();

		Block.init();

		stage3D = stage.stage3Ds[0];
		stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
		stage3D.requestContext3D();

		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	function onContext3DCreate(e:Event):Void
	{
		context = stage3D.context3D;
		context.configureBackBuffer(960, 640, 0, true);
		context.enableErrorChecking = true; // dev-time only; disable for release builds (perf cost)

		shader = new ShaderProgram(context);

		var bmd = Assets.getBitmapData("img/atlas.png");
		atlasTexture = context.createTexture(bmd.width, bmd.height, openfl.display3D.Context3DTextureFormat.BGRA, false);
		atlasTexture.uploadFromBitmapData(bmd);

		loadOrGenerateWorld();
		setupInput();
		buildInitialUI();

		rebuildAllDirtyChunks();
	}

	function loadOrGenerateWorld():Void
	{
		if (SaveSystem.hasSave())
		{
			SaveSystem.load(world);
			var p = SaveSystem.loadPlayer();
			if (p != null)
			{
				camera.x = p[0]; camera.y = p[1]; camera.z = p[2];
				camera.yaw = p[3]; camera.pitch = p[4];
			}
			return;
		}

		// Fresh world: generate the flat chunk grid + a few trees.
		for (cx in 0...WorldGen.CHUNKS_X)
		{
			for (cz in 0...WorldGen.CHUNKS_Z)
			{
				var c = WorldGen.generateFlatChunk(cx, cz);
				world.setChunk(c);
			}
		}
		// Trees are planted after all chunks exist so tree logic that reads
		// neighbor blocks (none currently, but future-proofing) sees a
		// consistent world.
		for (cx in 0...WorldGen.CHUNKS_X)
		{
			for (cz in 0...WorldGen.CHUNKS_Z)
			{
				var c = world.getChunk(cx, cz);
				for (spot in WorldGen.defaultTreeSpots(cx, cz))
				{
					WorldGen.plantTree(c, spot[0], spot[1]);
				}
			}
		}
	}

	function setupInput():Void
	{
		stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) keysDown.set(e.keyCode, true));
		stage.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent) keysDown.set(e.keyCode, false));

		stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		stage.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent) mouseLookActive = false);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.addEventListener(MouseEvent.RIGHT_CLICK, onRightClick);
		// NOTE: RIGHT_CLICK requires context menu to be disabled on the
		// stage, otherwise the browser's native context menu intercepts it.
		// That's set in Main.hx at startup (stage.contextMenu = disabled one).
	}

	function onMouseDown(e:MouseEvent):Void
	{
		mouseLookActive = true;
		lastMouseX = e.stageX;
		lastMouseY = e.stageY;
		breakBlockUnderCrosshair();
	}

	function onRightClick(e:MouseEvent):Void
	{
		placeBlockUnderCrosshair();
	}

	function onMouseMove(e:MouseEvent):Void
	{
		if (!mouseLookActive) return;
		var dx = e.stageX - lastMouseX;
		var dy = e.stageY - lastMouseY;
		camera.yaw += dx * MOUSE_SENSITIVITY;
		camera.pitch -= dy * MOUSE_SENSITIVITY;
		camera.clampPitch();
		lastMouseX = e.stageX;
		lastMouseY = e.stageY;
	}

	function breakBlockUnderCrosshair():Void
	{
		var hit = Raycaster.cast(world, camera.x, camera.y, camera.z, camera.forward());
		if (hit != null)
		{
			world.setBlockWorld(hit.bx, hit.by, hit.bz, Block.AIR);
			markChunkDirtyAt(hit.bx, hit.bz);
		}
	}

	function placeBlockUnderCrosshair():Void
	{
		var hit = Raycaster.cast(world, camera.x, camera.y, camera.z, camera.forward());
		if (hit == null) return;

		// Compute the adjacent cell on the hit face -- that's where the new
		// block goes, per the face numbering documented in Raycaster.hx.
		var px = hit.bx, py = hit.by, pz = hit.bz;
		switch (hit.face)
		{
			case 0: py += 1; // top
			case 1: py -= 1; // bottom
			case 2: pz -= 1; // north
			case 3: pz += 1; // south
			case 4: px += 1; // east
			case 5: px -= 1; // west
		}

		// Don't let the player place a block inside their own bounding
		// volume (a crude AABB check -- treat the player as a 0.6-wide,
		// 1.8-tall box centered on x/z, feet at camera.y - eye height).
		if (wouldIntersectPlayer(px, py, pz)) return;

		world.setBlockWorld(px, py, pz, hotbar[selectedSlot]);
		markChunkDirtyAt(px, pz);
	}

	function wouldIntersectPlayer(bx:Int, by:Int, bz:Int):Bool
	{
		var feetY = camera.y - 1.6;
		var withinX = camera.x > bx - 0.3 && camera.x < bx + 1.3;
		var withinZ = camera.z > bz - 0.3 && camera.z < bz + 1.3;
		var withinY = feetY < by + 1 && (feetY + 1.8) > by;
		return withinX && withinZ && withinY;
	}

	function markChunkDirtyAt(wx:Int, wz:Int):Void
	{
		var cx = Std.int(Math.floor(wx / Chunk.W));
		var cz = Std.int(Math.floor(wz / Chunk.D));
		var c = world.getChunk(cx, cz);
		if (c != null) c.dirty = true;
	}

	var lastFrameTime:Float = 0;

	function onEnterFrame(e:Event):Void
	{
		if (context == null) return;

		var now = Date.now().getTime() / 1000.0;
		if (lastFrameTime == 0) lastFrameTime = now;
		var dt = now - lastFrameTime;
		if (dt > 0.1) dt = 0.1; // clamp huge dt after tab-switch stalls
		lastFrameTime = now;

		updateMovement(dt);
		rebuildAllDirtyChunks();
		render();
		if (ui != null) ui.updateCrosshairHint(Raycaster.cast(world, camera.x, camera.y, camera.z, camera.forward()) != null);
	}

	function updateMovement(dt:Float):Void
	{
		var f = camera.forward();
		var r = camera.right();
		var speed = MOVE_SPEED * dt;

		var moveX = 0.0, moveY = 0.0, moveZ = 0.0;

		if (isDown(Keyboard.W)) { moveX += f.x; moveY += f.y; moveZ += f.z; }
		if (isDown(Keyboard.S)) { moveX -= f.x; moveY -= f.y; moveZ -= f.z; }
		if (isDown(Keyboard.A)) { moveX -= r.x; moveZ -= r.z; }
		if (isDown(Keyboard.D)) { moveX += r.x; moveZ += r.z; }
		if (isDown(Keyboard.SPACE)) { moveY += 1; }
		if (isDown(Keyboard.SHIFT)) { moveY -= 1; }

		var len = Math.sqrt(moveX * moveX + moveY * moveY + moveZ * moveZ);
		if (len > 0.0001)
		{
			camera.x += (moveX / len) * speed;
			camera.y += (moveY / len) * speed;
			camera.z += (moveZ / len) * speed;
		}
	}

	inline function isDown(code:Int):Bool
	{
		return keysDown.exists(code) && keysDown.get(code);
	}

	function rebuildAllDirtyChunks():Void
	{
		for (c in world.allChunks())
		{
			if (!c.dirty) continue;
			uploadChunkMesh(c);
			c.dirty = false;
		}
	}

	function uploadChunkMesh(c:Chunk):Void
	{
		var key = c.cx + "_" + c.cz;
		var md = Mesher.build(world, c);

		// Dispose old buffers before replacing, to avoid leaking GPU memory
		// every time a chunk is edited.
		if (chunkVBuffers.exists(key)) chunkVBuffers.get(key).dispose();
		if (chunkIBuffers.exists(key)) chunkIBuffers.get(key).dispose();

		var vertCount = Std.int(md.vertices.length / 3);
		if (vertCount == 0)
		{
			chunkVBuffers.remove(key);
			chunkIBuffers.remove(key);
			chunkIndexCounts.set(key, 0);
			return;
		}

		// Interleave position (3) + uv (2) = 5 floats per vertex.
		var interleaved = new Vector<Float>();
		for (i in 0...vertCount)
		{
			interleaved.push(md.vertices[i * 3 + 0]);
			interleaved.push(md.vertices[i * 3 + 1]);
			interleaved.push(md.vertices[i * 3 + 2]);
			interleaved.push(md.uvs[i * 2 + 0]);
			interleaved.push(md.uvs[i * 2 + 1]);
		}

		var vb = context.createVertexBuffer(vertCount, 5);
		vb.uploadFromVector(interleaved, 0, vertCount);

		var ib = context.createIndexBuffer(md.indices.length);
		ib.uploadFromVector(md.indices, 0, md.indices.length);

		chunkVBuffers.set(key, vb);
		chunkIBuffers.set(key, ib);
		chunkIndexCounts.set(key, md.indices.length);
	}

	function render():Void
	{
		context.clear(0.494, 0.753, 0.933, 1); // sky blue, matches window bg
		context.setDepthTest(true, Context3DCompareMode.LESS);
		context.setCulling(Context3DTriangleFace.BACK);

		context.setProgram(shader.program);
		context.setTextureAt(0, atlasTexture);
		context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0,
			Vector.ofArray([ShaderProgram.ALPHA_TEST_THRESHOLD, 0.0, 0.0, 0.0]));

		var view = camera.viewMatrix();
		var proj = Camera.projectionMatrix(FOV, 960 / 640, 0.1, 200);
		var model = new Matrix3D(); // identity: chunk mesh vertices are already in world space

		var mvp = model.clone();
		mvp.append(view);
		mvp.append(proj);

		context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvp, true);

		for (key in chunkVBuffers.keys())
		{
			var vb = chunkVBuffers.get(key);
			var ib = chunkIBuffers.get(key);
			var count = chunkIndexCounts.get(key);
			if (vb == null || ib == null || count == 0) continue;

			context.setVertexBufferAt(0, vb, 0, Context3DVertexBufferFormat.FLOAT_3); // position
			context.setVertexBufferAt(1, vb, 3, Context3DVertexBufferFormat.FLOAT_2); // uv

			context.drawTriangles(ib, 0, Std.int(count / 3));
		}

		context.setVertexBufferAt(0, null);
		context.setVertexBufferAt(1, null);
		context.present();
	}

	function buildInitialUI():Void
	{
		ui = new GameUI(hotbar, selectedSlot);
		addChild(ui);
		ui.onSlotSelected = function(slot:Int) selectedSlot = slot;
		ui.onSave = function() {
			SaveSystem.save(world);
			SaveSystem.savePlayer(camera);
		};
		ui.onJump = function() { if (isOnGround()) camera.y += 0.1; }; // placeholder hop, no gravity yet in fly mode
	}

	function isOnGround():Bool
	{
		var below = world.getBlockWorld(Std.int(Math.floor(camera.x)), Std.int(Math.floor(camera.y - 1.7)), Std.int(Math.floor(camera.z)));
		return Block.isSolid(below);
	}
}
