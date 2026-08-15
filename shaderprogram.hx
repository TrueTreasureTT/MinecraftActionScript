package voxel;

import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Program3D;
import openfl.display3D.textures.Texture;
import openfl.utils.AGALMiniAssembler;

/**
 * Minimal AGAL shader pair: transforms vertices by model-view-projection,
 * samples the atlas texture at the given UV. No lighting -- intentionally
 * simple so there's less to get wrong; ambient-only shading (via a per-face
 * brightness baked into vertex color) can be layered in later without
 * touching this core pipeline.
 */
class ShaderProgram
{
	public var program:Program3D;

	// Fragment constant register used by the alpha-test threshold below.
	// Callers MUST call context.setProgramConstantsFromVector(FRAGMENT, 0,
	// [ALPHA_TEST_THRESHOLD, 0,0,0]) before drawing with this program, or
	// the threshold reads as 0 and no transparent texels get discarded.
	public static inline var ALPHA_TEST_THRESHOLD:Float = 0.1;

	public function new(context:Context3D)
	{
		var vertexAssembler = new AGALMiniAssembler();
		vertexAssembler.assemble(Context3DProgramType.VERTEX, [
			"m44 op, va0, vc0", // position = mvp * position
			"mov v0, va1"       // pass UV through to fragment shader
		].join("\n"));

		// Alpha-test threshold for discarding fully-transparent texels (e.g.
		// water's semi-transparent fill still draws, but any texel authored
		// as fully transparent -- alpha near 0 -- should not write to the
		// depth buffer or color buffer at all, or you get faint dark
		// rectangles around leaf/water tile edges).
		// AGAL's `kil` instruction discards the fragment when its operand is
		// NEGATIVE, not when it's simply small -- so testing raw alpha
		// (0..1, always >= 0) would never discard anything. The fix is to
		// subtract the threshold first: (alpha - 0.1) is negative exactly
		// when alpha < 0.1, which is the actual "discard this texel" case.
		var fragmentAssembler = new AGALMiniAssembler();
		fragmentAssembler.assemble(Context3DProgramType.FRAGMENT, [
			"tex ft0, v0, fs0 <2d,nearest,clamp>", // nearest filtering: crisp pixel-art look, matches the blocky aesthetic
			"sub ft1.x, ft0.w, fc0.x",              // ft1.x = alpha - threshold
			"kil ft1.x",                             // discard if (alpha - threshold) < 0
			"mov oc, ft0"
		].join("\n"));

		program = context.createProgram();
		program.upload(vertexAssembler.agalcode, fragmentAssembler.agalcode);
	}

	public function dispose():Void
	{
		if (program != null) program.dispose();
	}
}
