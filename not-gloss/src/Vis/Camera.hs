{-# OPTIONS_GHC -Wall #-}

module Vis.Camera ( Camera0(..)
                  , Camera(..)
                  , makeCamera
                  , setCamera
                  , cameraMotion
                  , cameraKeyboardMouse
                  ) where

import Graphics.UI.GLUT ( GLdouble, GLint
                        , Vector3(..), Vertex3(..)
                        , Position(..), MouseButton(..), Key(..), KeyState(..)
                        )
import qualified Graphics.UI.GLUT as GLUT

import SpatialMath ( V3(..) )

data Camera0 = Camera0 { phi0 :: GLdouble
                       , theta0 :: GLdouble
                       , rho0 :: GLdouble
                       } deriving Show

data Camera = Camera { phi :: GLdouble
                     , theta :: GLdouble
                     , rho :: GLdouble
                     , pos :: V3 GLdouble
                     , ballX :: GLint
                     , ballY :: GLint 
                     , leftButton :: GLint
                     , rightButton :: GLint
                     , middleButton :: GLint
                     }

makeCamera :: Camera0 -> Camera
makeCamera camera0 = Camera { phi   = phi0 camera0
                            , theta = theta0 camera0
                            , rho   = rho0 camera0
                            , pos = V3 0 0 0
                            , ballX = (-1)
                            , ballY = (-1)
                            , leftButton = 0
                            , rightButton = 0
                            , middleButton = 0
                            }

setCamera :: Camera -> IO ()
setCamera camera = GLUT.lookAt (Vertex3 xc yc zc) (Vertex3 x0 y0 z0) (Vector3 0 0 (-1))
  where
    V3 x0 y0 z0 = pos camera
    phi'   = phi   camera
    theta' = theta camera
    rho'   = rho   camera

    xc = x0 + rho'*cos(phi'*pi/180)*cos(theta'*pi/180)
    yc = y0 + rho'*sin(phi'*pi/180)*cos(theta'*pi/180)
    zc = z0 - rho'*sin(theta'*pi/180)

cameraMotion :: Camera -> Position -> Camera
cameraMotion (Camera phi0' theta0' rho0' (V3 x0 y0 z0) bx by lb rb mb) (Position x y) =
  Camera nextPhi nextTheta rho0' nextPos nextBallX nextBallY lb rb mb
  where
    deltaX
      | bx == -1  = 0
      | otherwise = fromIntegral (x - bx)
    deltaY
      | by == -1  = 0
      | otherwise = fromIntegral (y - by)
    deltaZ
      | by == -1  = 0
      | otherwise = fromIntegral (y - by)
    nextTheta'
      | deltaY + theta0' >  80 =  80
      | deltaY + theta0' < -80 = -80
      | otherwise              = deltaY + theta0'
    nextX = x0 + 0.003*rho0'*( -sin(phi0'*pi/180)*deltaX - cos(phi0'*pi/180)*deltaY)
    nextY = y0 + 0.003*rho0'*(  cos(phi0'*pi/180)*deltaX - sin(phi0'*pi/180)*deltaY)
    nextZ = z0 - 0.001*rho0'*deltaZ

    (nextPhi, nextTheta) = if lb == 1
                           then (phi0' + deltaX, nextTheta')
                           else (phi0', theta0')

    nextPos
      | rb == 1 = V3 nextX nextY z0
      | mb == 1 = V3 x0 y0 nextZ
      | otherwise = V3 x0 y0 z0

    nextBallX = x
    nextBallY = y

cameraKeyboardMouse :: Camera -> Key -> KeyState -> Camera
cameraKeyboardMouse camera key keyState =
  camera {rho = newRho, leftButton = lb, rightButton = rb, middleButton = mb, ballX = bx, ballY = by}
  where
    (lb, reset0) = case (key, keyState) of (MouseButton LeftButton, Down) -> (1, True)
                                           (MouseButton LeftButton, Up) -> (0, False)
                                           _ -> (leftButton camera, False)
    (rb, reset1) = case (key, keyState) of (MouseButton RightButton, Down) -> (1, True)
                                           (MouseButton RightButton, Up) -> (0, False)
                                           _ -> (rightButton camera, False)
    (mb, reset2) = case (key, keyState) of (MouseButton MiddleButton, Down) -> (1, True)
                                           (MouseButton MiddleButton, Up) -> (0, False)
                                           _ -> (middleButton camera, False)
  
    (bx,by) = if reset0 || reset1 || reset2 then (-1,-1) else (ballX camera, ballY camera)
  
    newRho = case (key, keyState) of (MouseButton WheelUp, Down)   -> 0.9 * (rho camera)
                                     (MouseButton WheelDown, Down) -> 1.1 * (rho camera)
                                     (Char 'e', Down)   -> 0.9 * (rho camera)
                                     (Char 'q', Down) -> 1.1 * (rho camera)
                                     _ -> rho camera
