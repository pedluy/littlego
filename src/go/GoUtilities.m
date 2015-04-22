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


// Project includes
#import "GoUtilities.h"
#import "GoBoard.h"
#import "GoBoardRegion.h"
#import "GoGame.h"
#import "GoGameRules.h"
#import "GoMove.h"
#import "GoPoint.h"
#import "GoVertex.h"


@implementation GoUtilities

// -----------------------------------------------------------------------------
/// @brief Moves @a thePoint to a new GoBoardRegion in response to a change of
/// GoPoint.stoneState.
///
/// @a thePoint's stone state already must have its new value at the time this
/// method is invoked.
///
/// Effects of this method are:
/// - @a thePoint is removed from its old GoBoardRegion
/// - @a thePoint is added either to an existing GoBoardRegion (if one of the
///   neighbours of @a thePoint has the same GoPoint.stoneState), or to a new
///   GoBoardRegion (if all neighbours have a different GoPoint.stoneState)
/// - @a thePoint's old GoBoardRegion may become fragmented if @a thePoint
///   has been the only link between two or more sub-regions
/// - @a thePoint's new GoBoardRegion may merge with other regions if
///   @a thePoint joins them together
// -----------------------------------------------------------------------------
+ (void) movePointToNewRegion:(GoPoint*)thePoint
{
  // Step 1: Remove point from old region
  // Note: We must retain/autorelease to make sure that oldRegion survives
  // invocation of removePoint:() one line further down. If we don't retain
  // and thePoint is the last point of oldRegion, invoking removePoint:() will
  // cause thePoint's reference to oldRegion to be removed, which in turn will
  // cause oldRegion's retain count to drop to zero, deallocating it.
  GoBoardRegion* oldRegion = [[thePoint.region retain] autorelease];
  [oldRegion removePoint:thePoint];  // possible side-effect: oldRegion might be
                                     // split into multiple GoBoardRegion objects

  // Step 2: Attempt to add the point to the same region as one of its
  // neighbours. At the same time, merge regions if they can be joined.
  GoBoardRegion* newRegion = nil;
  for (GoPoint* neighbour in thePoint.neighbours)
  {
    // Do not consider the neighbour if the stone states do not match (stone
    // state also includes stone color)
    if (neighbour.stoneState != thePoint.stoneState)
      continue;
    if (! newRegion)
    {
      // Join the region of one of the neighbours
      newRegion = neighbour.region;
      [newRegion addPoint:thePoint];
    }
    else
    {
      // The stone has already joined a neighbouring region
      // -> now check if entire regions can be merged
      GoBoardRegion* neighbourRegion = neighbour.region;
      if (neighbourRegion != newRegion)
        [newRegion joinRegion:neighbourRegion];
    }
  }

  // Step 3: Still no region? The point forms its own new region!
  if (! newRegion)
    [GoBoardRegion regionWithPoint:thePoint];
}

// -----------------------------------------------------------------------------
/// @brief Returns an (unordered) list of NSString objects that denote vertices
/// for the specified @a handicap and @a boardSize.
///
/// For board sizes greater than 7x7, @a handicap must be between 2 and 9. For
/// board size 7x7, @a handicap must be between 2 and 4. The limits are
/// inclusive.
///
/// The handicap positions returned by this method correspond to those specified
/// in section 4.1.1 of the GTP v2 specification.
/// http://www.lysator.liu.se/~gunnar/gtp/gtp2-spec-draft2/gtp2-spec.html#sec:fixed-handicap-placement
///
/// Handicap stone distribution for handicaps 1-5:
/// @verbatim
/// 3   2
///   5
/// 1   4
/// @endverbatim
///
/// Handicap stone distribution for handicaps 6-7:
/// @verbatim
/// 3   2
/// 5 7 6
/// 1   4
/// @endverbatim
///
/// Handicap stone distribution for handicaps 8-9:
/// @verbatim
/// 3 8 2
/// 5 9 6
/// 1 7 4
/// @endverbatim
// -----------------------------------------------------------------------------
+ (NSArray*) verticesForHandicap:(int)handicap boardSize:(enum GoBoardSize)boardSize
{
  static const int numberOfBoardSizes = (GoBoardSizeMax - GoBoardSizeMin) / 2 + 1;
  static const int maxHandicaps[numberOfBoardSizes] = {4, 9, 9, 9, 9, 9, 9};
  static const int edgeDistances[numberOfBoardSizes] = {3, 3, 3, 4, 4, 4, 4};

  NSMutableArray* handicapVertices = [NSMutableArray arrayWithCapacity:0];
  if (0 == handicap)
    return handicapVertices;

  int boardSizeArrayIndex = (boardSize - GoBoardSizeMin) / 2;
  if (handicap < 2 || handicap > maxHandicaps[boardSizeArrayIndex])
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Specified handicap %d is out of range for GoBoardSize %d", handicap, boardSize];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSRangeException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  int edgeDistance = edgeDistances[boardSizeArrayIndex];
  int lineClose = edgeDistance;
  int lineFar = boardSize - edgeDistance + 1;
  int lineMiddle = lineClose + ((lineFar - lineClose) / 2);

  for (int handicapIter = 1; handicapIter <= handicap; ++handicapIter)
  {
    struct GoVertexNumeric numericVertex;
    switch (handicapIter)
    {
      case 1:
      {
        numericVertex.x = lineClose;
        numericVertex.y = lineClose;
        break;
      }
      case 2:
      {
        numericVertex.x = lineFar;
        numericVertex.y = lineFar;
        break;
      }
      case 3:
      {
        numericVertex.x = lineClose;
        numericVertex.y = lineFar;
        break;
      }
      case 4:
      {
        numericVertex.x = lineFar;
        numericVertex.y = lineClose;
        break;
      }
      case 5:
      {
        if (handicapIter == handicap)
        {
          numericVertex.x = lineMiddle;
          numericVertex.y = lineMiddle;
        }
        else
        {
          numericVertex.x = lineClose;
          numericVertex.y = lineMiddle;
        }
        break;
      }
      case 6:
      {
        numericVertex.x = lineFar;
        numericVertex.y = lineMiddle;
        break;
      }
      case 7:
      {
        if (handicapIter == handicap)
        {
          numericVertex.x = lineMiddle;
          numericVertex.y = lineMiddle;
        }
        else
        {
          numericVertex.x = lineMiddle;
          numericVertex.y = lineClose;
        }
        break;
      }
      case 8:
      {
        numericVertex.x = lineMiddle;
        numericVertex.y = lineFar;
        break;
      }
      case 9:
      {
        numericVertex.x = lineMiddle;
        numericVertex.y = lineMiddle;
        break;
      }
      default:
      {
        DDLogError(@"%@: Unsupported handicap %d", [self class], handicapIter);
        assert(0);
        break;
      }
    }
    GoVertex* vertex = [GoVertex vertexFromNumeric:numericVertex];
    [handicapVertices addObject:vertex.string];
  }

  return handicapVertices;
}

