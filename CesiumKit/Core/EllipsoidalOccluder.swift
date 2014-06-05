//
//  EllipsoidalOccluder.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 3/06/14.
//  Copyright (c) 2014 Test Toast. All rights reserved.
//

import Foundation

/**
* Determine whether or not other objects are visible or hidden behind the visible horizon defined by
* an {@link Ellipsoid} and a camera position.  The ellipsoid is assumed to be located at the
* origin of the coordinate system.  This class uses the algorithm described in the
* {@link http://cesiumjs.org/2013/04/25/Horizon-culling/|Horizon Culling} blog post.
*
* @alias EllipsoidalOccluder
*
* @param {Ellipsoid} ellipsoid The ellipsoid to use as an occluder.
* @param {Cartesian3} [cameraPosition] The coordinate of the viewer/camera.  If this parameter is not
*        specified, {@link EllipsoidalOccluder#cameraPosition} must be called before
*        testing visibility.
*
* @constructor
*
* @example
* // Construct an ellipsoidal occluder with radii 1.0, 1.1, and 0.9.
* var cameraPosition = new Cesium.Cartesian3(5.0, 6.0, 7.0);
* var occluderEllipsoid = new Cesium.Ellipsoid(1.0, 1.1, 0.9);
* var occluder = new Cesium.EllipsoidalOccluder(occluderEllipsoid, cameraPosition);
*/

class EllipsoidalOccluder {
    var ellipsoid: CSEllipsoid
    var cameraPosition: CSCartesian3 = CSCartesian3 () {
    didSet {
        // See http://cesiumjs.org/2013/04/25/Horizon-culling/
        self.cameraPositionInScaledSpace = self.ellipsoid.transformPositionToScaledSpace(self.cameraPosition)
        self.distanceToLimbInScaledSpaceSquared = self.cameraPositionInScaledSpace.magnitudeSquared() - 1.0;
    }
    }
    var cameraPositionInScaledSpace: CSCartesian3
    var distanceToLimbInScaledSpaceSquared: Double
    
    init(ellipsoid: CSEllipsoid, cameraPosition: CSCartesian3) {
        self.ellipsoid = ellipsoid

        self.cameraPositionInScaledSpace = CSCartesian3()
        self.distanceToLimbInScaledSpaceSquared = 0.0
        if (cameraPosition != nil)
        {
            self.cameraPosition = cameraPosition
        }
        else
        {
            self.cameraPosition = CSCartesian3()
        }
        UnsafePointer
    }
    
    /**
    * Determines whether or not a point, the <code>occludee</code>, is hidden from view by the occluder.
    *
    * @memberof EllipsoidalOccluder
    *
    * @param {Cartesian3} occludee The point to test for visibility.
    *
    * @returns {Boolean} <code>true</code> if the occludee is visible; otherwise <code>false</code>.
    *
    * @example
    * var cameraPosition = new Cesium.Cartesian3(0, 0, 2.5);
    * var ellipsoid = new Cesium.Ellipsoid(1.0, 1.1, 0.9);
    * var occluder = new Cesium.EllipsoidalOccluder(ellipsoid, cameraPosition);
    * var point = new Cesium.Cartesian3(0, -3, -3);
    * occluder.isPointVisible(point); //returns true
    */
    func isPointVisible(occludee: CSCartesian3) -> Bool {
        var occludeeScaledSpacePosition = ellipsoid.transformPositionToScaledSpace(occludee);
        return isScaledSpacePointVisible(occludeeScaledSpacePosition);
    }
    
