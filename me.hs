{-# LANGUAGE OverloadedStrings,DeriveDataTypeable #-}
import           Control.Exception        (SomeException)
import           Control.Exception.Lifted (handle)
import           Control.Monad.IO.Class   (liftIO)
import           Control.Monad            (mzero)
import           Data.Aeson               
import           Data.Aeson.Parser        (json)
import           Data.ByteString          (ByteString)
import           Data.Conduit             (ResourceT, ($$), ($$+-))
import           Data.Conduit.Attoparsec  (sinkParser)
import           Network.HTTP.Types       (status200, status400)
import           Network.Wai              (Application, Response, requestBody,
                                           responseLBS, rawQueryString, pathInfo, requestMethod)
import           Network.Wai.Handler.Warp (run)

import           System.Process
import           Data.Typeable
import           Data.Data

main :: IO ()
main = do
    putStrLn "me -- vmx ..loaded"
    run 3000 app

app :: Application
app req = 
        case requestMethod req of
            "OPTIONS" -> do
                return $ responseLBS
                    status200
                    optionsHeaders
                    ""
            "POST" -> handle invalidJson $ do
                        input <- requestBody req $$ sinkParser json
                        output <- liftIO $ runShell input
                        return $ responseLBS
                            status200
                            defaultHeaders
                            $ encode output
            _       -> do
                            return $ responseLBS
                                status400
                                defaultHeaders
                                $ encode ("INVALID REQUEST METHOD" :: String)
        where
            optionsHeaders = 
                    [("Content-Type", "application/json")
                    , ("Access-Control-Allow-Methods", "POST")
                    , ("Access-Control-Allow-Origin", "*")
                    , ("Access-Control-Allow-Headers", "Content-Type")
                    ]
            defaultHeaders = [("Content-Type", "application/json"), ("Access-Control-Allow-Origin", "*")]


invalidJson :: SomeException -> ResourceT IO Response
invalidJson ex = return $ responseLBS
    status400
    [("Content-Type", "application/json"), ("Access-Control-Allow-Origin", "*")]
    $ encode $ object [ ("message" .= show ex) ]

data Command = Command {
    cmd  :: String,
    args :: [String]
}deriving (Eq,Show)

data VMXResponse = VMXResponse {
    msg :: String,
    out :: String
}deriving (Data,Typeable, Eq,Show)
 
instance ToJSON VMXResponse where
   toJSON (VMXResponse msg out) = object ["msg" .= msg, "out" .= out]

instance FromJSON Command where
    parseJSON (Object o) = do
        cmd    <- parseJSON =<< (o .: "command")
        args   <- parseJSON =<< (o .: "args")
        return  $ Command cmd args
    parseJSON _ = mzero

runShell :: Value -> IO Value
runShell val = do
    case fromJSON val of
        Success (Command cmd' args') -> do
                        putStrLn cmd'
                        out <- readProcess cmd' args' ""
                        return $ toJSON $ VMXResponse "success" out 
        Error e         -> do
                        putStrLn e
                        return $ toJSON $ VMXResponse "error" e
    