// -----------------------------------------------------------------------------
/// @brief Returns an (unordered) list of GoPoint objects for the specified
/// @a handicap and board associated with @a game.
///
/// See verticesForHandicap:boardSize:() for details.
// -----------------------------------------------------------------------------
+ (NSArray*) pointsForHandicap:(int)handicap inGame:(GoGame*)game
{
  GoBoard* board = game.board;
  if (! board)
  {
    NSString* errorMessage = @"No GoBoard object associated with specified GoGame";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  NSMutableArray* handicapPoints = [NSMutableArray arrayWithCapacity:0];
  NSArray* handicapVertices = [GoUtilities verticesForHandicap:handicap boardSize:board.size];
  for (NSString* vertex in handicapVertices)
  {
    GoPoint* point = [board pointAtVertex:vertex];
    [handicapPoints addObject:point];
  }
  return handicapPoints;
}

// -----------------------------------------------------------------------------
/// @brief Returns the maximum handicap for the specified @a boardSize.
// -----------------------------------------------------------------------------
+ (int) maximumHandicapForBoardSize:(enum GoBoardSize)boardSize
{
  switch (boardSize)
  {
    case GoBoardSize7:
      return 4;
    default:
      return 9;
  }
}

// -----------------------------------------------------------------------------
/// @brief Assuming that alternating play is desired, returns the player whose
/// turn it is after @a move was played. If @a move is nil, returns the player
/// who plays first in @a game (after taking handicap into consideration).
// -----------------------------------------------------------------------------
+ (GoPlayer*) playerAfter:(GoMove*)move inGame:(GoGame*)game
{
  if (! move)
  {
    if (0 == game.handicapPoints.count)
      return game.playerBlack;
    else
      return game.playerWhite;
  }
  else if (move.player == game.playerBlack)
    return game.playerWhite;
  else
    return game.playerBlack;
}

// -----------------------------------------------------------------------------
/// @brief Returns an (unordered) list of GoPoint objects whose intersections
/// are located in the rectangle delimited by @a pointA and @a pointB. The
/// points that are returned are taken from the GoBoard instance associated with
/// @a game.
// -----------------------------------------------------------------------------
+ (NSArray*) pointsInRectangleDelimitedByCornerPoint:(GoPoint*)pointA
                                 oppositeCornerPoint:(GoPoint*)pointB
                                              inGame:(GoGame*)game
{
  if (! pointA || ! pointB)
  {
    NSString* errorMessage = @"Either one or both of the delimiting GoPoint objects not specified";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  GoBoard* board = game.board;
  if (! board)
  {
    NSString* errorMessage = @"No GoBoard object associated with specified GoGame";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  struct GoVertexNumeric numericVertexA = pointA.vertex.numeric;
  struct GoVertexNumeric numericVertexB = pointB.vertex.numeric;
  struct GoVertexNumeric numericVertexBottomLeft;
  numericVertexBottomLeft.x = MIN(numericVertexA.x, numericVertexB.x);
  numericVertexBottomLeft.y = MIN(numericVertexA.y, numericVertexB.y);
  struct GoVertexNumeric numericVertexTopRight;
  numericVertexTopRight.x = MAX(numericVertexA.x, numericVertexB.x);
  numericVertexTopRight.y = MAX(numericVertexA.y, numericVertexB.y);

  NSMutableArray* pointsInRectangle = [NSMutableArray arrayWithCapacity:0];
  struct GoVertexNumeric numericVertexIteration = numericVertexBottomLeft;
  while (numericVertexIteration.y <= numericVertexTopRight.y)
  {
    while (numericVertexIteration.x <= numericVertexTopRight.x)
    {
      GoVertex* vertexIteration = [GoVertex vertexFromNumeric:numericVertexIteration];
      GoPoint* point = [board pointAtVertex:vertexIteration.string];
      [pointsInRectangle addObject:point];
      numericVertexIteration.x++;
    }
    numericVertexIteration.x = numericVertexBottomLeft.x;
    numericVertexIteration.y++;
  }
  return pointsInRectangle;
}

// -----------------------------------------------------------------------------
/// @brief Returns the default komi value for the combination of @a handicap and
/// @a scoringSystem.
///
/// Raises an @e NSInvalidArgumentException if the combination of @a handicap
/// and @a scoringSystem is not recognized.
// -----------------------------------------------------------------------------
+ (double) defaultKomiForHandicap:(int)handicap scoringSystem:(enum GoScoringSystem)scoringSystem
{
  if (handicap > 0)
    return 0.5;

  switch (scoringSystem)
  {
    case GoScoringSystemAreaScoring:
    {
      return gDefaultKomiAreaScoring;
    }
    case GoScoringSystemTerritoryScoring:
    {
      return gDefaultKomiTerritoryScoring;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Unable to determine default komi, unknown scoring system %d", scoringSystem];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated GoGameRules object that contains rules for
/// which @a ruleset is a shorthand.
///
/// Raises an @e NSInvalidArgumentException if @a ruleset is not recognized.
// -----------------------------------------------------------------------------
+ (GoGameRules*) rulesForRuleset:(enum GoRuleset)ruleset
{
  GoGameRules* rules = [[[GoGameRules alloc] init] autorelease];
  switch (ruleset)
  {
    case GoRulesetAGA:
    {
      rules.koRule = GoKoRuleSuperkoSituational;
      rules.scoringSystem = GoScoringSystemAreaScoring;
      rules.lifeAndDeathSettlingRule = GoLifeAndDeathSettlingRuleTwoPasses;
      rules.disputeResolutionRule = GoDisputeResolutionRuleAlternatingPlay;
      rules.fourPassesRule = GoFourPassesRuleFourPassesEndTheGame;
      break;
    }
    case GoRulesetIGS:
    {
      rules.koRule = GoKoRuleSimple;
      rules.scoringSystem = GoScoringSystemTerritoryScoring;
      rules.lifeAndDeathSettlingRule = GoLifeAndDeathSettlingRuleThreePasses;
      rules.disputeResolutionRule = GoDisputeResolutionRuleAlternatingPlay;
      rules.fourPassesRule = GoFourPassesRuleFourPassesHaveNoSpecialMeaning;
      break;
    }
    case GoRulesetChinese:
    {
      rules.koRule = GoKoRuleSuperkoPositional;
      rules.scoringSystem = GoScoringSystemAreaScoring;
      rules.lifeAndDeathSettlingRule = GoLifeAndDeathSettlingRuleTwoPasses;
      rules.disputeResolutionRule = GoDisputeResolutionRuleNonAlternatingPlay;
      rules.fourPassesRule = GoFourPassesRuleFourPassesHaveNoSpecialMeaning;
      break;
    }
    case GoRulesetJapanese:
    {
      rules.koRule = GoKoRuleSimple;
      rules.scoringSystem = GoScoringSystemTerritoryScoring;
      rules.lifeAndDeathSettlingRule = GoLifeAndDeathSettlingRuleTwoPasses;
      rules.disputeResolutionRule = GoDisputeResolutionRuleNonAlternatingPlay;
      rules.fourPassesRule = GoFourPassesRuleFourPassesHaveNoSpecialMeaning;
      break;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Unable to determine GoGameRules, unknown ruleset %d", ruleset];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
  return rules;
}

// -----------------------------------------------------------------------------
/// @brief Returns the ruleset that best describes the rules in @a rules.
/// Returns #GoRulesetCustom if no ruleset fits.
// -----------------------------------------------------------------------------
+ (enum GoRuleset) rulesetForRules:(GoGameRules*)rules
{
  for (enum GoRuleset ruleset = GoRulesetMin; ruleset <= GoRulesetMax; ++ruleset)
  {
    GoGameRules* rulesForRuleset = [GoUtilities rulesForRuleset:ruleset];
    if (rules.koRule != rulesForRuleset.koRule)
      continue;
    else if (rules.scoringSystem != rulesForRuleset.scoringSystem)
      continue;
    else if (rules.lifeAndDeathSettlingRule != rulesForRuleset.lifeAndDeathSettlingRule)
      continue;
    else if (rules.disputeResolutionRule != rulesForRuleset.disputeResolutionRule)
      continue;
    else if (rules.fourPassesRule != rulesForRuleset.fourPassesRule)
      continue;
    return ruleset;
  }
  return GoRulesetCustom;
}

@end
