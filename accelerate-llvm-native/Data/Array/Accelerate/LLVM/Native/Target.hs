{-# LANGUAGE CPP                 #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies        #-}
-- |
-- Module      : Data.Array.Accelerate.LLVM.Native.Target
-- Copyright   : [2013] Trevor L. McDonell, Sean Lee, Vinod Grover
-- License     : BSD3
--
-- Maintainer  : Trevor L. McDonell <tmcdonell@nvidia.com>
-- Stability   : experimental
-- Portability : non-portable (GHC extensions)
--

module Data.Array.Accelerate.LLVM.Native.Target (

  module Data.Array.Accelerate.LLVM.Target,
  module Data.Array.Accelerate.LLVM.Native.Target

) where

-- llvm-general
import LLVM.General.Target                                      hiding ( Target )
import LLVM.General.AST.DataLayout                              ( DataLayout )

-- accelerate
import Data.Array.Accelerate.LLVM.Target                        ( Target(..) )
import Data.Array.Accelerate.LLVM.Native.Compile.Function       ( Function )

-- standard library
import Control.Monad.Error
import System.IO.Unsafe

#include "accelerate.h"


-- | Native machine code JIT execution target
--
data Native = Native

instance Target Native where
  data ExecutableR Native = NativeR { executableR :: Function }

  targetTriple     _ = Just nativeTargetTriple
  targetDataLayout _ = Just nativeDataLayout


-- | String that describes the native target
--
{-# NOINLINE nativeTargetTriple #-}
nativeTargetTriple :: String
nativeTargetTriple = unsafePerformIO $
#if MIN_VERSION_llvm_general(3,3,0)
    -- A target triple suitable for loading code into the current process
    getProcessTargetTriple
#else
    -- The default target triple LLVM has been configured to produce code for
    getDefaultTargetTriple
#endif

-- | A description of the various data layout properties that may be used during
-- optimisation.
--
{-# NOINLINE nativeDataLayout #-}
nativeDataLayout :: DataLayout
nativeDataLayout
  = unsafePerformIO
  $ fmap (either (INTERNAL_ERROR(error) "nativeDataLayout") id)
  $ runErrorT (withDefaultTargetMachine getTargetMachineDataLayout)


-- | Bracket the creation and destruction of a target machine for the native
-- backend running on this host.
--
withNativeTargetMachine
    :: (TargetMachine -> IO a)
    -> ErrorT String IO a
withNativeTargetMachine = withDefaultTargetMachine

