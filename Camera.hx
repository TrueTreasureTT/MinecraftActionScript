package voxel;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * Free-fly camera: position in world space (block units), yaw (radians,
 * rotation around Y / looking left-right) and pitch (radians, looking
 * up-down, clamped to avoid gimbal flip past straight up/down).
 */
class Camera
{
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var yaw:Float = 0;   // 0 = facing -Z (north)
	public var pitch:Float = 0; // 0 = level, +up -down (clamped +/- ~89deg)

	static inline var PITCH_LIMIT:Float = 1.5533; // ~89 degrees in radians

	public function new(x:Float, y:Float, z:Float)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function clampPitch():Void
	{
		if (pitch > PITCH_LIMIT) pitch = PITCH_LIMIT;
		if (pitch < -PITCH_LIMIT) pitch = -PITCH_LIMIT;
	}

	/** Forward direction vector, unit length, in world space. */
	public function forward():Vector3D
	{
		var cosPitch = Math.cos(pitch);
		return new Vector3D(
			Math.sin(yaw) * cosPitch,
			Math.sin(pitch),
			-Math.cos(yaw) * cosPitch
		);
	}

	/** Right direction vector (for strafing), unit length, ignores pitch. */
	public function right():Vector3D
	{
		return new Vector3D(Math.cos(yaw), 0, Math.sin(yaw));
	}

	public function viewMatrix():Matrix3D
	{
		var f = forward();
		var eye = new Vector3D(x, y, z);
		var target = new Vector3D(x + f.x, y + f.y, z + f.z);
		var up = new Vector3D(0, 1, 0);

		var m = new Matrix3D();
		// Matrix3D has no built-in lookAt in OpenFL, so build it manually:
		// zAxis = normalize(eye - target)   (camera looks down -zAxis)
		var zAxis = eye.subtract(target);
		zAxis.normalize();
		var xAxis = up.crossProduct(zAxis);
		xAxis.normalize();
		var yAxis = zAxis.crossProduct(xAxis);

		var raw = new Vector<Float>();
		raw.push(xAxis.x); raw.push(yAxis.x); raw.push(zAxis.x); raw.push(0);
		raw.push(xAxis.y); raw.push(yAxis.y); raw.push(zAxis.y); raw.push(0);
		raw.push(xAxis.z); raw.push(yAxis.z); raw.push(zAxis.z); raw.push(0);
		raw.push(-xAxis.dotProduct(eye));
		raw.push(-yAxis.dotProduct(eye));
		raw.push(-zAxis.dotProduct(eye));
		raw.push(1);
		m.copyRawDataFrom(raw);
		return m;
	}

	public static function projectionMatrix(fovRadians:Float, aspect:Float, near:Float, far:Float):Matrix3D
	{
		var yScale = 1.0 / Math.tan(fovRadians / 2);
		var xScale = yScale / aspect;
		var m = new Matrix3D();
		var raw = new Vector<Float>();
		raw.push(xScale); raw.push(0); raw.push(0); raw.push(0);
		raw.push(0); raw.push(yScale); raw.push(0); raw.push(0);
		raw.push(0); raw.push(0); raw.push(far / (far - near)); raw.push(1);
		raw.push(0); raw.push(0); raw.push(-near * far / (far - near)); raw.push(0);
		m.copyRawDataFrom(raw);
		return m;
	}
}