    /**
    * Determines whether or not a point expressed in the ellipsoid scaled space, is hidden from view by the
    * occluder.  To transform a Cartesian X, Y, Z position in the coordinate system aligned with the ellipsoid
    * into the scaled space, call {@link Ellipsoid#transformPositionToScaledSpace}.
    *
    * @memberof EllipsoidalOccluder
    *
    * @param {Cartesian3} occludeeScaledSpacePosition The point to test for visibility, represented in the scaled space.
    *
    * @returns {Boolean} <code>true</code> if the occludee is visible; otherwise <code>false</code>.
    *
    * @example
    * var cameraPosition = new Cesium.Cartesian3(0, 0, 2.5);
    * var ellipsoid = new Cesium.Ellipsoid(1.0, 1.1, 0.9);
    * var occluder = new Cesium.EllipsoidalOccluder(ellipsoid, cameraPosition);
    * var point = new Cesium.Cartesian3(0, -3, -3);
    * var scaledSpacePoint = ellipsoid.transformPositionToScaledSpace(point);
    * occluder.isScaledSpacePointVisible(scaledSpacePoint); //returns true
    */
    func isScaledSpacePointVisible(occludeeScaledSpacePosition: CSCartesian3) -> Bool {
        // See http://cesiumjs.org/2013/04/25/Horizon-culling/
        var vt = occludeeScaledSpacePosition.subtract(cameraPositionInScaledSpace)
        var vtDotVc = -vt.dot(cameraPositionInScaledSpace)
        var isOccluded = vtDotVc > distanceToLimbInScaledSpaceSquared &&
            vtDotVc * vtDotVc / vt.magnitudeSquared() > distanceToLimbInScaledSpaceSquared
        return !isOccluded;
    }
    
    /**
    * Computes a point that can be used for horizon culling from a list of positions.  If the point is below
    * the horizon, all of the positions are guaranteed to be below the horizon as well.  The returned point
    * is expressed in the ellipsoid-scaled space and is suitable for use with
    * {@link EllipsoidalOccluder#isScaledSpacePointVisible}.
    *
    * @param {Cartesian3} directionToPoint The direction that the computed point will lie along.
    *                     A reasonable direction to use is the direction from the center of the ellipsoid to
    *                     the center of the bounding sphere computed from the positions.  The direction need not
    *                     be normalized.
    * @param {Cartesian3[]} positions The positions from which to compute the horizon culling point.  The positions
    *                       must be expressed in a reference frame centered at the ellipsoid and aligned with the
    *                       ellipsoid's axes.
    * @param {Cartesian3} [result] The instance on which to store the result instead of allocating a new instance.
    * @returns {Cartesian3} The computed horizon culling point, expressed in the ellipsoid-scaled space.
    */
    func computeHorizonCullingPoint(directionToPoint: CSCartesian3, positions: CSCartesian3[]) -> CSCartesian3? {
        var scaledSpaceDirectionToPoint = computeScaledSpaceDirectionToPoint(ellipsoid, directionToPoint: directionToPoint);
        var resultMagnitude = 0.0
        for (var i = 0, len = positions.count; i < len; ++i) {
            var candidateMagnitude = computeMagnitude(ellipsoid, position: positions[i], scaledSpaceDirectionToPoint: scaledSpaceDirectionToPoint)
            resultMagnitude = max(resultMagnitude, candidateMagnitude)
        }
        
        return magnitudeToPoint(scaledSpaceDirectionToPoint, resultMagnitude: resultMagnitude)
    }

    /**
    * Computes a point that can be used for horizon culling from a list of positions.  If the point is below
    * the horizon, all of the positions are guaranteed to be below the horizon as well.  The returned point
    * is expressed in the ellipsoid-scaled space and is suitable for use with
    * {@link EllipsoidalOccluder#isScaledSpacePointVisible}.
    *
    * @param {Cartesian3} directionToPoint The direction that the computed point will lie along.
    *                     A reasonable direction to use is the direction from the center of the ellipsoid to
    *                     the center of the bounding sphere computed from the positions.  The direction need not
    *                     be normalized.
    * @param {Number[]} vertices  The vertices from which to compute the horizon culling point.  The positions
    *                   must be expressed in a reference frame centered at the ellipsoid and aligned with the
    *                   ellipsoid's axes.
    * @param {Number} [stride=3]
    * @param {Cartesian3} [center=Cartesian3.ZERO]
    * @param {Cartesian3} [result] The instance on which to store the result instead of allocating a new instance.
    * @returns {Cartesian3} The computed horizon culling point, expressed in the ellipsoid-scaled space.
    */
    func computeHorizonCullingPointFromVertices(
        directionToPoint: CSCartesian3,
        vertices: Double[],
        stride: Int,
        center: CSCartesian3 = CSCartesian3.zero()) -> CSCartesian3? {
        
            var scaledSpaceDirectionToPoint = computeScaledSpaceDirectionToPoint(ellipsoid, directionToPoint: directionToPoint)
        var resultMagnitude = 0.0
        
            var positionScratch: CSCartesian3
            for (var i = 0; i < vertices.count; i += stride) {
            positionScratch = CSCartesian3(
                x: vertices[i] + center.x,
                y: vertices[i + 1] + center.y,
                z: vertices[i + 2] + center.z)
            
            var candidateMagnitude = computeMagnitude(ellipsoid, position: positionScratch, scaledSpaceDirectionToPoint: scaledSpaceDirectionToPoint)
            resultMagnitude = max(resultMagnitude, candidateMagnitude)
        }
            return magnitudeToPoint(scaledSpaceDirectionToPoint, resultMagnitude: resultMagnitude)
        
    }
    
