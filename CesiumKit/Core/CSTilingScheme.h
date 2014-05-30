//
//  CSTilingScheme.h
//  CesiumKit
//
//  Created by Ryan Walklin on 30/05/14.
//  Copyright (c) 2014 Test Toast. All rights reserved.
//

@import Foundation;

@class CSEllipsoid, CSRectangle, CSProjection, CSCartesian2, CSCartographic;

/**
 * A tiling scheme for geometry or imagery on the surface of an ellipsoid.  At level-of-detail zero,
 * the coarsest, least-detailed level, the number of tiles is configurable.
 * At level of detail one, each of the level zero tiles has four children, two in each direction.
 * At level of detail two, each of the level one tiles has four children, two in each direction.
 * This continues for as many levels as are present in the geometry or imagery source.
 *
 * @alias TilingScheme
 * @constructor
 *
 * @see WebMercatorTilingScheme
 * @see GeographicTilingScheme
 */
@interface CSTilingScheme : NSObject {
    @protected
    CSEllipsoid *_ellipsoid;
    CSRectangle *_rectangle;
    CSProjection *_projection;
    UInt32 _numberOfLevelZeroTilesX;
    UInt32 _numberOfLevelZeroTilesY;
}

@property  CSEllipsoid *ellipsoid;
@property (readonly) CSRectangle *rectangle;
@property (readonly) CSProjection *projection;
@property (readonly) UInt32 numberOfLevelZeroTilesX;
@property (readonly) UInt32 numberOfLevelZeroTilesY;

-(instancetype)initWithOptions:(NSDictionary *)options;

/**
 * Gets the total number of tiles in the X direction at a specified level-of-detail.
 * @memberof TilingScheme
 * @function
 *
 * @param {Number} level The level-of-detail.
 * @returns {Number} The number of tiles in the X direction at the given level.
 */
-(UInt32)numberOfXTilesAtLevel:(UInt32)level;

/**
 * Gets the total number of tiles in the Y direction at a specified level-of-detail.
 * @memberof TilingScheme
 * @function
 *
 * @param {Number} level The level-of-detail.
 * @returns {Number} The number of tiles in the Y direction at the given level.
 */
-(UInt32)numberOfYTilesAtLevel:(UInt32)level;

/**
 * Transforms an rectangle specified in geodetic radians to the native coordinate system
 * of this tiling scheme.
 * @memberof TilingScheme
 * @function
 *
 * @param {Rectangle} rectangle The rectangle to transform.
 * @param {Rectangle} [result] The instance to which to copy the result, or undefined if a new instance
 *        should be created.
 * @returns {Rectangle} The specified 'result', or a new object containing the native rectangle if 'result'
 *          is undefined.
 */
-(CSRectangle *)rectangleToNativeRectangle:(CSRectangle *)rectangle;

/**
 * Converts tile x, y coordinates and level to an rectangle expressed in the native coordinates
 * of the tiling scheme.
 * @memberof TilingScheme
 * @function
 *
 * @param {Number} x The integer x coordinate of the tile.
 * @param {Number} y The integer y coordinate of the tile.
 * @param {Number} level The tile level-of-detail.  Zero is the least detailed.
 * @param {Object} [result] The instance to which to copy the result, or undefined if a new instance
 *        should be created.
 *
 * @returns {Rectangle} The specified 'result', or a new object containing the rectangle
 *          if 'result' is undefined.
 */
-(CSRectangle *)tileToNativeRectangleX:(UInt32)x Y:(UInt32)y level:(UInt32)level;

/**
 * Converts tile x, y coordinates and level to a cartographic rectangle in radians.
 * @memberof TilingScheme
 * @function
 *
 * @param {Number} x The integer x coordinate of the tile.
 * @param {Number} y The integer y coordinate of the tile.
 * @param {Number} level The tile level-of-detail.  Zero is the least detailed.
 * @param {Object} [result] The instance to which to copy the result, or undefined if a new instance
 *        should be created.
 *
 * @returns {Rectangle} The specified 'result', or a new object containing the rectangle
 *          if 'result' is undefined.
 */
-(CSRectangle *)tileToRectangleX:(UInt32)x Y:(UInt32)y level:(UInt32)level;

/**
 * Calculates the tile x, y coordinates of the tile containing
 * a given cartographic position.
 * @memberof TilingScheme
 * @function
 *
 * @param {Cartographic} position The position.
 * @param {Number} level The tile level-of-detail.  Zero is the least detailed.
 * @param {Cartesian} [result] The instance to which to copy the result, or undefined if a new instance
 *        should be created.
 *
 * @returns {Cartesian2} The specified 'result', or a new object containing the tile x, y coordinates
 *          if 'result' is undefined.
 */
-(CSCartesian2 *)positionToTileXY:(CSCartographic *)position level:(UInt32)level;

@end
