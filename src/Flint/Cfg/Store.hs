module Flint.Cfg.Store ( module Flint.Cfg.Store ) where

import Flint.Prelude

import Flint.Types.Cfg.Store (CfgStore)

import Blaze.Types.Function (Function)

import qualified Blaze.Import.Cfg as ImpCfg
import Blaze.Import.Cfg (CfgImporter, NodeDataType) 

import Blaze.Types.Cfg (PilCfg, PilNode)

import qualified Data.HashMap.Strict as HashMap


-- This is a cache of Cfgs for functions.
-- This version only supports functions from a single binary.

-- If you have a bunch of object files, you can collect them like so:
-- gcc -no-pie -Wl,--unresolved-symbols=ignore-all -o full_collection_binary *.o


init :: CfgStore
init = HashMap.empty

addFuncCfg_ :: Function -> PilCfg -> CfgStore -> CfgStore
addFuncCfg_ = HashMap.insert

-- | Adds a func/cfg to the store.
-- Overwrites existing function Cfg.
-- Any Cfgs in the store should have a CtxId of 0
addFunc
  :: ( CfgImporter a
     , NodeDataType a ~ PilNode)
  => a -> Function -> CfgStore -> IO CfgStore
addFunc imp func store = ImpCfg.getCfg imp func 0 >>= \case
  Nothing -> return store
  Just r -> return $ addFuncCfg_ func cfg store
    where cfg = r ^. #result

-- | TODO: use sqlite or something beside hashmap so we can use Function as key
cfgFromFunc :: CfgStore -> Function -> Maybe PilCfg
cfgFromFunc store func = HashMap.lookup func store

getFromFuncName :: Text -> CfgStore -> [(Function, PilCfg)]
getFromFuncName fname store = filter nameMatches $ HashMap.toList store
  where
    nameMatches (func, _cfg) = func ^. #name == fname

-- | Convenience function to get the first Cfg in store with that name
getFromFuncName_ :: Text -> CfgStore -> Maybe PilCfg
getFromFuncName_ fname store = fmap snd . headMay $ getFromFuncName fname store
