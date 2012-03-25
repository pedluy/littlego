// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -----------------------------------------------------------------------------


// Project includes
#import "PlayViewLayerDelegateBase.h"

// Forward declarations
@class ScoringModel;


// -----------------------------------------------------------------------------
/// @brief The TerritoryLayerDelegate class is responsible for drawing territory
/// while scoring is in progress.
// -----------------------------------------------------------------------------
@interface TerritoryLayerDelegate : PlayViewLayerDelegateBase
{
}

- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics playViewModel:(PlayViewModel*)playViewModel scoringModel:(ScoringModel*)theScoringModel;

/// @name PlayViewLayerDelegate methods
//@{
- (void) notify:(enum PlayViewLayerDelegateEvent)event eventInfo:(id)eventInfo;
//@}

/// @name CALayer delegate methods
//@{
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context;
//@}

@end