    /**
    * Computes a point that can be used for horizon culling of an rectangle.  If the point is below
    * the horizon, the ellipsoid-conforming rectangle is guaranteed to be below the horizon as well.
    * The returned point is expressed in the ellipsoid-scaled space and is suitable for use with
    * {@link EllipsoidalOccluder#isScaledSpacePointVisible}.
    *
    * @param {Rectangle} rectangle The rectangle for which to compute the horizon culling point.
    * @param {Ellipsoid} ellipsoid The ellipsoid on which the rectangle is defined.  This may be different from
    *                    the ellipsoid used by this instance for occlusion testing.
    * @param {Cartesian3} [result] The instance on which to store the result instead of allocating a new instance.
    * @returns {Cartesian3} The computed horizon culling point, expressed in the ellipsoid-scaled space.
    */
    func computeHorizonCullingPointFromRectangle(
        rectangle: CSRectangle,
        ellipsoid: CSEllipsoid) -> CSCartesian3? {
            var positions = rectangle.subsample(ellipsoid, surfaceHeight: 0.0);
            var bs = CSBoundingSphere(fromPoints: positions);
            
            // If the bounding sphere center is too close to the center of the occluder, it doesn't make
            // sense to try to horizon cull it.
            if (bs.center.magnitude() < 0.1 * ellipsoid.minimumRadius) {
                return nil;
            }
            return nil;
//            return computeHorizonCullingPoint(bs.center, positions: positions)
    }
    
    func computeMagnitude(
        ellipsoid: CSEllipsoid,
        position: CSCartesian3,
        scaledSpaceDirectionToPoint: CSCartesian3) -> Double {
            var scaledSpacePosition = ellipsoid.transformPositionToScaledSpace(position)
            var magnitudeSquared = scaledSpacePosition.magnitudeSquared();
            var magnitude = sqrt(magnitudeSquared);
            var direction = scaledSpacePosition.divideByScalar(magnitude);
            
            // For the purpose of this computation, points below the ellipsoid are consider to be on it instead.
            magnitudeSquared = max(1.0, magnitudeSquared);
            magnitude = max(1.0, magnitude);
            
            var cosAlpha = direction.dot(scaledSpaceDirectionToPoint);
            var sinAlpha = direction.cross(scaledSpaceDirectionToPoint).magnitude();
            var cosBeta = 1.0 / magnitude;
            var sinBeta = sqrt(magnitudeSquared - 1.0) * cosBeta;
            
            return 1.0 / (cosAlpha * cosBeta - sinAlpha * sinBeta);
    }
    
    func magnitudeToPoint(
        scaledSpaceDirectionToPoint: CSCartesian3,
        resultMagnitude: Double) -> CSCartesian3? {
            // The horizon culling point is undefined if there were no positions from which to compute it,
            // the directionToPoint is pointing opposite all of the positions,  or if we computed NaN or infinity.
            if (resultMagnitude <= 0.0 || resultMagnitude == 1.0 / 0.0 || resultMagnitude != resultMagnitude) {
                return nil;
            }
            
            return scaledSpaceDirectionToPoint.multiplyByScalar(resultMagnitude);
    }
   
    func computeScaledSpaceDirectionToPoint(
        ellipsoid: CSEllipsoid,
        directionToPoint: CSCartesian3) -> CSCartesian3 {
            return ellipsoid.transformPositionToScaledSpace(directionToPoint).normalise();
    }
}
