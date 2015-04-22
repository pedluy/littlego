// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class GoGame;
@class GoGameRules;
@class GoMove;
@class GoPlayer;
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The GoUtilities class is a container for various utility functions
/// that operate on all sorts of objects from the Go module.
///
/// @ingroup go
///
/// All functions in GoUtilities are class methods, so there is no need to
/// create an instance of GoUtilities.
// -----------------------------------------------------------------------------
@interface GoUtilities : NSObject
{
}

+ (void) movePointToNewRegion:(GoPoint*)thePoint;
+ (NSArray*) verticesForHandicap:(int)handicap boardSize:(enum GoBoardSize)boardSize;
+ (NSArray*) pointsForHandicap:(int)handicap inGame:(GoGame*)game;
+ (int) maximumHandicapForBoardSize:(enum GoBoardSize)boardSize;
+ (GoPlayer*) playerAfter:(GoMove*)move inGame:(GoGame*)game;
+ (NSArray*) pointsInRectangleDelimitedByCornerPoint:(GoPoint*)pointA
                                 oppositeCornerPoint:(GoPoint*)pointB
                                              inGame:(GoGame*)game;
+ (double) defaultKomiForHandicap:(int)handicap scoringSystem:(enum GoScoringSystem)scoringSystem;
+ (GoGameRules*) rulesForRuleset:(enum GoRuleset)ruleset;
+ (enum GoRuleset) rulesetForRules:(GoGameRules*)rules;

@end
