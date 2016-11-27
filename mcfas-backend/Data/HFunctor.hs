{-|
Module      : Data.HFunctor
Description : Polykinded higher-order functors
Copyright   : (c) Jacob Errington 2016
License     : MIT
Maintainer  : mcfas@mail.jerrington.me
Stability   : experimental

Polykinded higher-order functors allow you to represent indexed syntax trees.
Examples of indexed syntax trees include syntax trees with (static) type
annotations and mutual recursion.
-}

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeOperators #-}

module Data.HFunctor
( -- * Natural transformations
  type (:~>)
  -- * Higher-order functors
, HFunctor(..)
  -- ** Higher-order fixed points and folds
, HFix(..)
, hcata
  -- * Important functors
, K(..)
, I(..)
  -- * Higher-order generic traversals
, HTraversable(..)
, MonadH(..)
) where

-- | The class of polykinded higher-order functors.
--
-- Whereas a simple functor can be thought of as a context around a value, a
-- higher-order functor can be thought of as a context around another functor.
--
-- Any regular 'Functor' can be made an instance of HFunctor by choosing
-- @k ~ ()@, since @() -> *@ is isomorphic to @*@.
class HFunctor (h :: (k -> *) -> k -> *) where
  -- | A higher-order 'fmap'. By contrast with the simple @fmap@ which lifts
  -- simple functions into functions operating in the Functor, hfmap lifts
  -- natural transformations between functors into natural transformations
  -- operating in the HFunctor.
  hfmap :: (f :~> g) -> h f :~> h g

-- | Natural transformations.
--
-- Intuitively, a natural transformation between functors is a uniform
-- transformation of the context around the value. By \"uniform\", it is
-- understood that the transformation can in no way examine the value in order
-- to perform the transformation.
--
-- This is enforced on the type level by using parametricity.
type f :~> g = forall a. f a -> g a

-- | The fixed point of a higher order functor.
newtype HFix (h :: (k -> *) -> k -> *) (a :: k)
  = HFix { unHFix :: h (HFix h) a }

-- | Higher-order catamorphism.
--
-- Folds a higher-order functor fixpoint into a functor in a bottom-up fashion.
-- The @h f :~> f@ parameter is a higher-order F-algebra.
hcata
  :: forall (h :: (k -> *) -> k -> *) (f :: k -> *) (a :: k). HFunctor h
  => (forall (b :: k). h f b -> f b)
  -> HFix h a -> f a
hcata hAlg = hAlg . hfmap (hcata hAlg) . unHFix

-- hcataM
--   :: HFunctor h
--   => forall (a :: k).
--     (forall (a :: k). h f a -> m (f a))
--   -> HFix h a
--   -> m (f a)
-- hcataM hAlgM = (>>= hAlgM) . hcata (htraverse (>>= hAlgM))

-- | Constant functor.
--
-- Can be considered a type-level constant function.
--
-- The @fmap@ implementation simply ignores the given function, and rewrites
-- the type.
newtype K x (a :: k) = K { unK :: x } deriving Functor

-- | Identity functor. This is just a box around a value.
--
-- The @fmap@ implementation simply applies the function to the boxed value.
newtype I a = I { unI :: a } deriving Functor

-- | Class of higher-order functors whose side-effects can be sequenced
-- left-to-right.
class HTraversable (h :: (k -> *) -> k -> *) where
  -- | If a higher-order functor contains side effects in its recursive
  -- positions, then they can be sequenced left-to-right, hoisting the actions
  -- up.
  --
  -- Generalizes
  -- @sequenceA :: (Traversable t, Applicative f) => t (f a) -> f (t a)@.
  sequenceH :: Applicative m => h (MonadH m f) a -> m (h f a)

-- | Presents a monadic wrapper in a uniform way on the type-level.
newtype MonadH
  (m :: * -> *)
  (f :: k -> *)
  (a :: k)
  = MonadH
    { unMonadH :: m (f a) }

instance Functor m => HFunctor (MonadH m) where
  hfmap f (MonadH m) = MonadH (f <$> m)
