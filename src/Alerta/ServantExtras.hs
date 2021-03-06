{-# OPTIONS_GHC -fno-warn-orphans #-}
{-# LANGUAGE DataKinds            #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE OverloadedStrings    #-}
{-# LANGUAGE ScopedTypeVariables  #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE TypeOperators        #-}

--------------------------------------------------------------------------------
-- Module: Alerta.ServantExtras
--
-- Additions to Servant needed to cope with the peculiarities of
-- alerta's REST API.
--------------------------------------------------------------------------------
module Alerta.ServantExtras
  ( FieldQueries
  ) where

import           Alerta.Types       (FieldQuery, MatchType(..))

import           Data.List
import           Data.Monoid        ((<>))
import           Data.Proxy
import qualified Data.Text          as T

import           Servant.Common.Req (Req, appendToQueryString)
import           Servant.Client
import           Servant.API        ((:>))
import           Web.HttpApiData

-- | We need this because Alerta for some reason requires `field` and `field!`
-- parameters to be joined together with a comma rather than passed in the
-- usual way.
instance {-# OVERLAPPABLE #-} ToHttpApiData a => ToHttpApiData [a] where
  toQueryParam  = T.intercalate "," . map toQueryParam

data FieldQueries

instance HasClient api => HasClient (FieldQueries :> api) where
  type Client (FieldQueries :> api) = [FieldQuery] -> Client api

  clientWithRoute Proxy req fqs =
    clientWithRoute (Proxy :: Proxy api) $ foldl' (flip f) req fqs where

      f :: FieldQuery -> Req -> Req
      f (attr, txt, t, b) = appendToQueryString k (Just v) where
        k = toUrlPiece attr <> suffix
        v = prefix <> txt
        suffix = if b then "" else "!"
        prefix = case t of
          Regex   -> "~"
          Literal -> ""
