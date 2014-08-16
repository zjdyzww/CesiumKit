//
//  QuadTreeTile.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 16/08/14.
//  Copyright (c) 2014 Test Toast. All rights reserved.
//

/**
* A single tile in a {@link QuadtreePrimitive}.
*
* @alias QuadtreeTile
* @constructor
* @private
*
* :param: level The level of the tile in the quadtree.
* @param x The X coordinate of the tile in the quadtree.  0 is the westernmost tile.
* @param y The Y coordinate of the tile in the quadtree.  0 is the northernmost tile.
* @param tilingScheme The tiling scheme in which this tile exists.
* @param  This tile's parent, or undefined if this is a root tile.
*/
class QuadTreeTile {
    
    let level: Int
    let x: Int
    let y: Int
    let tilingScheme: TilingScheme
    let parent: QuadTreeTile?
    
    /**
    * Gets the cartographic rectangle of the tile, with north, south, east and
    * west properties in radians.
    * @memberof QuadtreeTile.prototype
    * @type {Rectangle}
    */
    let rectangle: Rectangle
    
    /**
    * Gets or sets the current state of the tile in the tile load pipeline.
    * @type {QuadtreeTileLoadState}
    * @default {@link QuadtreeTileLoadState.START}
    */
    var state: QuadTreeTileLoadState = .Start
    /**
    * Gets or sets a value indicating whether or not the tile is currently renderable.
    * @type {Boolean}
    * @default false
    */
    var renderable = false
    
    // QuadtreeTileReplacementQueue gets/sets these private properties.
    //    var replacementPrevious = undefined;
    //    var replacementNext = undefined;
    
    // The distance from the camera to this tile, updated when the tile is selected
    // for rendering.  We can get rid of this if we have a better way to sort by
    // distance - for example, by using the natural ordering of a quadtree.
    // QuadtreePrimitive gets/sets this private property.
    var distance = 0.0
    
    /**
    * Gets or set a value indicating whether or not the tile was entire upsampled from its
    * parent tile.  If all four children of a parent tile were upsampled from the parent,
    * we will render the parent instead of the children even if the LOD indicates that
    * the children would be preferable.
    * @type {Boolean}
    * @default false
    */
    var upsampledFromParent = false
    
    /**
    * Gets a value indicating whether or not this tile needs further loading.
    * This property will return true if the {@link QuadtreeTile#state} is
    * <code>START</code> or <code>LOADING</code>.
    * @memberof QuadtreeTile.prototype
    * @type {Boolean}
    */
    var needsLoading: Bool {
        get {
            return state == QuadTreeTileLoadState.Start || state == QuadTreeTileLoadState.Loading
        }
    }
    
    /**
    * Gets a value indicating whether or not this tile is eligible to be unloaded.
    * Typically, a tile is ineligible to be unloaded while an asynchronous operation,
    * such as a request for data, is in progress on it.  A tile will never be
    * unloaded while it is needed for rendering, regardless of the value of this
    * property.  If {@link QuadtreeTile#data} is defined and has an
    * <code>eligibleForUnloading</code> property, the value of that property is returned.
    * Otherwise, this property returns true.
    * @memberof QuadtreeTile.prototype
    * @type {Boolean}
    */
    var eligibleForUnloading: Bool {
        get {
            var result = true
            
            if data != nil {
                // FIXME: data.eligibleForUnloading
                //result = data.eligibleForUnloading
                //if (!defined(result)) {
                //    result = true
                //}
            }
            return result
        }
    }


    /**
    * An array of tiles that is at the next level of the tile tree.
    * @memberof QuadtreeTile.prototype
    * @type {QuadtreeTile[]}
    */
    var children: [QuadTreeTile] {
        get {
            if _children == nil {
                var nextlevel = level + 1
                var nextX = x * 2
                var nextY = y * 2
                _children = [
                    QuadTreeTile(level: nextlevel, x: nextX, y: nextY, tilingScheme: tilingScheme, parent: self),
                    QuadTreeTile(level: nextlevel, x: nextX + 1, y: nextY, tilingScheme: tilingScheme, parent: self),
                    QuadTreeTile(level: nextlevel, x: nextX, y: nextY + 1, tilingScheme: tilingScheme, parent: self),
                    QuadTreeTile(level: nextlevel, x: nextX + 1, y: nextY + 1, tilingScheme: tilingScheme, parent: self)
                ]
            }
            return _children!
        }
    }
    
    var _children: [QuadTreeTile]?
    
    /**
    * Gets or sets the additional data associated with this tile.  The exact content is specific to the
    * {@link QuadtreeTileProvider}.
    * @type {Object}
    * @default undefined
    */
    var data: GlobeSurfaceTile? = nil
    
    init(level: Int, x: Int, y: Int, tilingScheme: TilingScheme, parent: QuadTreeTile?) {
        
        assert(x >= 0 && y >= 0, "x and y must be greater than or equal to zero")
        assert(level >= 0, "level must be greater than or equal to zero.")
        
        self.tilingScheme = tilingScheme
        self.x = x
        self.y = y
        self.level = level
        self.parent = parent
        self.rectangle = self.tilingScheme.tileXYToRectangle(x: self.x, y: self.y, level: self.level)
    }
    
    /**
    * Creates a rectangular set of tiles for level of detail zero, the coarsest, least detailed level.
    *
    * @memberof QuadtreeTile
    *
    * @param {TilingScheme} tilingScheme The tiling scheme for which the tiles are to be created.
    * @returns {QuadtreeTile[]} An array containing the tiles at level of detail zero, starting with the
    * tile in the northwest corner and followed by the tile (if any) to its east.
    */
    class func createLevelZeroTiles (tilingScheme: TilingScheme) -> [QuadTreeTile] {
        
        var numberOfLevelZeroTilesX = tilingScheme.numberOfXTilesAtLevel(0)
        var numberOfLevelZeroTilesY = tilingScheme.numberOfYTilesAtLevel(0)
        
        var result = [QuadTreeTile]()
        
        var index = 0
        for var y = 0; y < numberOfLevelZeroTilesY; ++y {
            for var x = 0; x < numberOfLevelZeroTilesX; ++x {
                result.append(QuadTreeTile(level: 0, x: x, y: y, tilingScheme: tilingScheme, parent: nil))
            }
        }
        return result
    }
    
    /**
    * Frees the resources assocated with this tile and returns it to the <code>START</code>
    * {@link QuadtreeTileLoadState}.  If the {@link QuadtreeTile#data} property is defined and it
    * has a <code>freeResources</code> method, the method will be invoked.
    *
    * @memberof QuadtreeTile
    */
    func freeResources () {
        state = .Start
        renderable = false
        upsampledFromParent = false
        
        data?.freeResources()
        
        if _children != nil {
            for tile in _children {
                tile.freeResources()
            }
            _children = nil
        }
    }

}